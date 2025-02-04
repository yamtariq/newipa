using Microsoft.EntityFrameworkCore;
using NayifatPortalAdmin.Data;
using NayifatPortalAdmin.DTOs;
using NayifatPortalAdmin.Models;

namespace NayifatPortalAdmin.Services;

public class EmployeeService
{
    private readonly ApplicationDbContext _context;

    public EmployeeService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<EmployeeResponse>> GetEmployeesAsync()
    {
        return await _context.Employees
            .Include(e => e.Roles)
            .Select(e => new EmployeeResponse(
                e.EmployeeId,
                e.Name,
                e.Email,
                e.Phone ?? string.Empty,
                e.Status.ToString(),
                e.CreatedAt,
                e.Roles.Select(r => r.Role).ToList()
            ))
            .ToListAsync();
    }

    public async Task<EmployeeResponse?> GetEmployeeByIdAsync(int id)
    {
        var employee = await _context.Employees
            .Include(e => e.Roles)
            .FirstOrDefaultAsync(e => e.EmployeeId == id);

        if (employee == null)
            return null;

        return new EmployeeResponse(
            employee.EmployeeId,
            employee.Name,
            employee.Email,
            employee.Phone ?? string.Empty,
            employee.Status.ToString(),
            employee.CreatedAt,
            employee.Roles.Select(r => r.Role).ToList()
        );
    }

    public async Task<bool> UpdateEmployeeAsync(int id, UpdateEmployeeRequest request)
    {
        var employee = await _context.Employees.FindAsync(id);
        if (employee == null)
            return false;

        employee.Name = request.Name;
        employee.Phone = request.Phone;
        employee.Status = Enum.Parse<EmployeeStatus>(request.Status);

        if (request.Roles != null)
        {
            var currentRoles = await _context.Roles
                .Where(r => r.EmployeeId == id)
                .ToListAsync();

            _context.Roles.RemoveRange(currentRoles);

            foreach (var role in request.Roles)
            {
                _context.Roles.Add(new PortalRole
                {
                    EmployeeId = id,
                    Role = role,
                    AssignedAt = DateTime.UtcNow
                });
            }
        }

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<(bool success, string? error)> DeleteEmployeeAsync(int id)
    {
        var employee = await _context.Employees.FindAsync(id);
        if (employee == null)
            return (false, "Employee not found");

        var isSuperAdmin = await _context.Roles
            .AnyAsync(r => r.EmployeeId == id && r.Role == "super_admin");

        if (isSuperAdmin)
        {
            var superAdminCount = await _context.Roles
                .CountAsync(r => r.Role == "super_admin");

            if (superAdminCount <= 1)
                return (false, "Cannot delete the last super admin");
        }

        _context.Employees.Remove(employee);
        await _context.SaveChangesAsync();
        return (true, null);
    }

    public async Task<List<ActivityLogResponse>> GetActivityLogsAsync(int limit = 1000)
    {
        return await _context.ActivityLogs
            .Include(l => l.Employee)
            .OrderByDescending(l => l.CreatedAt)
            .Take(limit)
            .Select(l => new ActivityLogResponse(
                l.LogId,
                l.Employee.Name,
                l.Action,
                l.Details,
                l.IpAddress ?? "Unknown",
                l.CreatedAt
            ))
            .ToListAsync();
    }

    public async Task<(bool success, string? error)> ChangePasswordAsync(int employeeId, ChangePasswordRequest request)
    {
        if (request.NewPassword != request.ConfirmNewPassword)
            return (false, "New password and confirmation do not match");

        if (request.NewPassword.Length < 8)
            return (false, "New password must be at least 8 characters long");

        var employee = await _context.Employees.FindAsync(employeeId);
        if (employee == null)
            return (false, "Employee not found");

        if (!BCrypt.Net.BCrypt.Verify(request.CurrentPassword, employee.Password))
            return (false, "Current password is incorrect");

        employee.Password = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        await _context.SaveChangesAsync();

        return (true, null);
    }
}
