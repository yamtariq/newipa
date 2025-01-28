using System.Diagnostics;
using NayifatAPI.Services;

namespace NayifatAPI.Middleware;

public class MetricsMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IMetricsService _metrics;
    private readonly ILogger<MetricsMiddleware> _logger;

    public MetricsMiddleware(
        RequestDelegate next,
        IMetricsService metrics,
        ILogger<MetricsMiddleware> logger)
    {
        _next = next;
        _metrics = metrics;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var path = context.Request.Path.Value?.ToLowerInvariant() ?? "";
        var method = context.Request.Method;
        var stopwatch = Stopwatch.StartNew();

        try
        {
            await _next(context);
        }
        finally
        {
            stopwatch.Stop();
            var statusCode = context.Response.StatusCode;
            var duration = stopwatch.Elapsed;

            // Record request duration
            _metrics.RecordDuration($"http_{method}_{path}", duration);

            // Record status code metrics
            _metrics.IncrementCounter($"status_{statusCode}");

            // Record endpoint-specific metrics
            if (path.Contains("auth"))
            {
                _metrics.IncrementCounter("auth_requests");
                if (statusCode >= 400)
                {
                    _metrics.IncrementCounter("auth_failures");
                }
            }
            else if (path.Contains("notification"))
            {
                _metrics.IncrementCounter("notification_requests");
            }

            // Log detailed request information
            _logger.LogInformation(
                "Request {Method} {Path} completed with status {StatusCode} in {Duration}ms",
                method,
                path,
                statusCode,
                duration.TotalMilliseconds
            );

            // Log slow requests
            if (duration.TotalMilliseconds > 1000)
            {
                _logger.LogWarning(
                    "Slow request detected: {Method} {Path} took {Duration}ms",
                    method,
                    path,
                    duration.TotalMilliseconds
                );
            }
        }
    }
} 