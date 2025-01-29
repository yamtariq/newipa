using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using NayifatAPI.Middleware;
using NayifatAPI.Services;
using Serilog;
using System.Text;
using Microsoft.EntityFrameworkCore;
using NayifatAPI.Data;
using Microsoft.AspNetCore.Mvc.Controllers;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Debug()
    .WriteTo.Console()
    .CreateLogger();

builder.Host.UseSerilog();

// Add controller services
builder.Services.AddControllers();

// Add DbContext
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        sqlServerOptionsAction: sqlOptions =>
        {
            sqlOptions.EnableRetryOnFailure(
                maxRetryCount: 5,
                maxRetryDelay: TimeSpan.FromSeconds(30),
                errorNumbersToAdd: null);
        }
    ));

var app = builder.Build();

// Basic request logging
app.Use(async (context, next) =>
{
    Log.Information("Request: {Method} {Path}", context.Request.Method, context.Request.Path);
    await next();
    Log.Information("Response: {StatusCode}", context.Response.StatusCode);
});

// Basic pipeline
app.UseRouting();
app.MapControllers();

// Log all registered endpoints
var endpointDataSources = app.Services.GetServices<EndpointDataSource>();
foreach (var dataSource in endpointDataSources)
{
    foreach (var endpoint in dataSource.Endpoints)
    {
        if (endpoint is RouteEndpoint routeEndpoint)
        {
            Log.Information(
                "Route registered: {Pattern} -> {DisplayName}",
                routeEndpoint.RoutePattern.RawText,
                routeEndpoint.DisplayName);
        }
    }
}

app.Run("http://localhost:7000"); 