using Microsoft.AspNetCore.Mvc;
using NayifatAPI.Models;
using NayifatAPI.Services;

namespace NayifatAPI.Controllers;

[ApiController]
[Route("api")]
public class NotificationController : ControllerBase
{
    private readonly NotificationService _notificationService;
    private readonly ILogger<NotificationController> _logger;

    public NotificationController(
        NotificationService notificationService,
        ILogger<NotificationController> logger)
    {
        _notificationService = notificationService;
        _logger = logger;
    }

    [HttpPost("get_notifications.php")]
    public async Task<IActionResult> GetNotifications([FromBody] GetNotificationsRequest request)
    {
        try
        {
            var response = await _notificationService.GetNotifications(request);
            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting notifications");
            return Ok(new GetNotificationsResponse(ex.Message));
        }
    }

    [HttpPost("send_notification.php")]
    public async Task<IActionResult> SendNotification([FromBody] SendNotificationRequest request)
    {
        try
        {
            var response = await _notificationService.SendNotification(request);
            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending notification");
            return Ok(new SendNotificationResponse(ex.Message));
        }
    }
} 