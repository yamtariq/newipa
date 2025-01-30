using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NayifatAPI.Data;
using NayifatAPI.Models;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class NotificationsController : ApiBaseController
    {
        private readonly ILogger<NotificationsController> _logger;

        public NotificationsController(
            ApplicationDbContext context,
            ILogger<NotificationsController> logger,
            IConfiguration configuration) : base(context, configuration)
        {
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetNotifications([FromQuery] GetNotificationsRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                IQueryable<UserNotification> query = _context.UserNotifications
                    .Where(n => n.NationalId == request.NationalId);

                if (!request.IncludeRead)
                {
                    query = query.Where(n => !n.IsRead);
                }

                // Apply ordering after all filters
                query = query.OrderByDescending(n => n.CreatedAt);

                var notifications = await query
                    .Skip((request.Page - 1) * request.PageSize)
                    .Take(request.PageSize)
                    .Select(n => new
                    {
                        notification_id = n.Id,
                        title = n.Title,
                        message = n.Message,
                        data = n.Data,
                        is_read = n.IsRead,
                        created_at = n.CreatedAt.ToString("yyyy-MM-dd HH:mm:ss"),
                        read_at = n.ReadAt.HasValue ? n.ReadAt.Value.ToString("yyyy-MM-dd HH:mm:ss") : null,
                        notification_type = n.NotificationType,
                        last_updated = n.LastUpdated.ToString("yyyy-MM-dd HH:mm:ss")
                    })
                    .ToListAsync();

                // Mark notifications as read if requested
                if (request.MarkAsRead && notifications.Any())
                {
                    var notificationIds = notifications
                        .Where(n => !n.is_read)
                        .Select(n => n.notification_id)
                        .ToList();

                    if (notificationIds.Any())
                    {
                        await _context.UserNotifications
                            .Where(n => notificationIds.Contains(n.Id))
                            .ForEachAsync(n =>
                            {
                                n.IsRead = true;
                                n.ReadAt = DateTime.UtcNow;
                                n.LastUpdated = DateTime.UtcNow;
                            });

                        await _context.SaveChangesAsync();
                    }
                }

                return Success(new { notifications });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching notifications for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }

        [HttpPost]
        public async Task<IActionResult> SendNotification([FromBody] SendNotificationRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                var customer = await _context.Customers.FindAsync(request.NationalId);
                if (customer == null)
                {
                    return Error("Customer not found", 404);
                }

                var notification = new UserNotification
                {
                    NotificationId = Guid.NewGuid().ToString("N"),
                    NationalId = request.NationalId,
                    Title = request.Title,
                    Message = request.Message,
                    Data = request.Data ?? "{}",
                    NotificationType = request.NotificationType,
                    CreatedAt = DateTime.UtcNow,
                    LastUpdated = DateTime.UtcNow,
                    IsRead = false
                };

                _context.UserNotifications.Add(notification);

                // If this is a push notification, get the customer's devices
                if (request.SendPush)
                {
                    var devices = await _context.CustomerDevices
                        .Where(d => d.NationalId == request.NationalId && d.Status == "active")
                        .ToListAsync();

                    foreach (var device in devices)
                    {
                        // TODO: Implement push notification sending logic
                        _logger.LogInformation("Push notification would be sent to device {DeviceId}", device.DeviceId);
                    }
                }

                await _context.SaveChangesAsync();

                return Success(new
                {
                    notification_id = notification.Id,
                    devices_notified = request.SendPush ? await _context.CustomerDevices
                        .CountAsync(d => d.NationalId == request.NationalId && d.Status == "active") : 0
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending notification to National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }
    }

    public class GetNotificationsRequest
    {
        public required string NationalId { get; set; }
        public bool UnreadOnly { get; set; }
        public bool MarkAsRead { get; set; }
        public bool IncludeRead { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
    }

    public class SendNotificationRequest
    {
        public required string NationalId { get; set; }
        public required string Title { get; set; }
        public required string Message { get; set; }
        public string? Data { get; set; }
        public required string NotificationType { get; set; }
        public bool SendPush { get; set; }
    }
} 