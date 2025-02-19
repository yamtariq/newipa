using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NayifatAPI.Data;
using NayifatAPI.Models;

namespace NayifatAPI.Controllers
{
    public class ConfigController : ApiBaseController
    {
        private readonly ILogger<ConfigController> _logger;

        public ConfigController(
            ApplicationDbContext context,
            ILogger<ConfigController> logger,
            IConfiguration configuration) : base(context, configuration)
        {
            _logger = logger;
        }

        [HttpGet("page/{page}")]
        public async Task<IActionResult> GetPageConfig(string page)
        {
            try
            {
                var configs = await _context.MasterConfigs
                    .Where(c => c.Page == page)
                    .ToDictionaryAsync(c => c.KeyName, c => c.Value);

                return Success(configs);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching config for page: {Page}", page);
                return HandleException(ex);
            }
        }

        [HttpGet("key/{page}/{keyName}")]
        public async Task<IActionResult> GetConfigValue(string page, string keyName)
        {
            try
            {
                var config = await _context.MasterConfigs
                    .FirstOrDefaultAsync(c => c.Page == page && c.KeyName == keyName);

                if (config == null)
                {
                    return Failure("Configuration not found", 404);
                }

                return Success(new { value = config.Value });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching config value for page: {Page}, key: {Key}", page, keyName);
                return HandleException(ex);
            }
        }

        [HttpPost]
        public async Task<IActionResult> SetConfig([FromBody] SetConfigRequest request)
        {
            try
            {
                var config = await _context.MasterConfigs
                    .FirstOrDefaultAsync(c => c.Page == request.Page && c.KeyName == request.KeyName);

                if (config == null)
                {
                    config = new MasterConfig
                    {
                        Page = request.Page,
                        KeyName = request.KeyName,
                        Value = request.Value,
                        LastUpdated = DateTime.UtcNow
                    };
                    _context.MasterConfigs.Add(config);
                }
                else
                {
                    config.Value = request.Value;
                    config.LastUpdated = DateTime.UtcNow;
                }

                await _context.SaveChangesAsync();

                return Success(config);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error setting config for page: {Page}, key: {Key}", request.Page, request.KeyName);
                return HandleException(ex);
            }
        }

        [HttpDelete("{page}/{keyName}")]
        public async Task<IActionResult> DeleteConfig(string page, string keyName)
        {
            try
            {
                var config = await _context.MasterConfigs
                    .FirstOrDefaultAsync(c => c.Page == page && c.KeyName == keyName);

                if (config == null)
                {
                    return Failure("Configuration not found", 404);
                }

                _context.MasterConfigs.Remove(config);
                await _context.SaveChangesAsync();

                return Success();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting config for page: {Page}, key: {Key}", page, keyName);
                return HandleException(ex);
            }
        }
    }

    public class SetConfigRequest
    {
        public required string Page { get; set; }
        public required string KeyName { get; set; }
        public required string Value { get; set; }
    }
} 