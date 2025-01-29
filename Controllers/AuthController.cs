using Microsoft.AspNetCore.Mvc;
using NayifatAPI.Models.Auth;
using NayifatAPI.Services;
using System.Threading.Tasks;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/auth")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;
        private readonly ILogger<AuthController> _logger;

        public AuthController(IAuthService authService, ILogger<AuthController> logger)
        {
            _authService = authService;
            _logger = logger;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            try
            {
                var result = await _authService.RegisterUser(request);
                return Ok(new { success = true, data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during registration for user {NationalId}", request.NationalId);
                return StatusCode(500, new { success = false, message = "An error occurred during registration" });
            }
        }

        [HttpPost("user-details")]
        public async Task<IActionResult> SetUserDetails([FromBody] UserDetailsRequest request)
        {
            try
            {
                var result = await _authService.SetUserDetails(request);
                return Ok(new { success = true, data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error setting user details for {NationalId}", request.NationalId);
                return StatusCode(500, new { success = false, message = "An error occurred while setting user details" });
            }
        }

        [HttpPost("setup-mpin")]
        public async Task<IActionResult> SetupMpin([FromBody] MpinSetupRequest request)
        {
            try
            {
                var result = await _authService.SetupMpin(request);
                return Ok(new { success = true, data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error setting up MPIN for user {NationalId}", request.NationalId);
                return StatusCode(500, new { success = false, message = "An error occurred while setting up MPIN" });
            }
        }

        [HttpPost("biometrics")]
        public async Task<IActionResult> SetupBiometrics([FromBody] BiometricsRequest request)
        {
            try
            {
                var result = await _authService.SetupBiometrics(request);
                return Ok(new { success = true, data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error setting up biometrics for user {NationalId}", request.NationalId);
                return StatusCode(500, new { success = false, message = "An error occurred while setting up biometrics" });
            }
        }

        [HttpPost("signin")]
        public async Task<IActionResult> SignIn([FromBody] SignInRequest request)
        {
            try
            {
                var result = await _authService.SignIn(request);
                return Ok(new { success = true, data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during sign in for user {NationalId}", request.NationalId);
                return StatusCode(500, new { success = false, message = "An error occurred during sign in" });
            }
        }

        [HttpPost("otp/verify")]
        public async Task<IActionResult> VerifyOTP([FromBody] OtpRequest request)
        {
            try
            {
                var result = await _authService.VerifyOTP(request);
                return Ok(new { success = true, data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error verifying OTP for user {NationalId}", request.NationalId);
                return StatusCode(500, new { success = false, message = "An error occurred while verifying OTP" });
            }
        }

        [HttpPost("otp/resend")]
        public async Task<IActionResult> ResendOTP([FromBody] OtpRequest request)
        {
            try
            {
                var result = await _authService.ResendOTP(request);
                return Ok(new { success = true, data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error resending OTP for user {NationalId}", request.NationalId);
                return StatusCode(500, new { success = false, message = "An error occurred while resending OTP" });
            }
        }
    }
} 