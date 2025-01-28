using System.Text.Json;
using MySql.Data.MySqlClient;
using NayifatAPI.Models;

namespace NayifatAPI.Services;

public class NotificationService
{
    private readonly DatabaseService _db;
    private readonly ILogger<NotificationService> _logger;
    private readonly IAuditService _auditService;

    public NotificationService(
        DatabaseService db, 
        ILogger<NotificationService> logger,
        IAuditService auditService)
    {
        _db = db;
        _logger = logger;
        _auditService = auditService;
    }

    public async Task<GetNotificationsResponse> GetNotifications(GetNotificationsRequest request)
    {
        try
        {
            // Add validation to match PHP
            if (request == null || string.IsNullOrEmpty(request.NationalId))
            {
                return new GetNotificationsResponse("Invalid input or missing national_id");
            }

            using var connection = await _db.GetConnection();
            
            // Get user's notifications
            using var cmd = new MySqlCommand(
                "SELECT notifications FROM user_notifications WHERE national_id = @national_id",
                connection
            );
            cmd.Parameters.AddWithValue("@national_id", request.NationalId);

            using var reader = await cmd.ExecuteReaderAsync();
            if (!await reader.ReadAsync())
            {
                return new GetNotificationsResponse(new List<NotificationTemplate>());
            }

            var notificationsJson = reader.GetString(0);
            reader.Close();

            var notifications = !string.IsNullOrEmpty(notificationsJson) 
                ? JsonSerializer.Deserialize<List<UserNotification>>(notificationsJson)
                : new List<UserNotification>();

            if (notifications == null)
            {
                return new GetNotificationsResponse(new List<NotificationTemplate>());
            }

            var currentTime = DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss");
            var unreadNotifications = new List<NotificationTemplate>();

            // Filter and get template details for unread notifications
            foreach (var notification in notifications.Where(n => n.Status == "unread"))
            {
                if (!string.IsNullOrEmpty(notification.ExpiresAt) && 
                    string.Compare(notification.ExpiresAt, currentTime) < 0)
                {
                    continue;
                }

                using var templateCmd = new MySqlCommand(@"
                    SELECT * FROM notification_templates 
                    WHERE id = @template_id 
                    AND (expiry_at IS NULL OR expiry_at > @current_time)",
                    connection
                );
                templateCmd.Parameters.AddWithValue("@template_id", notification.TemplateId);
                templateCmd.Parameters.AddWithValue("@current_time", currentTime);

                using var templateReader = await templateCmd.ExecuteReaderAsync();
                if (await templateReader.ReadAsync())
                {
                    var additionalDataJson = templateReader.IsDBNull(templateReader.GetOrdinal("additional_data"))
                        ? null
                        : templateReader.GetString("additional_data");

                    var additionalData = !string.IsNullOrEmpty(additionalDataJson)
                        ? JsonSerializer.Deserialize<Dictionary<string, object>>(additionalDataJson)
                        : null;

                    unreadNotifications.Add(new NotificationTemplate
                    {
                        Id = notification.TemplateId,
                        Title = templateReader.GetString("title"),
                        Body = templateReader.GetString("body"),
                        TitleEn = templateReader.GetString("title_en"),
                        BodyEn = templateReader.GetString("body_en"),
                        TitleAr = templateReader.GetString("title_ar"),
                        BodyAr = templateReader.GetString("body_ar"),
                        Route = templateReader.GetString("route"),
                        AdditionalData = additionalData,
                        CreatedAt = notification.CreatedAt,
                        ExpiresAt = notification.ExpiresAt,
                        Status = notification.Status
                    });
                }
                templateReader.Close();
            }

            // Log expired notifications
            var expiredNotifications = notifications
                .Where(n => !string.IsNullOrEmpty(n.ExpiresAt) && 
                           string.Compare(n.ExpiresAt, currentTime) < 0 && 
                           !string.IsNullOrEmpty(n.TemplateId))
                .ToList();

            if (expiredNotifications.Any())
            {
                var expiredIds = expiredNotifications.Select(n => n.TemplateId).ToList();
                await _auditService.LogAuditAsync(
                    int.Parse(request.NationalId),
                    "notification_expired",
                    JsonSerializer.Serialize(new
                    {
                        notification_ids = expiredIds,
                        timestamp = currentTime
                    })
                );
            }

            // Log notifications being delivered
            var notificationIds = unreadNotifications.Select(n => n.Id).ToList();
            if (notificationIds.Any())
            {
                await _auditService.LogAuditAsync(
                    int.Parse(request.NationalId),
                    "notification_delivered",
                    JsonSerializer.Serialize(new
                    {
                        notification_count = unreadNotifications.Count,
                        notification_ids = notificationIds,
                        timestamp = currentTime
                    })
                );
            }

            // Mark notifications as read if requested
            if (request.MarkAsRead == true && unreadNotifications.Any())
            {
                foreach (var notification in notifications.Where(n => n.Status == "unread"))
                {
                    notification.Status = "read";
                    notification.ReadAt = currentTime;
                }

                using var updateCmd = new MySqlCommand(
                    "UPDATE user_notifications SET notifications = @notifications WHERE national_id = @national_id",
                    connection
                );
                var updatedJson = JsonSerializer.Serialize(notifications);
                updateCmd.Parameters.AddWithValue("@notifications", updatedJson);
                updateCmd.Parameters.AddWithValue("@national_id", request.NationalId);

                if (await updateCmd.ExecuteNonQueryAsync() > 0)
                {
                    var readNotificationIds = unreadNotifications
                        .Where(n => n.Status == "unread")
                        .Select(n => n.Id)
                        .ToList();

                    if (readNotificationIds.Any())
                    {
                        await _auditService.LogAuditAsync(
                            int.Parse(request.NationalId),
                            "notification_read",
                            JsonSerializer.Serialize(new
                            {
                                notification_ids = readNotificationIds,
                                timestamp = currentTime
                            })
                        );
                    }
                }
            }

            return new GetNotificationsResponse(unreadNotifications);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting notifications for user {NationalId}", request.NationalId);
            return new GetNotificationsResponse(ex.Message);
        }
    }

    public async Task<SendNotificationResponse> SendNotification(SendNotificationRequest request)
    {
        try
        {
            if (request == null)
            {
                return new SendNotificationResponse("Invalid JSON input");
            }

            // Check if it's a multi-language notification
            var isMultiLanguage = request.TitleEn != null && request.BodyEn != null && 
                                request.TitleAr != null && request.BodyAr != null;

            if (!isMultiLanguage && (request.Title == null || request.Body == null))
            {
                return new SendNotificationResponse("Either provide single language notification (title + body) or multi-language notification (title_en + body_en + title_ar + body_ar)");
            }

            using var connection = await _db.GetConnection();
            var targetUsers = new List<string>();

            // Case 1: Single user
            if (!string.IsNullOrEmpty(request.NationalId))
            {
                using var cmd = new MySqlCommand(
                    "SELECT national_id FROM Customers WHERE national_id = @national_id",
                    connection
                );
                cmd.Parameters.AddWithValue("@national_id", request.NationalId);
                using var reader = await cmd.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    targetUsers.Add(reader.GetString(0));
                }
                reader.Close();
            }
            // Case 2: Multiple specific users
            else if (request.NationalIds?.Any() == true)
            {
                var idList = string.Join(",", request.NationalIds.Select(id => $"'{MySqlHelper.EscapeString(id)}'"));
                using var cmd = new MySqlCommand(
                    $"SELECT national_id FROM Customers WHERE national_id IN ({idList})",
                    connection
                );
                using var reader = await cmd.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    targetUsers.Add(reader.GetString(0));
                }
                reader.Close();
            }
            // Case 3: Filtered users
            else if (request.Filters?.Any() == true)
            {
                var (query, parameters) = BuildFilterQuery(request.Filters, request.FilterOperation);
                using var cmd = new MySqlCommand(query, connection);
                foreach (var param in parameters)
                {
                    cmd.Parameters.AddWithValue(param.Key, param.Value);
                }
                using var reader = await cmd.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    targetUsers.Add(reader.GetString(0));
                }
                reader.Close();
            }

            if (!targetUsers.Any())
            {
                return new SendNotificationResponse("No target users found");
            }

            // Create notification template
            var templateId = Guid.NewGuid().ToString();
            using var templateCmd = new MySqlCommand(@"
                INSERT INTO notification_templates (
                    id, title, body, title_en, body_en, title_ar, body_ar, 
                    route, additional_data, created_at, expiry_at
                ) VALUES (
                    @id, @title, @body, @title_en, @body_en, @title_ar, @body_ar,
                    @route, @additional_data, @created_at, @expiry_at
                )",
                connection
            );

            var currentTime = DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss");
            templateCmd.Parameters.AddWithValue("@id", templateId);
            templateCmd.Parameters.AddWithValue("@title", request.Title ?? "");
            templateCmd.Parameters.AddWithValue("@body", request.Body ?? "");
            templateCmd.Parameters.AddWithValue("@title_en", request.TitleEn ?? "");
            templateCmd.Parameters.AddWithValue("@body_en", request.BodyEn ?? "");
            templateCmd.Parameters.AddWithValue("@title_ar", request.TitleAr ?? "");
            templateCmd.Parameters.AddWithValue("@body_ar", request.BodyAr ?? "");
            templateCmd.Parameters.AddWithValue("@route", request.Route ?? "");
            templateCmd.Parameters.AddWithValue("@additional_data", 
                request.AdditionalData != null ? JsonSerializer.Serialize(request.AdditionalData) : null);
            templateCmd.Parameters.AddWithValue("@created_at", currentTime);
            templateCmd.Parameters.AddWithValue("@expiry_at", request.ExpiresAt);

            await templateCmd.ExecuteNonQueryAsync();

            // Log notification creation
            await _auditService.LogAuditAsync(
                0, // System action
                "notification_created",
                JsonSerializer.Serialize(new
                {
                    template_id = request.TemplateId,
                    target_users_count = targetUsers.Count,
                    filters = request.Filters,
                    filter_operation = request.FilterOperation,
                    timestamp = DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss")
                })
            );

            // Add notification for each target user
            foreach (var userId in targetUsers)
            {
                var userNotification = new UserNotification
                {
                    TemplateId = templateId,
                    CreatedAt = currentTime,
                    ExpiresAt = request.ExpiresAt,
                    Status = "unread"
                };

                // Get existing notifications
                using var getCmd = new MySqlCommand(
                    "SELECT notifications FROM user_notifications WHERE national_id = @national_id",
                    connection
                );
                getCmd.Parameters.AddWithValue("@national_id", userId);
                
                using var reader = await getCmd.ExecuteReaderAsync();
                var existingNotifications = new List<UserNotification>();
                
                if (await reader.ReadAsync())
                {
                    var notificationsJson = reader.GetString(0);
                    if (!string.IsNullOrEmpty(notificationsJson))
                    {
                        existingNotifications = JsonSerializer.Deserialize<List<UserNotification>>(notificationsJson) ?? new List<UserNotification>();
                    }
                }
                reader.Close();

                existingNotifications.Add(userNotification);
                var updatedJson = JsonSerializer.Serialize(existingNotifications);

                // Update or insert notifications
                using var upsertCmd = new MySqlCommand(@"
                    INSERT INTO user_notifications (national_id, notifications) 
                    VALUES (@national_id, @notifications)
                    ON DUPLICATE KEY UPDATE notifications = @notifications",
                    connection
                );
                upsertCmd.Parameters.AddWithValue("@national_id", userId);
                upsertCmd.Parameters.AddWithValue("@notifications", updatedJson);
                
                await upsertCmd.ExecuteNonQueryAsync();

                // Log notification sent
                await _auditService.LogAuditAsync(
                    int.Parse(userId),
                    "notification_sent",
                    JsonSerializer.Serialize(new
                    {
                        template_id = templateId,
                        timestamp = currentTime
                    })
                );
            }

            return new SendNotificationResponse();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending notification");
            return new SendNotificationResponse(ex.Message);
        }
    }

    private (string query, Dictionary<string, object> parameters) BuildFilterQuery(
        Dictionary<string, object> filters,
        string? filterOperation)
    {
        var conditions = new List<string>();
        var parameters = new Dictionary<string, object>();
        var paramCount = 0;

        foreach (var (key, value) in filters)
        {
            switch (key)
            {
                case "salary_range":
                    if (value is JsonElement element && element.ValueKind == JsonValueKind.Object)
                    {
                        var range = JsonSerializer.Deserialize<Dictionary<string, int>>(element.ToString());
                        if (range?.ContainsKey("min") == true)
                        {
                            conditions.Add("salary >= @p" + paramCount);
                            parameters["@p" + paramCount++] = range["min"];
                        }
                        if (range?.ContainsKey("max") == true)
                        {
                            conditions.Add("salary <= @p" + paramCount);
                            parameters["@p" + paramCount++] = range["max"];
                        }
                    }
                    break;

                case "employment_status":
                case "employer_name":
                case "language":
                    conditions.Add($"{key} = @p{paramCount}");
                    parameters["@p" + paramCount++] = value.ToString() ?? "";
                    break;

                case "loan_status":
                    conditions.Add(@"EXISTS (
                        SELECT 1 FROM loan_application_details 
                        WHERE loan_application_details.national_id = Users.national_id 
                        AND loan_application_details.status = @p" + paramCount + ")");
                    parameters["@p" + paramCount++] = value.ToString() ?? "";
                    break;

                case "card_status":
                    conditions.Add(@"EXISTS (
                        SELECT 1 FROM card_application_details 
                        WHERE card_application_details.national_id = Users.national_id 
                        AND card_application_details.status = @p" + paramCount + ")");
                    parameters["@p" + paramCount++] = value.ToString() ?? "";
                    break;

                default:
                    // Dynamic filter handling
                    var tableColumn = key.Split('.');
                    if (tableColumn.Length == 2)
                    {
                        var table = tableColumn[0];
                        var column = tableColumn[1];

                        var allowedTables = new[] { "Users", "loan_application_details", "card_application_details" };
                        if (!allowedTables.Contains(table))
                        {
                            continue;
                        }

                        // Add debug logging to match PHP
                        _logger.LogDebug("Processing filter for table: {Table}, column: {Column}", table, column);
                        _logger.LogDebug("Filter value: {Value}", JsonSerializer.Serialize(value));

                        if (value is JsonElement jsonElement)
                        {
                            if (jsonElement.ValueKind == JsonValueKind.Array)
                            {
                                var columnConditions = new List<string>();
                                var conditions = JsonSerializer.Deserialize<List<Dictionary<string, object>>>(jsonElement.ToString());

                                foreach (var condition in conditions ?? new List<Dictionary<string, object>>())
                                {
                                    if (!condition.ContainsKey("operator") || !condition.ContainsKey("value"))
                                        continue;

                                    var op = condition["operator"].ToString();
                                    var filterValue = condition["value"];

                                    var allowedOperators = new[] { "=", "!=", ">", "<", ">=", "<=", "LIKE", "IN", "BETWEEN" };
                                    if (!allowedOperators.Contains(op))
                                        continue;

                                    if (op == "BETWEEN" && filterValue is JsonElement betweenElement && 
                                        betweenElement.ValueKind == JsonValueKind.Array)
                                    {
                                        var values = JsonSerializer.Deserialize<List<object>>(betweenElement.ToString());
                                        if (values?.Count == 2)
                                        {
                                            var condition = table == "Users"
                                                ? $"{column} >= @p{paramCount} AND {column} <= @p{paramCount + 1}"
                                                : $"EXISTS (SELECT 1 FROM {table} WHERE {table}.national_id = Users.national_id AND {table}.{column} >= @p{paramCount} AND {table}.{column} <= @p{paramCount + 1})";
                                            
                                            columnConditions.Add($"({condition})");
                                            parameters["@p" + paramCount] = values[0];
                                            parameters["@p" + (paramCount + 1)] = values[1];
                                            paramCount += 2;
                                        }
                                    }
                                    else if (op == "IN" && filterValue is JsonElement inElement && 
                                             inElement.ValueKind == JsonValueKind.Array)
                                    {
                                        var values = JsonSerializer.Deserialize<List<object>>(inElement.ToString());
                                        if (values?.Any() == true)
                                        {
                                            var placeholders = string.Join(",", values.Select(_ => $"@p{paramCount++}"));
                                            var condition = table == "Users"
                                                ? $"{column} IN ({placeholders})"
                                                : $"EXISTS (SELECT 1 FROM {table} WHERE {table}.national_id = Users.national_id AND {table}.{column} IN ({placeholders}))";
                                            
                                            columnConditions.Add(condition);
                                            for (var i = 0; i < values.Count; i++)
                                            {
                                                parameters["@p" + (paramCount - values.Count + i)] = values[i];
                                            }
                                        }
                                    }
                                    else
                                    {
                                        var condition = table == "Users"
                                            ? $"{column} {op} @p{paramCount}"
                                            : $"EXISTS (SELECT 1 FROM {table} WHERE {table}.national_id = Users.national_id AND {table}.{column} {op} @p{paramCount})";
                                        
                                        columnConditions.Add(condition);
                                        parameters["@p" + paramCount++] = filterValue.ToString() ?? "";
                                    }
                                }

                                if (columnConditions.Any())
                                {
                                    conditions.Add($"({string.Join(" OR ", columnConditions)})");
                                }
                            }
                            else if (jsonElement.ValueKind == JsonValueKind.Object)
                            {
                                var condition = JsonSerializer.Deserialize<Dictionary<string, object>>(jsonElement.ToString());
                                if (condition?.ContainsKey("operator") == true && condition.ContainsKey("value"))
                                {
                                    var op = condition["operator"].ToString();
                                    var filterValue = condition["value"];

                                    var allowedOperators = new[] { "=", "!=", ">", "<", ">=", "<=", "LIKE", "IN", "BETWEEN" };
                                    if (!allowedOperators.Contains(op))
                                        continue;

                                    if (op == "BETWEEN" && filterValue is JsonElement betweenElement && 
                                        betweenElement.ValueKind == JsonValueKind.Array)
                                    {
                                        var values = JsonSerializer.Deserialize<List<object>>(betweenElement.ToString());
                                        if (values?.Count == 2)
                                        {
                                            var sqlCondition = table == "Users"
                                                ? $"({column} >= @p{paramCount} AND {column} <= @p{paramCount + 1})"
                                                : $"EXISTS (SELECT 1 FROM {table} WHERE {table}.national_id = Users.national_id AND {table}.{column} >= @p{paramCount} AND {table}.{column} <= @p{paramCount + 1})";
                                            
                                            conditions.Add(sqlCondition);
                                            parameters["@p" + paramCount] = values[0];
                                            parameters["@p" + (paramCount + 1)] = values[1];
                                            paramCount += 2;
                                        }
                                    }
                                    else if (op == "IN" && filterValue is JsonElement inElement && 
                                             inElement.ValueKind == JsonValueKind.Array)
                                    {
                                        var values = JsonSerializer.Deserialize<List<object>>(inElement.ToString());
                                        if (values?.Any() == true)
                                        {
                                            var placeholders = string.Join(",", values.Select(_ => $"@p{paramCount++}"));
                                            var sqlCondition = table == "Users"
                                                ? $"{column} IN ({placeholders})"
                                                : $"EXISTS (SELECT 1 FROM {table} WHERE {table}.national_id = Users.national_id AND {table}.{column} IN ({placeholders}))";
                                            
                                            conditions.Add(sqlCondition);
                                            for (var i = 0; i < values.Count; i++)
                                            {
                                                parameters["@p" + (paramCount - values.Count + i)] = values[i];
                                            }
                                        }
                                    }
                                    else
                                    {
                                        var sqlCondition = table == "Users"
                                            ? $"{column} {op} @p{paramCount}"
                                            : $"EXISTS (SELECT 1 FROM {table} WHERE {table}.national_id = Users.national_id AND {table}.{column} {op} @p{paramCount})";
                                        
                                        conditions.Add(sqlCondition);
                                        parameters["@p" + paramCount++] = filterValue.ToString() ?? "";
                                    }
                                }
                            }
                        }
                    }
                    break;
            }
        }

        var joinOperator = filterOperation?.ToUpper() == "OR" ? " OR " : " AND ";
        var whereClause = conditions.Any() 
            ? $"WHERE {string.Join(joinOperator, conditions)}" 
            : "";

        return ($"SELECT national_id FROM Customers {whereClause}", parameters);
    }
} 