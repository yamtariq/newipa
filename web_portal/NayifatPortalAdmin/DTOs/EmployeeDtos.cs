namespace NayifatPortalAdmin.DTOs;

public record UpdateEmployeeRequest(
    string Name,
    string Phone,
    string Status,
    List<string>? Roles
);

public record ActivityLogResponse(
    int LogId,
    string EmployeeName,
    string Action,
    string? Details,
    string IpAddress,
    DateTime CreatedAt
);
