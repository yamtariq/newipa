using MySql.Data.MySqlClient;
using System.Data;
using Microsoft.Extensions.Options;
using NayifatAPI.Models;
using System.Security.Cryptography;
using Dapper;
using BCrypt.Net;

namespace NayifatAPI.Services;

public class DatabaseSettings
{
    public string ConnectionString { get; set; } = string.Empty;
}

public interface IAuthService
{
    Task<Dictionary<string, object>?> GetCustomerByNationalId(string nationalId);
    Task LogAuthAttempt(string nationalId, string? deviceId, string status, string? failureReason = null);
    Task UpdateDeviceLastUsed(string nationalId, string deviceId);
    Task<(string? userId, string? nationalId)> ValidateRefreshToken(string refreshToken);
    Task UpdateAccessToken(string userId, string accessToken, int expiryTimestamp);
    Task<(string Status, string Message, string? OtpCode)> GenerateOtpAsync(string nationalId);
    Task<(string Status, string Message, Dictionary<string, object>? Debug)> VerifyOtpAsync(string nationalId, string otpCode);
    Task<(string Status, string Code, string Message, string MessageAr)> ChangePasswordAsync(string nationalId, string newPassword, string type);
    Task<bool> CheckNationalIdExists(string nationalId);
    Task<(bool success, string message)> RegisterUser(UserRegistrationRequest request);
    GovData GetGovernmentData(UserRegistrationRequest request);
    Task<DeviceRegistrationResponse> RegisterDevice(DeviceRegistrationRequest request, string ipAddress, string userAgent);
}

public class AuthService : IAuthService
{
    private readonly DatabaseService _db;
    private readonly ILogger<AuthService> _logger;
    private readonly IHttpContextAccessor _httpContextAccessor;
    public const int TOKEN_EXPIRY = 3600; // 1 hour, matching PHP

    public AuthService(DatabaseService db, ILogger<AuthService> logger, IHttpContextAccessor httpContextAccessor)
    {
        _db = db;
        _logger = logger;
        _httpContextAccessor = httpContextAccessor;
    }

    public async Task<Dictionary<string, object>?> GetCustomerByNationalId(string nationalId)
    {
        try
        {
            using var connection = _db.CreateConnection();
            await connection.OpenAsync();

            using var command = new MySqlCommand("SELECT * FROM Customers WHERE national_id = @nationalId", (MySqlConnection)connection);
            command.Parameters.Add("@nationalId", MySqlDbType.VarChar).Value = nationalId;

            using var reader = await command.ExecuteReaderAsync();
            if (!await reader.ReadAsync())
                return null;

            var result = new Dictionary<string, object>();
            for (int i = 0; i < reader.FieldCount; i++)
            {
                var value = reader.GetValue(i);
                result[reader.GetName(i)] = value == DBNull.Value ? null : value;
            }

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting customer by national ID: {NationalId}", nationalId);
            throw;
        }
    }

    public async Task LogAuthAttempt(string nationalId, string? deviceId, string status, string? failureReason = null)
    {
        try
        {
            using var connection = _db.CreateConnection();
            await connection.OpenAsync();

            using var command = new MySqlCommand(@"
                INSERT INTO auth_logs (
                    national_id, deviceId, auth_type, status, 
                    ip_address, user_agent, failure_reason
                ) VALUES (
                    @nationalId, @deviceId, 'password', @status, 
                    @ipAddress, @userAgent, @failureReason
                )", (MySqlConnection)connection);

            var context = _httpContextAccessor.HttpContext;
            var ipAddress = context?.Connection.RemoteIpAddress?.ToString() ?? "";
            var userAgent = context?.Request.Headers.UserAgent.ToString() ?? "";

            command.Parameters.Add("@nationalId", MySqlDbType.VarChar).Value = nationalId;
            command.Parameters.Add("@deviceId", MySqlDbType.VarChar).Value = deviceId == null ? DBNull.Value : deviceId;
            command.Parameters.Add("@status", MySqlDbType.VarChar).Value = status;
            command.Parameters.Add("@ipAddress", MySqlDbType.VarChar).Value = ipAddress;
            command.Parameters.Add("@userAgent", MySqlDbType.VarChar).Value = userAgent;
            command.Parameters.Add("@failureReason", MySqlDbType.VarChar).Value = failureReason == null ? DBNull.Value : failureReason;

            await command.ExecuteNonQueryAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error logging auth attempt for national ID: {NationalId}", nationalId);
            throw;
        }
    }

    public async Task UpdateDeviceLastUsed(string nationalId, string deviceId)
    {
        try
        {
            using var connection = _db.CreateConnection();
            await connection.OpenAsync();

            using var command = new MySqlCommand(@"
                UPDATE customer_devices 
                SET last_used_at = NOW()
                WHERE national_id = @nationalId AND deviceId = @deviceId", (MySqlConnection)connection);

            command.Parameters.Add("@nationalId", MySqlDbType.VarChar).Value = nationalId;
            command.Parameters.Add("@deviceId", MySqlDbType.VarChar).Value = deviceId;

            await command.ExecuteNonQueryAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating device last used for national ID: {NationalId}, deviceId: {DeviceId}", nationalId, deviceId);
            throw;
        }
    }

    public async Task<(string? userId, string? nationalId)> ValidateRefreshToken(string refreshToken)
    {
        using var connection = await _db.GetConnectionAsync();
        using var command = connection.CreateCommand();
        
        command.CommandText = @"
            SELECT user_id, national_id 
            FROM user_tokens 
            WHERE refresh_token = @refreshToken 
            AND refresh_expires_at > NOW()";
            
        command.Parameters.AddWithValue("@refreshToken", refreshToken);

        using var reader = await command.ExecuteReaderAsync();
        
        if (!await reader.ReadAsync())
        {
            return (null, null);
        }

        return (
            reader.GetString("user_id"),
            reader.GetString("national_id")
        );
    }

    public async Task UpdateAccessToken(string userId, string accessToken, int expiryTimestamp)
    {
        using var connection = await _db.GetConnectionAsync();
        using var command = connection.CreateCommand();
        
        command.CommandText = @"
            UPDATE user_tokens 
            SET access_token = @accessToken, 
                access_expires_at = FROM_UNIXTIME(@expiryTimestamp)
            WHERE user_id = @userId";
            
        command.Parameters.AddWithValue("@accessToken", accessToken);
        command.Parameters.AddWithValue("@expiryTimestamp", expiryTimestamp);
        command.Parameters.AddWithValue("@userId", userId);

        await command.ExecuteNonQueryAsync();
    }

    private string GenerateOtpCode(int length = 6)
    {
        using var rng = RandomNumberGenerator.Create();
        byte[] randomNumber = new byte[length];
        rng.GetBytes(randomNumber);
        
        int min = (int)Math.Pow(10, length - 1);
        int max = (int)Math.Pow(10, length) - 1;
        
        int value = Math.Abs(BitConverter.ToInt32(randomNumber, 0));
        return (min + (value % (max - min + 1))).ToString().PadLeft(length, '0');
    }

    public async Task<(string Status, string Message, string? OtpCode)> GenerateOtpAsync(string nationalId)
    {
        try
        {
            using var connection = await _db.CreateConnectionAsync();
            
            // Check rate limiting
            var currentTime = DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss");
            var checkRateLimit = @"SELECT expires_at FROM OTP_Codes 
                                 WHERE national_id = @NationalId 
                                 AND expires_at > @CurrentTime 
                                 ORDER BY expires_at DESC LIMIT 1";
            
            var existingOtp = await connection.QueryFirstOrDefaultAsync<DateTime?>(
                checkRateLimit,
                new { NationalId = nationalId, CurrentTime = currentTime }
            );

            if (existingOtp.HasValue)
            {
                await LogAuditAsync(connection, nationalId, "OTP Generation Failed", 
                    $"Rate limit exceeded for national_id: {nationalId}");
                
                return ("error", "OTP request rate limit exceeded. Please wait before requesting again.", null);
            }

            // Generate new OTP
            var otpCode = GenerateOtpCode(6);
            var hashedOtp = Convert.ToHexString(SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(otpCode)));
            var expiresAt = DateTime.UtcNow.AddMinutes(5).ToString("yyyy-MM-dd HH:mm:ss");

            // Store OTP
            var insertOtp = @"INSERT INTO OTP_Codes (otp_code, expires_at, is_used, national_id) 
                            VALUES (@HashedOtp, @ExpiresAt, 0, @NationalId)";
            
            await connection.ExecuteAsync(insertOtp, new
            {
                HashedOtp = hashedOtp,
                ExpiresAt = expiresAt,
                NationalId = nationalId
            });

            await LogAuditAsync(connection, nationalId, "OTP Generation Successful", 
                "OTP generated and sent to user phone");

            return ("success", "OTP generated successfully and sent to the user phone", otpCode);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating OTP for national ID: {NationalId}", nationalId);
            return ("error", "Failed to generate OTP", null);
        }
    }

    private async Task LogAuditAsync(IDbConnection connection, string? nationalId, string action, string details)
    {
        try
        {
            var riyadhTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Asia/Riyadh");
            var currentTime = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, riyadhTimeZone);

            var query = @"INSERT INTO audit_logs (national_id, action, details, created_at) 
                         VALUES (@NationalId, @Action, @Details, @CreatedAt)";
            
            await connection.ExecuteAsync(query, new
            {
                NationalId = nationalId,
                Action = action,
                Details = details,
                CreatedAt = currentTime
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error logging audit for national ID: {NationalId}, action: {Action}", nationalId, action);
        }
    }

    public async Task<(string Status, string Message, Dictionary<string, object>? Debug)> VerifyOtpAsync(string nationalId, string otpCode)
    {
        try
        {
            using var connection = await _db.CreateConnectionAsync();
            var currentTime = DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss");
            
            // Hash the OTP code before verification
            var hashedOtp = Convert.ToHexString(SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(otpCode)));

            // Verify the OTP
            var query = @"SELECT otp_id, expires_at 
                         FROM OTP_Codes 
                         WHERE national_id = @NationalId 
                         AND otp_code = @HashedOtp 
                         AND is_used = 0 
                         AND expires_at > @CurrentTime";

            var result = await connection.QueryFirstOrDefaultAsync<dynamic>(
                query,
                new { NationalId = nationalId, HashedOtp = hashedOtp, CurrentTime = currentTime }
            );

            if (result == null)
            {
                await LogAuditAsync(connection, nationalId, "OTP Verification Failed", 
                    $"Invalid or expired OTP for national_id: {nationalId}");

                return ("error", "Invalid or expired OTP", new Dictionary<string, object>
                {
                    { "national_id", nationalId },
                    { "otp_code", otpCode }
                });
            }

            // Check if the OTP has expired (double check even though we have it in the query)
            if (DateTime.Parse(result.expires_at.ToString()) < DateTime.UtcNow)
            {
                await LogAuditAsync(connection, nationalId, "OTP Verification Failed", 
                    $"OTP expired for national_id: {nationalId}");
                return ("error", "OTP has expired", null);
            }

            // Mark the OTP as used
            var updateQuery = "UPDATE OTP_Codes SET is_used = TRUE WHERE otp_id = @OtpId";
            var updateResult = await connection.ExecuteAsync(updateQuery, new { OtpId = result.otp_id });

            if (updateResult > 0)
            {
                await LogAuditAsync(connection, nationalId, "OTP Verification Successful", 
                    $"OTP verified successfully for national_id: {nationalId}");
                return ("success", "OTP verified successfully", null);
            }
            else
            {
                await LogAuditAsync(connection, nationalId, "OTP Verification Failed", 
                    $"Failed to mark OTP as used for national_id: {nationalId}");
                return ("error", "Failed to mark OTP as used", null);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error verifying OTP for national ID: {NationalId}", nationalId);
            return ("error", "Failed to verify OTP", null);
        }
    }

    public async Task<(string Status, string Code, string Message, string MessageAr)> ChangePasswordAsync(string nationalId, string newPassword, string type)
    {
        using var connection = await _db.CreateConnectionAsync();
        await connection.OpenAsync();
        using var transaction = await connection.BeginTransactionAsync(IsolationLevel.ReadCommitted);

        try
        {
            var riyadhTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Asia/Riyadh");
            var currentTime = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, riyadhTimeZone);

            // Validate password requirements
            if (newPassword.Length < 8 || 
                !newPassword.Any(char.IsUpper) || 
                !newPassword.Any(char.IsLower) || 
                !newPassword.Any(char.IsDigit))
            {
                return ("error", "INVALID_PASSWORD_FORMAT", 
                    "Password must be at least 8 characters and include uppercase, lowercase, and numbers",
                    "كلمة المرور يجب أن تحتوي على 8 أحرف على الأقل، وتتضمن أحرف كبيرة وصغيرة وأرقام");
            }

            // Check if user exists
            var query = "SELECT id, password FROM Customers WHERE national_id = @NationalId";
            var customer = await connection.QueryFirstOrDefaultAsync<dynamic>(query, new { NationalId = nationalId });

            if (customer == null)
            {
                return ("error", "USER_NOT_FOUND", "Customer not found", "المستخدم غير موجود");
            }

            // Check if new password is same as old password
            string? currentPassword = customer.password?.ToString();
            if (!string.IsNullOrEmpty(currentPassword) && BCrypt.Net.BCrypt.Verify(newPassword, currentPassword))
            {
                return ("error", "SAME_AS_OLD_PASSWORD", 
                    "New password must be different from current password",
                    "كلمة المرور الجديدة يجب أن تكون مختلفة عن كلمة المرور الحالية");
            }

            // Hash the new password
            var hashedPassword = BCrypt.Net.BCrypt.HashPassword(newPassword);

            // Update the password
            var updateQuery = "UPDATE Customers SET password = @Password WHERE national_id = @NationalId";
            await connection.ExecuteAsync(updateQuery, new { Password = hashedPassword, NationalId = nationalId }, transaction);

            // Log the password change
            var context = _httpContextAccessor.HttpContext;
            var ipAddress = context?.Connection.RemoteIpAddress?.ToString() ?? "";
            var userAgent = context?.Request.Headers.UserAgent.ToString() ?? "";

            var logQuery = @"INSERT INTO password_change_logs (
                national_id, type, status, ip_address, user_agent, created_at
            ) VALUES (@NationalId, @Type, @Status, @IpAddress, @UserAgent, @CreatedAt)";

            await connection.ExecuteAsync(logQuery, new
            {
                NationalId = nationalId,
                Type = type,
                Status = "success",
                IpAddress = ipAddress,
                UserAgent = userAgent,
                CreatedAt = currentTime
            }, transaction);

            await transaction.CommitAsync();

            await LogAuditAsync(connection, customer.id.ToString(), "Password Change Successful", 
                $"Password changed successfully for national_id: {nationalId}");

            return ("success", "", "Password changed successfully", "تم تغيير كلمة المرور بنجاح");
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            _logger.LogError(ex, "Error changing password for national ID: {NationalId}", nationalId);
            return ("error", "UNKNOWN_ERROR", "An unexpected error occurred", "حدث خطأ غير متوقع");
        }
    }

    public async Task<bool> CheckNationalIdExists(string nationalId)
    {
        using var connection = await _db.GetConnectionAsync();
        var command = connection.CreateCommand();
        command.CommandText = "SELECT national_id FROM Customers WHERE national_id = @nationalId";
        command.Parameters.AddWithValue("@nationalId", nationalId);
        
        using var reader = await command.ExecuteReaderAsync();
        return await reader.ReadAsync();
    }

    public async Task<(bool success, string message)> RegisterUser(UserRegistrationRequest request)
    {
        // Ensure we're using Riyadh timezone for all timestamps
        var riyadhTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Asia/Riyadh");
        var currentTime = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, riyadhTimeZone);

        using var connection = await _db.CreateConnectionAsync();
        await connection.OpenAsync();

        using var transaction = await connection.BeginTransactionAsync();
        try
        {
            // Check if user already exists
            var command = connection.CreateCommand();
            command.Transaction = transaction;
            command.CommandText = "SELECT national_id FROM Customers WHERE national_id = @nationalId";
            command.Parameters.AddWithValue("@nationalId", request.NationalId);
            
            using (var reader = await command.ExecuteReaderAsync())
            {
                if (await reader.ReadAsync())
                {
                    throw new Exception("This ID already registered");
                }
            }

            // Insert customer
            command = connection.CreateCommand();
            command.Transaction = transaction;
            command.CommandText = @"
                INSERT INTO Customers (
                    national_id, 
                    first_name_en, second_name_en, third_name_en, family_name_en,
                    first_name_ar, second_name_ar, third_name_ar, family_name_ar,
                    date_of_birth, id_expiry_date, email, phone,
                    building_no, street, district, city, zipcode, add_no,
                    iban, dependents, salary_dakhli, salary_customer,
                    los, sector, employer, password,
                    registration_date, consent, consent_date,
                    nafath_status, nafath_timestamp
                ) VALUES (
                    @nationalId, 
                    @firstNameEn, @secondNameEn, @thirdNameEn, @familyNameEn,
                    @firstNameAr, @secondNameAr, @thirdNameAr, @familyNameAr,
                    @dateOfBirth, @idExpiryDate, @email, @phone,
                    @buildingNo, @street, @district, @city, @zipcode, @addNo,
                    @iban, @dependents, @salaryDakhli, @salaryCustomer,
                    @los, @sector, @employer, @password,
                    @registrationDate, @consent, @consentDate,
                    @nafathStatus, @nafathTimestamp
                )";

            command.Parameters.AddWithValue("@nationalId", request.NationalId);
            command.Parameters.Add("@firstNameEn", MySqlDbType.VarChar).Value = (object?)request.FirstNameEn ?? DBNull.Value;
            command.Parameters.Add("@secondNameEn", MySqlDbType.VarChar).Value = (object?)request.SecondNameEn ?? DBNull.Value;
            command.Parameters.Add("@thirdNameEn", MySqlDbType.VarChar).Value = (object?)request.ThirdNameEn ?? DBNull.Value;
            command.Parameters.Add("@familyNameEn", MySqlDbType.VarChar).Value = (object?)request.FamilyNameEn ?? DBNull.Value;
            command.Parameters.Add("@firstNameAr", MySqlDbType.VarChar).Value = (object?)request.FirstNameAr ?? DBNull.Value;
            command.Parameters.Add("@secondNameAr", MySqlDbType.VarChar).Value = (object?)request.SecondNameAr ?? DBNull.Value;
            command.Parameters.Add("@thirdNameAr", MySqlDbType.VarChar).Value = (object?)request.ThirdNameAr ?? DBNull.Value;
            command.Parameters.Add("@familyNameAr", MySqlDbType.VarChar).Value = (object?)request.FamilyNameAr ?? DBNull.Value;
            command.Parameters.Add("@dateOfBirth", MySqlDbType.Date).Value = (object?)request.DateOfBirth ?? DBNull.Value;
            command.Parameters.Add("@idExpiryDate", MySqlDbType.Date).Value = (object?)request.IdExpiryDate ?? DBNull.Value;
            command.Parameters.Add("@email", MySqlDbType.VarChar).Value = (object?)request.Email ?? DBNull.Value;
            command.Parameters.Add("@phone", MySqlDbType.VarChar).Value = (object?)request.Phone ?? DBNull.Value;
            command.Parameters.Add("@buildingNo", MySqlDbType.VarChar).Value = (object?)request.BuildingNo ?? DBNull.Value;
            command.Parameters.Add("@street", MySqlDbType.VarChar).Value = (object?)request.Street ?? DBNull.Value;
            command.Parameters.Add("@district", MySqlDbType.VarChar).Value = (object?)request.District ?? DBNull.Value;
            command.Parameters.Add("@city", MySqlDbType.VarChar).Value = (object?)request.City ?? DBNull.Value;
            command.Parameters.Add("@zipcode", MySqlDbType.VarChar).Value = (object?)request.Zipcode ?? DBNull.Value;
            command.Parameters.Add("@addNo", MySqlDbType.VarChar).Value = (object?)request.AddNo ?? DBNull.Value;
            command.Parameters.Add("@iban", MySqlDbType.VarChar).Value = (object?)request.Iban ?? DBNull.Value;
            command.Parameters.Add("@dependents", MySqlDbType.Int32).Value = (object?)request.Dependents ?? DBNull.Value;
            command.Parameters.Add("@salaryDakhli", MySqlDbType.Decimal).Value = (object?)request.SalaryDakhli ?? DBNull.Value;
            command.Parameters.Add("@salaryCustomer", MySqlDbType.Decimal).Value = (object?)request.SalaryCustomer ?? DBNull.Value;
            command.Parameters.Add("@los", MySqlDbType.VarChar).Value = (object?)request.Los ?? DBNull.Value;
            command.Parameters.Add("@sector", MySqlDbType.VarChar).Value = (object?)request.Sector ?? DBNull.Value;
            command.Parameters.Add("@employer", MySqlDbType.VarChar).Value = (object?)request.Employer ?? DBNull.Value;
            command.Parameters.Add("@password", MySqlDbType.VarChar).Value = request.Password != null ? BCrypt.Net.BCrypt.HashPassword(request.Password) : DBNull.Value;
            command.Parameters.Add("@registrationDate", MySqlDbType.DateTime).Value = currentTime;
            command.Parameters.Add("@consent", MySqlDbType.Bit).Value = request.Consent;
            command.Parameters.Add("@consentDate", MySqlDbType.DateTime).Value = (object?)request.ConsentDate ?? DBNull.Value;
            command.Parameters.Add("@nafathStatus", MySqlDbType.VarChar).Value = (object?)request.NafathStatus ?? DBNull.Value;
            command.Parameters.Add("@nafathTimestamp", MySqlDbType.DateTime).Value = (object?)request.NafathTimestamp ?? DBNull.Value;

            await command.ExecuteNonQueryAsync();

            // Handle device registration if provided
            if (request.DeviceInfo != null)
            {
                // Disable existing devices
                command = connection.CreateCommand();
                command.Transaction = transaction;
                command.CommandText = "UPDATE customer_devices SET status = 'disabled' WHERE national_id = @nationalId AND deviceId = @deviceId";
                command.Parameters.Clear();
                command.Parameters.AddWithValue("@nationalId", request.NationalId);
                command.Parameters.AddWithValue("@deviceId", request.DeviceInfo.DeviceId);
                await command.ExecuteNonQueryAsync();

                // Register new device
                command = connection.CreateCommand();
                command.Transaction = transaction;
                command.CommandText = @"
                    INSERT INTO customer_devices (
                        national_id, deviceId, platform, model, manufacturer,
                        biometric_enabled, status, created_at
                    ) VALUES (
                        @nationalId, @deviceId, @platform, @model, @manufacturer,
                        @biometricEnabled, 'active', @createdAt
                    )";
                command.Parameters.Clear();
                command.Parameters.Add("@nationalId", MySqlDbType.VarChar).Value = request.NationalId;
                command.Parameters.Add("@deviceId", MySqlDbType.VarChar).Value = request.DeviceInfo.DeviceId;
                command.Parameters.Add("@platform", MySqlDbType.VarChar).Value = request.DeviceInfo.Platform;
                command.Parameters.Add("@model", MySqlDbType.VarChar).Value = request.DeviceInfo.Model;
                command.Parameters.Add("@manufacturer", MySqlDbType.VarChar).Value = request.DeviceInfo.Manufacturer;
                command.Parameters.Add("@biometricEnabled", MySqlDbType.Bit).Value = 1;
                command.Parameters.Add("@createdAt", MySqlDbType.DateTime).Value = currentTime;
                await command.ExecuteNonQueryAsync();

                // Log device registration
                var httpContext = _httpContextAccessor.HttpContext;
                command = connection.CreateCommand();
                command.Transaction = transaction;
                command.CommandText = @"
                    INSERT INTO auth_logs (
                        national_id, deviceId, auth_type, status, ip_address, user_agent, created_at
                    ) VALUES (
                        @nationalId, @deviceId, 'device_registration', 'success', @ipAddress, @userAgent, @createdAt
                    )";
                command.Parameters.Clear();
                command.Parameters.AddWithValue("@nationalId", request.NationalId);
                command.Parameters.AddWithValue("@deviceId", request.DeviceInfo.DeviceId);
                command.Parameters.AddWithValue("@ipAddress", httpContext?.Connection.RemoteIpAddress?.ToString() ?? "unknown");
                command.Parameters.AddWithValue("@userAgent", httpContext?.Request.Headers["User-Agent"].ToString() ?? "unknown");
                command.Parameters.AddWithValue("@createdAt", currentTime);
                await command.ExecuteNonQueryAsync();

                // Log the registration in audit_logs
                await LogAuditAsync(connection, request.NationalId, "User Registration", 
                    $"User registered successfully with device: {request.DeviceInfo.DeviceId}");
            }
            else
            {
                // Log the registration without device info
                await LogAuditAsync(connection, request.NationalId, "User Registration", 
                    "User registered successfully without device info");
            }

            await transaction.CommitAsync();
            return (true, "Registration successful");
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            _logger.LogError(ex, "Registration failed for national ID: {NationalId}", request.NationalId);
            return (false, ex.Message);
        }
    }

    public GovData GetGovernmentData(UserRegistrationRequest request)
    {
        return new GovData
        {
            NationalId = request.NationalId,
            FirstNameEn = request.FirstNameEn,
            FamilyNameEn = request.FamilyNameEn,
            FirstNameAr = request.FirstNameAr,
            FamilyNameAr = request.FamilyNameAr,
            DateOfBirth = request.DateOfBirth
        };
    }

    public async Task<DeviceRegistrationResponse> RegisterDevice(DeviceRegistrationRequest request, string ipAddress, string userAgent)
    {
        // Ensure we're using Riyadh timezone for all timestamps
        var riyadhTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Asia/Riyadh");
        var currentTime = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, riyadhTimeZone);

        using var connection = await _db.CreateConnectionAsync();
        using var transaction = await connection.BeginTransactionAsync();

        try
        {
            // Verify customer exists
            var customerExists = await connection.QueryFirstOrDefaultAsync<int>(
                "SELECT id FROM Customers WHERE national_id = @NationalId",
                new { request.NationalId },
                transaction
            );

            if (customerExists == 0)
            {
                throw new Exception("Customer not found");
            }

            // If deviceId is provided, handle device registration
            if (!string.IsNullOrEmpty(request.DeviceId))
            {
                // First, disable ALL existing devices for this user
                await connection.ExecuteAsync(
                    "UPDATE customer_devices SET status = 'disabled' WHERE national_id = @NationalId",
                    new { request.NationalId },
                    transaction
                );

                // Register new device
                var deviceParams = new
                {
                    request.NationalId,
                    request.DeviceId,
                    request.Platform,
                    request.Model,
                    request.Manufacturer,
                    BiometricEnabled = 1,
                    Status = "active",
                    CreatedAt = currentTime  // Now using Riyadh time
                };

                var deviceId = await connection.QuerySingleAsync<int>(
                    @"INSERT INTO customer_devices (
                        national_id, 
                        deviceId, 
                        platform, 
                        model, 
                        manufacturer, 
                        biometric_enabled, 
                        status,
                        created_at
                    ) VALUES (
                        @NationalId, 
                        @DeviceId, 
                        @Platform, 
                        @Model, 
                        @Manufacturer, 
                        @BiometricEnabled, 
                        @Status,
                        @CreatedAt
                    ); SELECT LAST_INSERT_ID();",
                    deviceParams,
                    transaction
                );

                // Log successful device registration
                await LogAuthEvent(
                    connection,
                    request.NationalId,
                    request.DeviceId,
                    "device_registration",
                    "success",
                    ipAddress,
                    userAgent,
                    null,
                    transaction
                );

                await transaction.CommitAsync();
                return DeviceRegistrationResponse.Success(
                    "Device registered successfully",
                    deviceId
                );
            }

            await transaction.CommitAsync();
            return DeviceRegistrationResponse.Success("Customer verified successfully");
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();

            // Log failed attempt if deviceId was provided
            if (!string.IsNullOrEmpty(request.DeviceId))
            {
                await LogAuthEvent(
                    connection,
                    request.NationalId,
                    request.DeviceId,
                    "device_registration",
                    "failed",
                    ipAddress,
                    userAgent,
                    ex.Message
                );
            }

            return DeviceRegistrationResponse.Error(ex.Message);
        }
    }
} 