using System;
using System.Threading.Tasks;
using MySql.Data.MySqlClient;
using NayifatAPI.Models;
using System.Data;

namespace NayifatAPI.Services
{
    public interface IGovService
    {
        Task<GovServiceResponse> GetGovernmentData(string nationalId);
    }

    public class GovService : IGovService
    {
        private readonly DatabaseService _db;
        private readonly AuditService _audit;

        public GovService(DatabaseService db, AuditService audit)
        {
            _db = db;
            _audit = audit;
        }

        public async Task<GovServiceResponse> GetGovernmentData(string nationalId)
        {
            try
            {
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

                    await _audit.LogAsync(nationalId, "Get Government Data Success", "Record retrieved successfully");

                    return new GovServiceResponse
                    {
                        Status = "success",
                        Data = data
                    };
                }

                await _audit.LogAsync(nationalId, "Get Government Data Failed", "Record not found");
                return new GovServiceResponse
                {
                    Status = "error",
                    Message = "Record not found for the provided national ID",
                    NationalId = nationalId
                };
            }
            catch (Exception ex)
            {
                await _audit.LogAsync(null, "Get Government Data Failed", "An unexpected error occurred");
                throw new Exception("Failed to get government data", ex);
            }
        }
    }
} 