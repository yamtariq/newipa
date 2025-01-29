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

// Basic logging
builder.Services.AddLogging(logging =>
{
    logging.ClearProviders();
    logging.AddConsole();
    logging.SetMinimumLevel(LogLevel.Debug);
});

// Add ONLY controller services
builder.Services.AddControllers();

var app = builder.Build();

// Log all controllers at startup
var controllerTypes = app.Services.GetServices<IEnumerable<EndpointDataSource>>()
    .SelectMany(ds => ds.Endpoints)
    .OfType<RouteEndpoint>()
    .Select(e => e.DisplayName)
    .ToList();

Console.WriteLine("Found controllers:");
foreach (var controller in controllerTypes)
{
    Console.WriteLine($"- {controller}");
}

// Basic pipeline
app.UseRouting();
app.MapControllers();

app.Run("http://localhost:5000"); 