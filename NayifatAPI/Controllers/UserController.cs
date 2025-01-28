using Microsoft.AspNetCore.Mvc;
using NayifatAPI.Models;
using NayifatAPI.Services;

namespace NayifatAPI.Controllers
{
    [ApiController]
    public class UserController : ControllerBase
    {
        private readonly IUserService _userService;

        public UserController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpGet("/get_user")]
        public async Task<ActionResult<UserResponse>> GetUser([FromQuery] string nationalId)
        {
            if (string.IsNullOrEmpty(nationalId))
            {
                return Ok(new UserResponse
                {
                    Success = false,
                    Message = "nationalId parameter is required"
                });
            }

            var response = await _userService.GetUserByNationalIdAsync(nationalId);
            return Ok(response);
        }
    }
} 