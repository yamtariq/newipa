using MySql.Data.MySqlClient;
using NayifatAPI.Models;

namespace NayifatAPI.Services
{
    public interface IUserService
    {
        Task<UserResponse> GetUserByNationalIdAsync(string nationalId);
    }

    public class UserService : IUserService
    {
        private readonly DatabaseService _databaseService;
        private readonly IAuditService _auditService;
        private readonly ILogger<UserService> _logger;

        public UserService(
            DatabaseService databaseService,
            IAuditService auditService,
            ILogger<UserService> logger)
        {
            _databaseService = databaseService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<UserResponse> GetUserByNationalIdAsync(string nationalId)
        {
            try
            {
                using var connection = await _databaseService.GetConnectionAsync();
                using var command = new MySqlCommand(
                    "SELECT * FROM Customers WHERE national_id = @nationalId",
                    connection);
                
                command.Parameters.AddWithValue("@nationalId", nationalId);

                using var reader = await command.ExecuteReaderAsync();
                
                if (await reader.ReadAsync())
                {
                    var userId = reader.GetInt32("id");
                    var response = new UserResponse
                    {
                        Success = true,
                        Data = new CustomerData
                        {
                            Id = userId,
                            NationalId = reader.GetString("national_id"),
                            FirstName = reader.GetString("first_name"),
                            LastName = reader.GetString("last_name"),
                            Email = reader.GetString("email"),
                            Phone = reader.GetString("phone"),
                            DateOfBirth = reader.IsDBNull("date_of_birth") ? null : reader.GetDateTime("date_of_birth"),
                            Gender = reader.GetString("gender"),
                            Address = reader.GetString("address"),
                            City = reader.GetString("city"),
                            Status = reader.GetString("status"),
                            CreatedAt = reader.GetDateTime("created_at"),
                            UpdatedAt = reader.GetDateTime("updated_at"),
                            LastLogin = reader.IsDBNull("last_login") ? null : reader.GetDateTime("last_login"),
                            IsActive = reader.GetBoolean("is_active")
                        }
                    };

                    await _auditService.LogAuditAsync(userId, "User Data Retrieved", 
                        $"User data retrieved for national_id: {nationalId}");

                    return response;
                }

                await _auditService.LogAuditAsync(0, "User Data Retrieval Failed", 
                    $"User not found for national_id: {nationalId}");

                return new UserResponse
                {
                    Success = false,
                    Message = "User not found"
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving user data for national ID: {NationalId}", nationalId);
                
                await _auditService.LogAuditAsync(0, "User Data Retrieval Error", 
                    $"Error retrieving data for national_id: {nationalId}. Error: {ex.Message}");

                return new UserResponse
                {
                    Success = false,
                    Message = $"Error: {ex.Message}"
                };
            }
        }
    }
} 