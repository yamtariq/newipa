using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NayifatAPI.Data;
using NayifatAPI.Models;

namespace NayifatAPI.Controllers
{
    public class UserController : ApiBaseController
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<UserController> _logger;

        public UserController(ApplicationDbContext context, ILogger<UserController> logger)
        {
            _context = context;
            _logger = logger;
        }

        [HttpPost("get_user.php")]
        public async Task<IActionResult> GetUser([FromBody] GetUserRequest request)
        {
            if (!ValidateApiKey() || !ValidateFeatureHeader("user"))
            {
                return Error("Invalid headers", 401);
            }

            try
            {
                var customer = await _context.Customers
                    .FirstOrDefaultAsync(c => c.NationalId == request.NationalId);

                if (customer == null)
                {
                    return Error("User not found", 404);
                }

                var devices = await _context.CustomerDevices
                    .Where(d => d.NationalId == request.NationalId && d.IsActive)
                    .Select(d => new
                    {
                        device_id = d.DeviceId,
                        device_name = d.DeviceName,
                        platform = d.Platform,
                        os_version = d.OsVersion,
                        is_biometric_enabled = d.IsBiometricEnabled,
                        registered_at = d.RegisteredAt.ToString("yyyy-MM-dd HH:mm:ss"),
                        last_used_at = d.LastUsedAt?.ToString("yyyy-MM-dd HH:mm:ss")
                    })
                    .ToListAsync();

                return Success(new
                {
                    user = new
                    {
                        national_id = customer.NationalId,
                        name_en = $"{customer.FirstNameEn} {customer.SecondNameEn} {customer.ThirdNameEn} {customer.FamilyNameEn}".Trim(),
                        name_ar = $"{customer.FirstNameAr} {customer.SecondNameAr} {customer.ThirdNameAr} {customer.FamilyNameAr}".Trim(),
                        email = customer.Email,
                        phone = customer.Phone,
                        date_of_birth = customer.DateOfBirth.ToString("yyyy-MM-dd"),
                        id_expiry_date = customer.IdExpiryDate.ToString("yyyy-MM-dd"),
                        building_no = customer.BuildingNo,
                        street = customer.Street,
                        district = customer.District,
                        city = customer.City,
                        zipcode = customer.Zipcode,
                        add_no = customer.AddNo,
                        iban = customer.Iban,
                        dependents = customer.Dependents,
                        salary_dakhli = customer.SalaryDakhli,
                        salary_customer = customer.SalaryCustomer,
                        los = customer.Los,
                        sector = customer.Sector,
                        employer = customer.Employer,
                        registration_date = customer.RegistrationDate.ToString("yyyy-MM-dd HH:mm:ss"),
                        consent = customer.Consent,
                        consent_date = customer.ConsentDate?.ToString("yyyy-MM-dd HH:mm:ss"),
                        nafath_status = customer.NafathStatus,
                        nafath_timestamp = customer.NafathTimestamp?.ToString("yyyy-MM-dd HH:mm:ss")
                    },
                    devices = devices
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user details for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }
    }

    public class GetUserRequest
    {
        public string NationalId { get; set; }
    }
} 