namespace NayifatAPI.Middleware;

public class CacheControlMiddleware
{
    private readonly RequestDelegate _next;

    public CacheControlMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Match PHP headers exactly
        context.Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0";
        context.Response.Headers.Append("Cache-Control", "post-check=0, pre-check=0");
        context.Response.Headers["Pragma"] = "no-cache";
        
        await _next(context);
    }
} 