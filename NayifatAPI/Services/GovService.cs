using System;
using System.Threading.Tasks;
using MySql.Data.MySqlClient;
using NayifatAPI.Models;
using System.Data;
using System.Text.Json;

namespace NayifatAPI.Services
{
    public interface IGovService
    {
        Task<GovServiceResponse> GetGovernmentData(string nationalId);
    }

    public class GovService : IGovService
    {
        private readonly DatabaseService _db;
        private readonly IAuditService _auditService;
        private readonly ILogger<GovService> _logger;

        public GovService(
            DatabaseService db, 
            IAuditService auditService,
            ILogger<GovService> logger)
        {
            _db = db;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<GovServiceResponse> GetGovernmentData(string nationalId)
        {
            try
            {
                // Get user ID for audit logging
                using var userCmd = _db.CreateCommand("SELECT id FROM Customers WHERE national_id = @nationalId");
                userCmd.Parameters.AddWithValue("@nationalId", nationalId);
                var userId = await userCmd.ExecuteScalarAsync();
                var userIdInt = userId != null ? Convert.ToInt32(userId) : 0;

                using var connection = await _db.CreateConnectionAsync();
                using var command = connection.CreateCommand();
                
                command.CommandText = @"SELECT 
                    national_id,
                    full_name,
                    arabic_name,
                    dob,
                    salary,
                    employment_status,
                    employer_name,
                    employment_date,
                    national_address,
                    updated_at
                FROM GovernmentServices 
                WHERE national_id = @NationalId";

                command.Parameters.AddWithValue("@NationalId", nationalId);

                using var reader = await command.ExecuteReaderAsync();
                
                if (await reader.ReadAsync())
                {
                    var data = new GovServiceData
                    {
                        NationalId = reader.GetString("national_id"),
                        FullName = reader.IsDBNull("full_name") ? null : reader.GetString("full_name"),
                        ArabicName = reader.IsDBNull("arabic_name") ? null : reader.GetString("arabic_name"),
                        Dob = reader.IsDBNull("dob") ? null : reader.GetDateTime("dob"),
                        Salary = reader.IsDBNull("salary") ? null : reader.GetDecimal("salary"),
                        EmploymentStatus = reader.IsDBNull("employment_status") ? null : reader.GetString("employment_status"),
                        EmployerName = reader.IsDBNull("employer_name") ? null : reader.GetString("employer_name"),
                        EmploymentDate = reader.IsDBNull("employment_date") ? null : reader.GetDateTime("employment_date"),
                        NationalAddress = reader.IsDBNull("national_address") ? null : reader.GetString("national_address"),
                        UpdatedAt = reader.IsDBNull("updated_at") ? null : reader.GetDateTime("updated_at")
                    };

                    await _auditService.LogAuditAsync(userIdInt, "Government Data Retrieved", 
                        JsonSerializer.Serialize(new {
                            national_id = nationalId,
                            has_employment = !string.IsNullOrEmpty(data.EmploymentStatus),
                            has_address = !string.IsNullOrEmpty(data.NationalAddress),
                            last_updated = data.UpdatedAt
                        }));

                    return new GovServiceResponse
                    {
                        Status = "success",
                        Data = data
                    };
                }

                await _auditService.LogAuditAsync(userIdInt, "Government Data Not Found", 
                    $"No government data found for national_id: {nationalId}");

                return new GovServiceResponse
                {
                    Status = "error",
                    Message = "Record not found for the provided national ID",
                    NationalId = nationalId
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving government data for national ID: {NationalId}", nationalId);
                
                await _auditService.LogAuditAsync(0, "Government Data Error", 
                    $"Error retrieving government data for national_id: {nationalId}. Error: {ex.Message}");

                throw new Exception("Failed to get government data", ex);
            }
        }
    }
} 