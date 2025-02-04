using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NayifatPortalAdmin.Data;
using NayifatPortalAdmin.DTOs;
using NayifatPortalAdmin.Services;

namespace NayifatPortalAdmin.Controllers;

[Authorize]
public class EmployeesController : BaseApiController
{
    private readonly EmployeeService _employeeService;

    public EmployeesController(ApplicationDbContext context, EmployeeService employeeService) 
        : base(context)
    {
        _employeeService = employeeService;
    }

    [HttpGet]
    [Authorize(Roles = "super_admin,admin")]
    public async Task<ActionResult<List<EmployeeResponse>>> GetEmployees()
    {
        var employees = await _employeeService.GetEmployeesAsync();
        await LogActivityAsync("View Employees List");
        return employees;
    }

    [HttpGet("{id}")]
    [Authorize(Roles = "super_admin,admin")]
    public async Task<ActionResult<EmployeeResponse>> GetEmployee(int id)
    {
        var employee = await _employeeService.GetEmployeeByIdAsync(id);
        if (employee == null)
            return NotFound();

        await LogActivityAsync("View Employee Details", $"Employee ID: {id}");
        return employee;
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "super_admin")]
    public async Task<ActionResult> UpdateEmployee(int id, [FromBody] UpdateEmployeeRequest request)
    {
        var success = await _employeeService.UpdateEmployeeAsync(id, request);
        if (!success)
            return NotFound();

        await LogActivityAsync("Update Employee", $"Updated employee ID: {id}");
        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "super_admin")]
    public async Task<ActionResult> DeleteEmployee(int id)
    {
        var (success, error) = await _employeeService.DeleteEmployeeAsync(id);
        if (!success)
            return error == "Employee not found" ? NotFound() : BadRequest(error);

        await LogActivityAsync("Delete Employee", $"Deleted employee ID: {id}");
        return NoContent();
    }

    [HttpGet("activity-logs")]
    [Authorize(Roles = "super_admin")]
    public async Task<ActionResult<List<ActivityLogResponse>>> GetActivityLogs()
    {
        var logs = await _employeeService.GetActivityLogsAsync();
        await LogActivityAsync("View Activity Logs");
        return logs;
    }

    [HttpPost("change-password")]
    [Authorize]
    public async Task<ActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        var employeeId = GetCurrentUserId();
        var (success, error) = await _employeeService.ChangePasswordAsync(employeeId, request);
        
        if (!success)
            return BadRequest(new { message = error });

        await LogActivityAsync("Changed Password");
        return NoContent();
    }
}
