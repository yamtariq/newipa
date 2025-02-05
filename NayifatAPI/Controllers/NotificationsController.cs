using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NayifatAPI.Data;
using NayifatAPI.Models;
using NayifatAPI.Services;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Linq.Expressions;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/notifications")]
    public class NotificationsController : ApiBaseController
    {
        private readonly ILogger<NotificationsController> _logger;
        private readonly IAuditLogService _auditLog;

        public NotificationsController(
            ApplicationDbContext context,
            ILogger<NotificationsController> logger,
            IAuditLogService auditLog,
            IConfiguration configuration) : base(context, configuration)
        {
            _logger = logger;
            _auditLog = auditLog;
        }

        [HttpPost("list")]
        public async Task<IActionResult> GetNotifications([FromBody] GetNotificationsRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                var userNotif = await _context.UserNotifications
                    .FirstOrDefaultAsync(un => un.NationalId == request.NationalId);

                if (userNotif == null || string.IsNullOrEmpty(userNotif.Notifications))
                {
                    return Success(new { notifications = new List<object>() });
                }

                List<Dictionary<string, object>> notifications;
                try
                {
                    notifications = JsonSerializer.Deserialize<List<Dictionary<string, object>>>(userNotif.Notifications) ?? new List<Dictionary<string, object>>();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error deserializing notifications for user {NationalId}", request.NationalId);
                    return Success(new { notifications = new List<object>() });
                }

                var currentTime = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("Arab Standard Time"));
                var unreadNotifications = new List<object>();

                if (notifications != null)
                {
                    foreach (var notification in notifications)
                    {
                        // Skip if notification is read or expired
                        if (notification["status"].ToString() != "unread" ||
                            (notification["expires_at"] != null && 
                             DateTime.Parse(notification["expires_at"].ToString()!) < currentTime))
                        {
                            continue;
                        }

                        var template = await _context.NotificationTemplates
                            .FirstOrDefaultAsync(t => t.Id == int.Parse(notification["template_id"].ToString()!));

                        if (template != null && (template.ExpiryAt == null || template.ExpiryAt > currentTime))
                        {
                            object? additionalData = null;
                            if (!string.IsNullOrEmpty(template.AdditionalData))
                            {
                                try
                                {
                                    additionalData = JsonSerializer.Deserialize<object>(template.AdditionalData);
                                }
                                catch (Exception ex)
                                {
                                    _logger.LogError(ex, "Error deserializing additional data for template {TemplateId}", template.Id);
                                }
                            }

                            unreadNotifications.Add(new
                            {
                                id = template.Id,
                                title = template.Title,
                                body = template.Body,
                                title_en = template.TitleEn,
                                body_en = template.BodyEn,
                                title_ar = template.TitleAr,
                                body_ar = template.BodyAr,
                                route = template.Route,
                                additional_data = additionalData,
                                created_at = notification["created_at"],
                                expires_at = notification["expires_at"],
                                status = notification["status"]
                            });
                        }
                    }
                }

                // Check for expired notifications
                var expiredNotifications = notifications.Where(n => 
                    n["expires_at"] != null && 
                    DateTime.Parse(n["expires_at"].ToString()!) < currentTime &&
                    n["template_id"] != null).ToList();

                if (expiredNotifications.Any())
                {
                    var expiredIds = expiredNotifications
                        .Select(n => int.Parse(n["template_id"].ToString()!))
                        .ToList();

                    await _auditLog.LogAsync(request.NationalId, "notification_expired", new
                    {
                        notification_ids = expiredIds,
                        timestamp = currentTime
                    });
                }

                // Log notifications being delivered
                if (unreadNotifications.Any())
                {
                    await _auditLog.LogAsync(request.NationalId, "notification_delivered", new
                    {
                        notification_count = unreadNotifications.Count,
                        notification_ids = unreadNotifications.Select(n => ((dynamic)n).id).ToList(),
                        timestamp = currentTime
                    });
                }

                // Mark as read if requested
                if (request.MarkAsRead && unreadNotifications.Any())
                {
                    foreach (var notif in notifications)
                    {
                        if (notif["status"].ToString() == "unread")
                        {
                            notif["status"] = "read";
                            notif["read_at"] = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("Arab Standard Time"));
                        }
                    }

                    var serializedNotifications = JsonSerializer.Serialize(notifications);
                    await _context.Database.ExecuteSqlRawAsync(
                        "UPDATE user_notifications SET notifications = {0}, last_updated = {1} WHERE national_id = {2}",
                        serializedNotifications, TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("Arab Standard Time")), request.NationalId);

                    // Log notifications being read
                    await _auditLog.LogAsync(request.NationalId, "notification_read", new
                    {
                        notification_ids = unreadNotifications.Select(n => ((dynamic)n).id).ToList(),
                        timestamp = currentTime
                    });
                }

                return Success(new { notifications = unreadNotifications });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in GetNotifications for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }

        [HttpPost("send")]
        public async Task<IActionResult> SendNotification([FromBody] SendNotificationRequest request)
        {
            if (!ValidateApiKey())
            {
                _logger.LogWarning("Invalid or missing API key in notification request");
                return Error("Invalid or expired API key", 401);
            }

            try
            {
                // Log the incoming request
                _logger.LogInformation("Received notification request: {@Request}", 
                    new { 
                        request.Title, 
                        request.TitleEn, 
                        request.TitleAr, 
                        request.Filters, 
                        request.NationalId, 
                        request.NationalIds,
                        // 💡 Add logging for image URLs
                        request.BigPictureUrl,
                        request.LargeIconUrl
                    });

                // Validate request
                bool isMultiLanguage = !string.IsNullOrEmpty(request.TitleEn) && 
                                     !string.IsNullOrEmpty(request.BodyEn) && 
                                     !string.IsNullOrEmpty(request.TitleAr) && 
                                     !string.IsNullOrEmpty(request.BodyAr);

                if (!isMultiLanguage && (string.IsNullOrEmpty(request.Title) || string.IsNullOrEmpty(request.Body)))
                {
                    _logger.LogWarning("Invalid notification content: Missing required fields");
                    return Error("Either provide single language notification (title + body) or multi-language notification (title_en + body_en + title_ar + body_ar)", 400);
                }

                // Get target users
                var targetUsers = await GetTargetUsers(request);
                _logger.LogInformation("Target users query completed. Found {Count} users", targetUsers?.Count ?? 0);

                if (!targetUsers?.Any() ?? true)
                {
                    _logger.LogWarning("No target users found. Filters: {@Filters}", request.Filters);
                    return Error("No target users found for the given criteria", 400);
                }

                // 💡 Special handling for "all" target
                bool isAllUsers = targetUsers.Count == 1 && targetUsers[0] == "all";
                if (isAllUsers)
                {
                    _logger.LogInformation("Processing notification for all users");
                }
                else
                {
                    _logger.LogInformation("Found {Count} target users for notification", targetUsers.Count);
                }

                // Create notification template
                var template = new NotificationTemplate
                {
                    Title = !isMultiLanguage ? request.Title : null,
                    Body = !isMultiLanguage ? request.Body : null,
                    TitleEn = isMultiLanguage ? request.TitleEn : null,
                    BodyEn = isMultiLanguage ? request.BodyEn : null,
                    TitleAr = isMultiLanguage ? request.TitleAr : null,
                    BodyAr = isMultiLanguage ? request.BodyAr : null,
                    Route = request.Route,
                    BigPictureUrl = request.BigPictureUrl,
                    LargeIconUrl = request.LargeIconUrl,
                    AdditionalData = request.AdditionalData != null ? 
                        JsonSerializer.Serialize(request.AdditionalData) : null,
                    TargetCriteria = JsonSerializer.Serialize(new Dictionary<string, object>
                    {
                        ["Customers.national_id"] = new Dictionary<string, string>
                        {
                            ["operator"] = "=",
                            ["value"] = isAllUsers ? "all" : request.Filters?["Customers.national_id"]?.ToString() ?? ""
                        }
                    }),
                    CreatedAt = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("Arab Standard Time")),
                    ExpiryAt = request.ExpiryAt ?? TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("Arab Standard Time")).AddDays(30)
                };

                // 💡 Log template values before saving
                _logger.LogInformation("Template values before saving: {@Template}", 
                    new { 
                        template.Title,
                        template.TitleEn,
                        template.TitleAr,
                        template.BigPictureUrl,
                        template.LargeIconUrl
                    });

                _context.NotificationTemplates.Add(template);
                await _context.SaveChangesAsync();

                _logger.LogInformation("Created notification template with ID: {TemplateId}", template.Id);

                // 💡 Log template creation with special handling for "all" target
                if (isAllUsers)
                {
                    try
                    {
                        // Get first admin user or any user from Customers table for audit log
                        var adminUser = await _context.Customers.FirstOrDefaultAsync();
                        if (adminUser != null)
                        {
                            await _auditLog.LogAsync(adminUser.NationalId, "notification_sent", new
                            {
                                template_id = template.Id,
                                recipient_count = -1, // -1 indicates "all users"
                                target_criteria = new Dictionary<string, object>
                                {
                                    ["Customers.national_id"] = new Dictionary<string, string>
                                    {
                                        ["operator"] = "=",
                                        ["value"] = "all"
                                    }
                                },
                                timestamp = template.CreatedAt,
                                is_broadcast = true
                            });

                            // Create notification reference for "all" target
                            var allNotificationRef = new
                            {
                                template_id = template.Id,
                                status = "unread",
                                created_at = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("Arab Standard Time")),
                                read_at = (DateTime?)null,
                                expires_at = template.ExpiryAt,
                                target = "all"
                            };

                            // Create or update user_notifications entry for "all" target
                            var userNotif = await _context.UserNotifications
                                .FirstOrDefaultAsync(un => un.NationalId == "all");

                            var notifications = new List<object>();
                            if (userNotif != null && !string.IsNullOrEmpty(userNotif.Notifications))
                            {
                                try
                                {
                                    notifications = JsonSerializer.Deserialize<List<object>>(userNotif.Notifications) ?? new List<object>();
                                }
                                catch (Exception ex)
                                {
                                    _logger.LogError(ex, "Error deserializing notifications for all users");
                                    notifications = new List<object>();
                                }
                            }

                            notifications.Insert(0, allNotificationRef);
                            if (notifications.Count > 50)
                            {
                                notifications = notifications.Take(50).ToList();
                            }

                            var serializedNotifications = JsonSerializer.Serialize(notifications);

                            if (userNotif == null)
                            {
                                await _context.Database.ExecuteSqlRawAsync(
                                    "INSERT INTO user_notifications (national_id, notifications, last_updated) VALUES ({0}, {1}, {2})",
                                    "all", serializedNotifications, TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("Arab Standard Time")));
                                _logger.LogInformation("Created new UserNotification entry for all users");
                            }
                            else
                            {
                                await _context.Database.ExecuteSqlRawAsync(
                                    "UPDATE user_notifications SET notifications = {0}, last_updated = {1} WHERE national_id = {2}",
                                    serializedNotifications, TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("Arab Standard Time")), "all");
                                _logger.LogInformation("Updated existing UserNotification for all users");
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error processing all-users notification. Template ID: {TemplateId}", template.Id);
                    }

                    return Success(new
                    {
                        status = "success",
                        message = "Successfully created notification for all users",
                        template_id = template.Id
                    });
                }

                // Create notification reference
                var notificationRef = new
                {
                    template_id = template.Id,
                    status = "unread",
                    created_at = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("Arab Standard Time")),
                    read_at = (DateTime?)null,
                    expires_at = template.ExpiryAt
                };

                // Send to users
                int successCount = 0;
                foreach (var userId in targetUsers)
                {
                    try
                    {
                        var userNotif = await _context.UserNotifications
                            .FirstOrDefaultAsync(un => un.NationalId == userId);

                        _logger.LogInformation("Processing notification for user {UserId}. Existing notification record: {Exists}", 
                            userId, userNotif != null);

                        var notifications = new List<object>();
                        if (userNotif != null && !string.IsNullOrEmpty(userNotif.Notifications))
                        {
                            try
                            {
                                notifications = JsonSerializer.Deserialize<List<object>>(userNotif.Notifications) ?? new List<object>();
                            }
                            catch (Exception ex)
                            {
                                _logger.LogError(ex, "Error deserializing notifications for user {UserId}", userId);
                                notifications = new List<object>();
                            }
                        }

                        _logger.LogInformation("Current notifications count for user {UserId}: {Count}", 
                            userId, notifications.Count);

                        notifications.Insert(0, notificationRef);
                        if (notifications.Count > 50) 
                        {
                            notifications = notifications.Take(50).ToList();
                            _logger.LogInformation("Trimmed notifications to 50 for user: {UserId}", userId);
                        }

                        var serializedNotifications = JsonSerializer.Serialize(notifications);
                        _logger.LogInformation("Serialized new notifications for user {UserId}. Length: {Length}", 
                            userId, serializedNotifications.Length);

                        try
                        {
                            if (userNotif == null)
                            {
                                // Create new user notification
                                await _context.Database.ExecuteSqlRawAsync(
                                    "INSERT INTO user_notifications (national_id, notifications, last_updated) VALUES ({0}, {1}, {2})",
                                    userId, serializedNotifications, TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("Arab Standard Time")));
                                _logger.LogInformation("Created new UserNotification entry for user: {UserId}", userId);
                            }
                            else
                            {
                                // Update existing user notification
                                await _context.Database.ExecuteSqlRawAsync(
                                    "UPDATE user_notifications SET notifications = {0}, last_updated = {1} WHERE national_id = {2}",
                                    serializedNotifications, TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("Arab Standard Time")), userId);
                                _logger.LogInformation("Updated existing UserNotification for user: {UserId}", userId);
                            }
                            successCount++;
                        }
                        catch (Exception dbEx)
                        {
                            _logger.LogError(dbEx, "Database operation failed for user {UserId}. Error: {Error}", 
                                userId, dbEx.Message);
                            throw;
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Failed to process notification for user: {UserId}. Error: {Error}", 
                            userId, ex.Message);
                    }
                }

                if (successCount == 0)
                {
                    _logger.LogError("Failed to send notifications to any users. Total targets: {Count}", targetUsers.Count);
                    return Error("Failed to send notifications to any users", 500);
                }

                // Log successful deliveries
                await _auditLog.LogAsync(request.NationalId ?? targetUsers.First(), "notification_delivered", new
                {
                    template_id = template.Id,
                    successful_sends = successCount,
                    total_recipients = targetUsers.Count,
                    timestamp = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("Arab Standard Time"))
                });

                _logger.LogInformation(
                    "Successfully sent notifications. Template: {TemplateId}, Success: {SuccessCount}, Total: {TotalCount}", 
                    template.Id, successCount, targetUsers.Count);

                return Success(new
                {
                    status = "success",
                    message = $"Successfully sent notifications to {successCount} users",
                    total_recipients = targetUsers.Count,
                    successful_sends = successCount
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in SendNotification");
                return Error("Internal server error", 500);
            }
        }

        private List<string> ParseInOperatorValues(object? value)
        {
            var values = new List<string>();
            if (value == null) return values;

            try
            {
                switch (value)
                {
                    case string str:
                        try
                        {
                            var jsonValues = JsonSerializer.Deserialize<string[]>(str);
                            if (jsonValues != null)
                            {
                                values.AddRange(jsonValues.Where(x => x != null)!);
                                return values;
                            }
                        }
                        catch
                        {
                            values.Add(str);
                            _logger.LogInformation("Using string value as single item for IN operator");
                        }
                        break;

                    case JsonElement element:
                        if (element.ValueKind == JsonValueKind.Array)
                        {
                            values.AddRange(element.EnumerateArray()
                                .Where(x => x.ValueKind == JsonValueKind.String)
                                .Select(x => x.GetString())
                                .Where(x => x != null)!);
                        }
                        else if (element.ValueKind == JsonValueKind.String)
                        {
                            var str = element.GetString();
                            if (str != null) values.Add(str);
                        }
                        break;

                    case IEnumerable<object> array:
                        values.AddRange(array
                            .Select(x => x?.ToString())
                            .Where(x => x != null)!);
                        break;

                    default:
                        var str2 = value.ToString();
                        if (str2 != null) values.Add(str2);
                        break;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error parsing IN operator values");
            }

            return values;
        }

        private IQueryable<Customer> ApplyFilter(
            IQueryable<Customer> query,
            string column,
            string op,
            object? val)
        {
            if (val == null) return query;

            try
            {
                switch (op.ToUpper())
                {
                    case "=":
                        // 💡 Special handling for national_id field
                        if (column.ToLower() == "national_id")
                        {
                            return query.Where(c => c.NationalId == val.ToString());
                        }
                        return query.Where(c => EF.Property<string>(c, column) == val.ToString());
                    
                    case "!=":
                        // 💡 Special handling for national_id field
                        if (column.ToLower() == "national_id")
                        {
                            return query.Where(c => c.NationalId != val.ToString());
                        }
                        return query.Where(c => EF.Property<string>(c, column) != val.ToString());
                    
                    case ">":
                        if (decimal.TryParse(val.ToString(), out decimal gtValue))
                        {
                            // 💡 Special handling for national_id field
                            if (column.ToLower() == "national_id")
                            {
                                return query.Where(c => string.Compare(c.NationalId, val.ToString()) > 0);
                            }
                            return query.Where(c => EF.Property<decimal>(c, column) > gtValue);
                        }
                        break;
                    
                    case "<":
                        if (decimal.TryParse(val.ToString(), out decimal ltValue))
                        {
                            // 💡 Special handling for national_id field
                            if (column.ToLower() == "national_id")
                            {
                                return query.Where(c => string.Compare(c.NationalId, val.ToString()) < 0);
                            }
                            return query.Where(c => EF.Property<decimal>(c, column) < ltValue);
                        }
                        break;
                    
                    case ">=":
                        if (decimal.TryParse(val.ToString(), out decimal gteValue))
                        {
                            // 💡 Special handling for national_id field
                            if (column.ToLower() == "national_id")
                            {
                                return query.Where(c => string.Compare(c.NationalId, val.ToString()) >= 0);
                            }
                            return query.Where(c => EF.Property<decimal>(c, column) >= gteValue);
                        }
                        break;
                    
                    case "<=":
                        if (decimal.TryParse(val.ToString(), out decimal lteValue))
                        {
                            // 💡 Special handling for national_id field
                            if (column.ToLower() == "national_id")
                            {
                                return query.Where(c => string.Compare(c.NationalId, val.ToString()) <= 0);
                            }
                            return query.Where(c => EF.Property<decimal>(c, column) <= lteValue);
                        }
                        break;
                    
                    case "LIKE":
                        return query.Where(c => EF.Functions.Like(
                            EF.Property<string>(c, column), 
                            $"%{val}%"));
                    
                    case "IN":
                        var values = ParseInOperatorValues(val);
                        if (values.Any())
                        {
                            // 💡 Special handling for national_id field
                            if (column.ToLower() == "national_id")
                            {
                                return query.Where(c => values.Contains(c.NationalId));
                            }
                            switch (column.ToLower())
                            {
                                case "city":
                                    return query.Where(c => values.Contains(c.City));
                                default:
                                    return query.Where(c => values.Contains(EF.Property<string>(c, column)));
                            }
                        }
                        break;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error applying filter: {Column} {Op} {Value}", column, op, val);
            }

            return query;
        }

        private IQueryable<Customer> ApplyNumericFilter(
            IQueryable<Customer> query,
            string propertyName,
            string op,
            decimal value,
            decimal? value2 = null)
        {
            switch (op.ToUpper())
            {
                case "=":
                    return query.Where(c => EF.Property<decimal>(c, propertyName) == value);
                case "!=":
                    return query.Where(c => EF.Property<decimal>(c, propertyName) != value);
                case ">":
                    return query.Where(c => EF.Property<decimal>(c, propertyName) > value);
                case "<":
                    return query.Where(c => EF.Property<decimal>(c, propertyName) < value);
                case ">=":
                    return query.Where(c => EF.Property<decimal>(c, propertyName) >= value);
                case "<=":
                    return query.Where(c => EF.Property<decimal>(c, propertyName) <= value);
                case "BETWEEN":
                    if (value2.HasValue)
                    {
                        return query.Where(c => EF.Property<decimal>(c, propertyName) >= value && 
                                              EF.Property<decimal>(c, propertyName) <= value2.Value);
                    }
                    return query;
                case "NOT BETWEEN":
                    if (value2.HasValue)
                    {
                        return query.Where(c => EF.Property<decimal>(c, propertyName) < value || 
                                              EF.Property<decimal>(c, propertyName) > value2.Value);
                    }
                    return query;
                default:
                    return query;
            }
        }

        private IQueryable<Customer> ApplyIntFilter(
            IQueryable<Customer> query,
            string propertyName,
            string op,
            int value,
            int? value2 = null)
        {
            switch (op.ToUpper())
            {
                case "=":
                    return query.Where(c => EF.Property<int>(c, propertyName) == value);
                case "!=":
                    return query.Where(c => EF.Property<int>(c, propertyName) != value);
                case ">":
                    return query.Where(c => EF.Property<int>(c, propertyName) > value);
                case "<":
                    return query.Where(c => EF.Property<int>(c, propertyName) < value);
                case ">=":
                    return query.Where(c => EF.Property<int>(c, propertyName) >= value);
                case "<=":
                    return query.Where(c => EF.Property<int>(c, propertyName) <= value);
                case "BETWEEN":
                    if (value2.HasValue)
                    {
                        return query.Where(c => EF.Property<int>(c, propertyName) >= value && 
                                              EF.Property<int>(c, propertyName) <= value2.Value);
                    }
                    return query;
                case "NOT BETWEEN":
                    if (value2.HasValue)
                    {
                        return query.Where(c => EF.Property<int>(c, propertyName) < value || 
                                              EF.Property<int>(c, propertyName) > value2.Value);
                    }
                    return query;
                default:
                    return query;
            }
        }

        private IQueryable<Customer> ApplyStringFilter(
            IQueryable<Customer> query,
            string propertyName,
            string op,
            string value)
        {
            if (string.IsNullOrEmpty(value)) return query;

            switch (op.ToUpper())
            {
                case "=":
                    return query.Where(c => EF.Property<string>(c, propertyName) == value);
                case "!=":
                    return query.Where(c => EF.Property<string>(c, propertyName) != value);
                case "LIKE":
                    return query.Where(c => EF.Functions.Like(
                        EF.Property<string>(c, propertyName), 
                        $"%{value}%"));
                case "NOT LIKE":
                    return query.Where(c => !EF.Functions.Like(
                        EF.Property<string>(c, propertyName), 
                        $"%{value}%"));
                case "IN":
                    var values = ParseInOperatorValues(value);
                    if (values.Any())
                    {
                        var nonNullValues = values.Where(v => !string.IsNullOrEmpty(v)).ToList();
                        if (nonNullValues.Any())
                        {
                            return query.Where(c => nonNullValues.Contains(EF.Property<string>(c, propertyName)));
                        }
                    }
                    break;
                case "NOT IN":
                    var notValues = ParseInOperatorValues(value);
                    if (notValues.Any())
                    {
                        var nonNullValues = notValues.Where(v => !string.IsNullOrEmpty(v)).ToList();
                        if (nonNullValues.Any())
                        {
                            return query.Where(c => !nonNullValues.Contains(EF.Property<string>(c, propertyName)));
                        }
                    }
                    break;
            }
            return query;
        }

        private async Task<List<string>> GetTargetUsers(SendNotificationRequest request)
        {
            _logger.LogInformation("Starting GetTargetUsers with request type: {RequestType}", 
                !string.IsNullOrEmpty(request.NationalId) ? "Single User" :
                request.NationalIds?.Any() == true ? "Multiple Users" :
                request.Filters?.Any() == true ? "Filtered Users" : "Unknown");

            // 💡 Special case: Check for "all" in national_id filter
            if (request.Filters?.TryGetValue("Customers.national_id", out var nationalIdFilter) == true)
            {
                var filterObj = JsonSerializer.Deserialize<Dictionary<string, string>>(nationalIdFilter.ToString());
                if (filterObj != null && filterObj.TryGetValue("value", out var value) && value.ToLower() == "all")
                {
                    _logger.LogInformation("Special case: Using 'all' as target without fetching IDs");
                    return new List<string> { "all" }; // Return special "all" indicator
                }
            }

            // Case 1: Single user
            if (!string.IsNullOrEmpty(request.NationalId))
            {
                var users = await _context.Customers
                    .Where(c => c.NationalId == request.NationalId)
                    .Select(c => c.NationalId)
                    .ToListAsync();
                
                _logger.LogInformation("Found {Count} users matching national ID {NationalId}", 
                    users.Count, request.NationalId);
                    
                return users;
            }

            // Case 2: Multiple specific users
            if (request.NationalIds?.Any() == true)
            {
                var validIds = request.NationalIds.Where(id => !string.IsNullOrEmpty(id)).ToList();
                if (!validIds.Any())
                {
                    _logger.LogWarning("No valid National IDs provided");
                    return new List<string>();
                }

                var users = await _context.Customers
                    .Where(c => validIds.Contains(c.NationalId))
                    .Select(c => c.NationalId)
                    .ToListAsync();
                    
                _logger.LogInformation("Found {Count} users from provided National IDs", users.Count);
                
                return users;
            }

            // Case 3: Filtered users
            if (request.Filters?.Any() != true)
            {
                _logger.LogWarning("No filters provided");
                return new List<string>();
            }

            var query = _context.Customers.AsQueryable();
            bool isOrOperation = request.Filters.GetValueOrDefault("filter_operation")?.ToString()?.ToUpper() == "OR";
            var filterGroups = new List<IQueryable<Customer>>();
            
            foreach (var filter in request.Filters.Where(f => f.Key != "filter_operation"))
            {
                try
                {
                    var localQuery = query;
                    bool filterApplied = false;

                    // Parse table and field from filter key
                    var parts = filter.Key.Split('.');
                    var tableName = parts.Length > 1 ? parts[0].ToLower() : string.Empty;
                    var fieldName = parts.Length > 1 ? parts[1] : filter.Key;

                    // Skip if no table specified
                    if (string.IsNullOrEmpty(tableName))
                    {
                        _logger.LogWarning("No table specified in filter key: {Key}", filter.Key);
                        continue;
                    }

                    _logger.LogInformation("Processing filter for table: {Table}, field: {Field}", tableName, fieldName);

                    // Handle JsonElement type for filter value
                    if (filter.Value is System.Text.Json.JsonElement jsonElement)
                    {
                        if (jsonElement.ValueKind == JsonValueKind.Object)
                        {
                            var op = jsonElement.TryGetProperty("operator", out var opElement) ? 
                                opElement.GetString() : "=";
                            
                            // Handle regular operators
                            if (jsonElement.TryGetProperty("value", out var regularValElement))
                            {
                                var val = regularValElement.GetString();
                                if (!string.IsNullOrEmpty(val))
                                {
                                    // Remove table prefix if exists
                                    var actualFieldName = fieldName.Contains(".") ? fieldName.Split('.')[1] : fieldName;
                                    _logger.LogInformation("Processing filter: {Field} {Op} {Value}", actualFieldName, op, val);

                                    // 💡 Special handling for national_id field
                                    if (actualFieldName.ToLower() == "national_id")
                                    {
                                        localQuery = query.Where(c => c.NationalId == val);
                                        filterApplied = true;
                                        _logger.LogInformation("Applied national_id filter: {Op} {Value}", op, val);
                                    }
                                    else
                                    {
                                        // Try parsing as decimal first
                                        if (decimal.TryParse(val, out decimal decimalValue))
                                        {
                                            localQuery = ApplyNumericFilter(localQuery, actualFieldName, op!, decimalValue);
                                            filterApplied = true;
                                            _logger.LogInformation("Applied {Field} numeric filter: {Op} {Value}", actualFieldName, op, decimalValue);
                                        }
                                        // Then try as integer
                                        else if (int.TryParse(val, out int intValue))
                                        {
                                            localQuery = ApplyIntFilter(localQuery, actualFieldName, op!, intValue);
                                            filterApplied = true;
                                            _logger.LogInformation("Applied {Field} integer filter: {Op} {Value}", actualFieldName, op, intValue);
                                        }
                                        // If not numeric, treat as string
                                        else
                                        {
                                            localQuery = ApplyStringFilter(localQuery, actualFieldName, op!, val);
                                            filterApplied = true;
                                            _logger.LogInformation("Applied {Field} string filter: {Op} {Value}", actualFieldName, op, val);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else if (filter.Value != null)
                    {
                        // Simple equals filter
                        var strValue = filter.Value.ToString();
                        if (!string.IsNullOrEmpty(strValue))
                        {
                            switch (fieldName.ToLower())
                            {
                                case "national_id":
                                    localQuery = localQuery.Where(c => c.NationalId == strValue);
                                    filterApplied = true;
                                    _logger.LogInformation("Applied simple national_id filter: {Value}", strValue);
                                    break;
                                case "city":
                                    localQuery = localQuery.Where(c => c.City == strValue);
                                    filterApplied = true;
                                    _logger.LogInformation("Applied simple City filter: {Value}", strValue);
                                    break;
                                default:
                                    _logger.LogWarning("Unknown field name in simple filter: {Field}", fieldName);
                                    break;
                            }
                        }
                    }

                    if (filterApplied)
                    {
                        filterGroups.Add(localQuery);
                        _logger.LogInformation("Added filter group for {Table}.{Field}", tableName, fieldName);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error applying filter: {Key} = {Value}", filter.Key, filter.Value);
                }
            }

            // Apply the filters based on OR/AND operation
            if (!filterGroups.Any())
            {
                _logger.LogWarning("No valid filters were applied");
                return new List<string>();
            }

            if (isOrOperation)
            {
                // Combine all filter groups with OR
                var unionQuery = filterGroups.First();
                foreach (var group in filterGroups.Skip(1))
                {
                    unionQuery = unionQuery.Union(group);
                }
                query = unionQuery;
            }
            else
            {
                // Combine all filter groups with AND
                query = filterGroups.First();
                foreach (var group in filterGroups.Skip(1))
                {
                    query = query.Intersect(group);
                }
            }

            _logger.LogInformation("Executing filter query with operation: {Operation}", isOrOperation ? "OR" : "AND");
            var results = await query.Select(c => c.NationalId).ToListAsync();
            _logger.LogInformation("Found {Count} users after applying filters", results.Count);
            
            return results;
        }
    }

    public class GetNotificationsRequest
    {
        public required string NationalId { get; set; }
        public bool MarkAsRead { get; set; }
    }

    public class SendNotificationRequest
    {
        // Single language
        public string? Title { get; set; }
        public string? Body { get; set; }

        // Multi-language
        [JsonPropertyName("title_en")]
        public string? TitleEn { get; set; }
        
        [JsonPropertyName("body_en")]
        public string? BodyEn { get; set; }
        
        [JsonPropertyName("title_ar")]
        public string? TitleAr { get; set; }
        
        [JsonPropertyName("body_ar")]
        public string? BodyAr { get; set; }

        // 💡 Add image URL properties
        [JsonPropertyName("big_picture_url")]
        public string? BigPictureUrl { get; set; }
        
        [JsonPropertyName("large_icon_url")]
        public string? LargeIconUrl { get; set; }

        // Target users (one will be used)
        [JsonPropertyName("national_id")]
        public string? NationalId { get; set; }
        
        [JsonPropertyName("national_ids")]
        public List<string>? NationalIds { get; set; }
        
        public Dictionary<string, object>? Filters { get; set; }

        // Optional data
        public string? Route { get; set; }
        
        [JsonPropertyName("additional_data")]
        public object? AdditionalData { get; set; }
        
        [JsonPropertyName("expiry_at")]
        public DateTime? ExpiryAt { get; set; }
    }
} 