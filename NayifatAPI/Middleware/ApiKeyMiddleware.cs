using Microsoft.AspNetCore.Http;

namespace NayifatAPI.Middleware;

public class ApiKeyMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IConfiguration _configuration;

    public ApiKeyMiddleware(RequestDelegate next, IConfiguration configuration)
    {
        _next = next;
        _configuration = configuration;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (!context.Request.Headers.TryGetValue("api-key", out var extractedApiKey))
        {
            context.Response.StatusCode = 401;
            await context.Response.WriteAsJsonAsync(new { 
                status = "error",
                code = "MISSING_API_KEY",
                message = "API key is missing"
            });
            return;
        }

        var apiKey = _configuration.GetValue<string>("ApiKey") ?? throw new InvalidOperationException("API key not configured");
        if (!apiKey.Equals(extractedApiKey.ToString()))
        {
            context.Response.StatusCode = 401;
            await context.Response.WriteAsJsonAsync(new { 
                status = "error",
                code = "INVALID_API_KEY",
                message = "Invalid API key"
            });
            return;
        }

        await _next(context);
    }
} 