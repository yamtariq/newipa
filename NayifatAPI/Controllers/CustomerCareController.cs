using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using Dapper;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CustomerCareController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly string _connectionString;

        public CustomerCareController(IConfiguration configuration)
        {
            _configuration = configuration;
            _connectionString = _configuration.GetConnectionString("DefaultConnection");
        }

        [HttpPost("Submit")]
        public async Task<IActionResult> Submit([FromBody] CustomerCareRequest request)
        {
            try
            {
                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    var sql = @"
                        INSERT INTO CustomerCare (
                            NationalID, Phone, CustomerName, 
                            Subject, SubSubject, Complaint
                        ) 
                        VALUES (
                            @NationalID, @Phone, @CustomerName, 
                            @Subject, @SubSubject, @Complaint
                        );
                        SELECT SCOPE_IDENTITY();";

                    var complaintId = await connection.ExecuteScalarAsync<int>(sql, new {
                        NationalID = request.NationalId,
                        Phone = request.Phone,
                        CustomerName = request.CustomerName,
                        Subject = request.Subject,
                        SubSubject = request.SubSubject,
                        Complaint = request.Complaint
                    });

                    return Ok(new {
                        Success = true,
                        ComplaintNumber = complaintId.ToString("CC000000"),
                        Message = "Complaint submitted successfully"
                    });
                }
            }
            catch (Exception ex)
            {
                return BadRequest(new {
                    Success = false,
                    Message = "Failed to submit complaint"
                });
            }
        }
    }
} 