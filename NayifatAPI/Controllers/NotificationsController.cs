using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NayifatAPI.Data;
using NayifatAPI.Models;

namespace NayifatAPI.Controllers
{
    public class NotificationsController : ApiBaseController
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<NotificationsController> _logger;

        public NotificationsController(ApplicationDbContext context, ILogger<NotificationsController> logger)
        {
            _context = context;
            _logger = logger;
        }

        [HttpPost("get_notifications.php")]
        public async Task<IActionResult> GetNotifications([FromBody] GetNotificationsRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                var query = _context.UserNotifications
                    .Where(n => n.NationalId == request.NationalId);

                if (request.UnreadOnly)
                {
                    query = query.Where(n => !n.IsRead);
                }

                var notifications = await query
                    .OrderByDescending(n => n.CreatedAt)
                    .Take(50)
                    .Select(n => new
                    {
                        id = n.Id,
                        title = n.Title,
                        message = n.Message,
                        data = n.Data,
                        is_read = n.IsRead,
                        created_at = n.CreatedAt.ToString("yyyy-MM-dd HH:mm:ss"),
                        read_at = n.ReadAt?.ToString("yyyy-MM-dd HH:mm:ss"),
                        notification_type = n.NotificationType
                    })
                    .ToListAsync();

                // Mark notifications as read if requested
                if (request.MarkAsRead && notifications.Any())
                {
                    var notificationIds = notifications
                        .Where(n => !n.is_read)
                        .Select(n => n.id)
                        .ToList();

                    if (notificationIds.Any())
                    {
                        await _context.UserNotifications
                            .Where(n => notificationIds.Contains(n.Id))
                            .ForEachAsync(n =>
                            {
                                n.IsRead = true;
                                n.ReadAt = DateTime.UtcNow;
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

        [HttpPost("send_notification.php")]
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
                    NationalId = request.NationalId,
                    Title = request.Title,
                    Message = request.Message,
                    Data = request.Data ?? "{}",
                    NotificationType = request.NotificationType,
                    CreatedAt = DateTime.UtcNow,
                    IsRead = false
                };

                _context.UserNotifications.Add(notification);

                // If this is a push notification, get the customer's devices
                if (request.SendPush)
                {
                    var devices = await _context.CustomerDevices
                        .Where(d => d.NationalId == request.NationalId && d.IsActive)
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
                        .CountAsync(d => d.NationalId == request.NationalId && d.IsActive) : 0
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
        public string NationalId { get; set; }
        public bool UnreadOnly { get; set; }
        public bool MarkAsRead { get; set; }
    }

    public class SendNotificationRequest
    {
        public string NationalId { get; set; }
        public string Title { get; set; }
        public string Message { get; set; }
        public string Data { get; set; }
        public string NotificationType { get; set; }
        public bool SendPush { get; set; }
    }
} 