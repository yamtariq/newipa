namespace NayifatPortalAdmin.DTOs;

public record LoginRequest(string Email, string Password);

public record LoginResponse(string Token, string Name, string Email, List<string> Roles);

public record RegisterEmployeeRequest(
    string Name,
    string Email,
    string Password,
    string Phone,
    List<string> Roles
);

public record EmployeeResponse(
    int EmployeeId,
    string Name,
    string Email,
    string Phone,
    string Status,
    DateTime CreatedAt,
    List<string> Roles
);

public record ChangePasswordRequest(
    string CurrentPassword,
    string NewPassword,
    string ConfirmNewPassword
);
