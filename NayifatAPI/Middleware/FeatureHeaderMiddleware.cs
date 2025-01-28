using Microsoft.AspNetCore.Http;

namespace NayifatAPI.Middleware;

public class FeatureHeaderMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<FeatureHeaderMiddleware> _logger;

    public FeatureHeaderMiddleware(RequestDelegate next, ILogger<FeatureHeaderMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var path = context.Request.Path.Value?.ToLower();
        
        // Skip feature header check for certain endpoints if needed
        if (path?.Contains("health") == true)
        {
            await _next(context);
            return;
        }

        if (!context.Request.Headers.TryGetValue("X-Feature", out var feature))
        {
            context.Response.StatusCode = 400;
            await context.Response.WriteAsJsonAsync(new { 
                status = "error",
                code = "MISSING_FEATURE_HEADER",
                message = "X-Feature header is required"
            });
            return;
        }

        var featureValue = feature.ToString().ToLower();
        var isValid = path switch
        {
            var p when p?.Contains("auth") == true => featureValue == "auth",
            var p when p?.Contains("device") == true => featureValue == "device",
            var p when p?.Contains("user") == true => featureValue == "user",
            _ => true
        };

        if (!isValid)
        {
            context.Response.StatusCode = 400;
            await context.Response.WriteAsJsonAsync(new { 
                status = "error",
                code = "INVALID_FEATURE_HEADER",
                message = "Invalid X-Feature header for this endpoint"
            });
            return;
        }

        await _next(context);
    }
} 