using NayifatAPI.Services;
using NayifatAPI.Middleware;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddMemoryCache();

// Configure MySQL
builder.Services.Configure<DatabaseSettings>(
    builder.Configuration.GetSection("DatabaseSettings"));

// Add our services
builder.Services.AddSingleton<DatabaseService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<ILoanService, LoanService>();
builder.Services.AddScoped<ICardDecisionService, CardDecisionService>();
builder.Services.AddScoped<IGovService, GovService>();
builder.Services.AddScoped<IContentService, ContentService>();
builder.Services.AddHttpContextAccessor();

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors();

// Add our custom middleware
app.UseMiddleware<ApiKeyMiddleware>();
app.UseMiddleware<FeatureHeaderMiddleware>();
app.UseMiddleware<CacheControlMiddleware>();

app.MapControllers();

app.Run();
