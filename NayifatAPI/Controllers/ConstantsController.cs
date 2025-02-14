using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NayifatAPI.Data;
using NayifatAPI.Models;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ConstantsController : ApiBaseController
    {
        private readonly ILogger<ConstantsController> _logger;

        public ConstantsController(
            ApplicationDbContext context,
            ILogger<ConstantsController> logger,
            IConfiguration configuration) : base(context, configuration)
        {
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllConstants()
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                var constants = await _context.Constants
                    .Select(c => new GetConstantsResponse
                    {
                        Name = c.ConstantName,
                        Value = c.ConstantValue,
                        ValueAr = c.ConstantValueAr,
                        Description = c.Description,
                        LastUpdated = c.LastUpdated
                    })
                    .ToListAsync();

                return Success(constants);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching constants");
                return HandleException(ex);
            }
        }

        [HttpGet("{name}")]
        public async Task<IActionResult> GetConstantByName(string name)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                var constant = await _context.Constants
                    .Where(c => c.ConstantName == name)
                    .Select(c => new GetConstantsResponse
                    {
                        Name = c.ConstantName,
                        Value = c.ConstantValue,
                        ValueAr = c.ConstantValueAr,
                        Description = c.Description,
                        LastUpdated = c.LastUpdated
                    })
                    .FirstOrDefaultAsync();

                if (constant == null)
                {
                    return Error("Constant not found", 404);
                }

                return Success(constant);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching constant with name: {Name}", name);
                return HandleException(ex);
            }
        }

        [HttpPost]
        public async Task<IActionResult> CreateConstant([FromBody] CreateConstantRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                // Check if constant with same name already exists
                var existingConstant = await _context.Constants
                    .FirstOrDefaultAsync(c => c.ConstantName == request.Name);

                if (existingConstant != null)
                {
                    return Error("A constant with this name already exists", 400);
                }

                var constant = new Constant
                {
                    ConstantName = request.Name,
                    ConstantValue = request.Value,
                    ConstantValueAr = request.ValueAr,
                    Description = request.Description,
                    LastUpdated = DateTime.UtcNow
                };

                _context.Constants.Add(constant);
                await _context.SaveChangesAsync();

                return Success(new GetConstantsResponse
                {
                    Name = constant.ConstantName,
                    Value = constant.ConstantValue,
                    ValueAr = constant.ConstantValueAr,
                    Description = constant.Description,
                    LastUpdated = constant.LastUpdated
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating constant: {Name}", request.Name);
                return HandleException(ex);
            }
        }

        [HttpPut("{name}")]
        public async Task<IActionResult> UpdateConstant(string name, [FromBody] UpdateConstantRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                var constant = await _context.Constants
                    .FirstOrDefaultAsync(c => c.ConstantName == name);

                if (constant == null)
                {
                    return Error("Constant not found", 404);
                }

                constant.ConstantValue = request.Value;
                constant.ConstantValueAr = request.ValueAr;
                constant.Description = request.Description;
                constant.LastUpdated = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Success(new GetConstantsResponse
                {
                    Name = constant.ConstantName,
                    Value = constant.ConstantValue,
                    ValueAr = constant.ConstantValueAr,
                    Description = constant.Description,
                    LastUpdated = constant.LastUpdated
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating constant: {Name}", name);
                return HandleException(ex);
            }
        }
    }
} 