using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using NayifatAPI.Middleware;
using NayifatAPI.Services;
using Serilog;
using System.Text;
using Microsoft.EntityFrameworkCore;
using NayifatAPI.Data;
using Microsoft.AspNetCore.Mvc.Controllers;
using System.Net.Http.Headers;
using System.Net;

// 💡 Disable SSL validation globally at application startup
static class CertificateValidation
{
    public static void DisableValidation()
    {
        // Disable all certificate validation
        ServicePointManager.ServerCertificateValidationCallback = (sender, certificate, chain, sslPolicyErrors) => true;
        // Use SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls
        ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
    }
}

var builder = WebApplication.CreateBuilder(args);

// 💡 Disable SSL validation globally before any HTTP clients are created
CertificateValidation.DisableValidation();

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

// Add HttpClient for proxy
builder.Services.AddHttpClient("ProxyClient", client =>
{
    client.DefaultRequestHeaders.Accept.Add(new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
    // No SSL validation settings needed here as it's handled globally
})
.ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler
{
    // No SSL validation settings needed here as it's handled globally
});

// Add HttpClient for decompression
builder.Services.AddHttpClient("DecompressClient", client =>
{
    client.DefaultRequestHeaders.Accept.Add(new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
    // No SSL validation settings needed here as it's handled globally
})
.ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler
{
    // No SSL validation settings needed here as it's handled globally
});

// Add default HttpClient with SSL validation disabled
builder.Services.AddHttpClient("DefaultClient", client =>
{
    // No SSL validation settings needed here as it's handled globally
})
.ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler
{
    // No SSL validation settings needed here as it's handled globally
});

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