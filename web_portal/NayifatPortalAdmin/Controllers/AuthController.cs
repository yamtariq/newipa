using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NayifatPortalAdmin.Data;
using NayifatPortalAdmin.DTOs;
using NayifatPortalAdmin.Models;
using NayifatPortalAdmin.Services;

namespace NayifatPortalAdmin.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly JwtService _jwtService;

    public AuthController(ApplicationDbContext context, JwtService jwtService)
    {
        _context = context;
        _jwtService = jwtService;
    }

    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> Login(LoginRequest request)
    {
        var employee = await _context.Employees
            .Include(e => e.Roles)
            .FirstOrDefaultAsync(e => e.Email == request.Email);

        if (employee == null || !BCrypt.Net.BCrypt.Verify(request.Password, employee.Password))
        {
            return Unauthorized(new { message = "Invalid email or password" });
        }

        if (employee.Status != EmployeeStatus.Active)
        {
            return Unauthorized(new { message = "Account is inactive" });
        }

        var roles = employee.Roles.Select(r => r.Role).ToList();
        var token = _jwtService.GenerateToken(employee, roles);

        // Update last login
        employee.LastLogin = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return new LoginResponse(token, employee.Name, employee.Email, roles);
    }

    [HttpPost("register")]
    public async Task<ActionResult<EmployeeResponse>> Register(RegisterEmployeeRequest request)
    {
        if (await _context.Employees.AnyAsync(e => e.Email == request.Email))
        {
            return BadRequest(new { message = "Email already registered" });
        }

        var employee = new PortalEmployee
        {
            Name = request.Name,
            Email = request.Email,
            Password = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Phone = request.Phone,
            Status = EmployeeStatus.Active,
            CreatedAt = DateTime.UtcNow
        };

        _context.Employees.Add(employee);
        await _context.SaveChangesAsync();

        // Add roles
        foreach (var role in request.Roles)
        {
            _context.Roles.Add(new PortalRole
            {
                EmployeeId = employee.EmployeeId,
                Role = role,
                AssignedAt = DateTime.UtcNow
            });
        }

        await _context.SaveChangesAsync();

        return new EmployeeResponse(
            employee.EmployeeId,
            employee.Name,
            employee.Email,
            employee.Phone ?? string.Empty,
            employee.Status.ToString(),
            employee.CreatedAt,
            request.Roles
        );
    }
}
