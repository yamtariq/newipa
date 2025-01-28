using System.Net;
using System.Text.Json;
using MySql.Data.MySqlClient;

namespace NayifatAPI.Middleware;

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;
    private readonly IHostEnvironment _environment;

    public ExceptionHandlingMiddleware(
        RequestDelegate next,
        ILogger<ExceptionHandlingMiddleware> logger,
        IHostEnvironment environment)
    {
        _next = next;
        _logger = logger;
        _environment = environment;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An unhandled exception occurred");
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        var response = context.Response;
        response.ContentType = "application/json";

        var (statusCode, message) = exception switch
        {
            MySqlException sqlEx => HandleMySqlException(sqlEx),
            ArgumentException _ => (HttpStatusCode.BadRequest, "Invalid input provided"),
            KeyNotFoundException _ => (HttpStatusCode.NotFound, "Requested resource not found"),
            UnauthorizedAccessException _ => (HttpStatusCode.Unauthorized, "Unauthorized access"),
            _ => (HttpStatusCode.InternalServerError, "An unexpected error occurred")
        };

        response.StatusCode = (int)statusCode;

        var result = JsonSerializer.Serialize(new
        {
            status = "error",
            message = message,
            details = _environment.IsDevelopment() ? exception.ToString() : null,
            code = statusCode.ToString()
        });

        await response.WriteAsync(result);
    }

    private (HttpStatusCode statusCode, string message) HandleMySqlException(MySqlException ex)
    {
        return ex.Number switch
        {
            1042 => (HttpStatusCode.ServiceUnavailable, "Database is currently unavailable"),
            1045 => (HttpStatusCode.InternalServerError, "Database authentication failed"),
            1049 => (HttpStatusCode.InternalServerError, "Database does not exist"),
            1062 => (HttpStatusCode.Conflict, "Record already exists"),
            1451 => (HttpStatusCode.Conflict, "Cannot delete due to existing references"),
            _ => (HttpStatusCode.InternalServerError, "A database error occurred")
        };
    }
} 