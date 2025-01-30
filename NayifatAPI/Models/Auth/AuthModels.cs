using System;

namespace NayifatAPI.Models.Auth
{
    public class RegisterRequest
    {
        public required string NationalId { get; set; }
        public required string Password { get; set; }
        public required string Email { get; set; }
        public required string Phone { get; set; }
    }

    public class UserDetailsRequest
    {
        public required string NationalId { get; set; }
        public required string FullNameEn { get; set; }
        public required string FullNameAr { get; set; }
    }

    public class MpinSetupRequest
    {
        public required string NationalId { get; set; }
        public required string Mpin { get; set; }
    }

    public class BiometricsRequest
    {
        public required string NationalId { get; set; }
        public required string BiometricToken { get; set; }
    }

    public class SignInRequest
    {
        public required string NationalId { get; set; }
        public required string Password { get; set; }
    }

    public class OtpRequest
    {
        public required string NationalId { get; set; }
        public required string Otp { get; set; }
    }

    public class OtpResponse
    {
        public bool Success { get; set; }
        public required string Message { get; set; }
        public required string Status { get; set; }
        public DateTime? ExpiryTime { get; set; }
    }

    public class AuthResult
    {
        public bool Success { get; set; }
        public required string Message { get; set; }
        public required string ErrorCode { get; set; }
        public required object Data { get; set; }
    }

    public class SignInResult
    {
        public bool Success { get; set; }
        public required string AccessToken { get; set; }
        public required string RefreshToken { get; set; }
        public required UserProfile UserProfile { get; set; }
        public required DeviceStatus DeviceStatus { get; set; }
    }

    public class UserProfile
    {
        public required string NationalId { get; set; }
        public required string FullNameEn { get; set; }
        public required string FullNameAr { get; set; }
        public required string Email { get; set; }
        public required string Phone { get; set; }
        public bool IsEmailVerified { get; set; }
        public bool IsPhoneVerified { get; set; }
        public bool IsMpinEnabled { get; set; }
        public bool IsBiometricsEnabled { get; set; }
    }

    public class DeviceStatus
    {
        public bool IsRegistered { get; set; }
        public bool BiometricsEnabled { get; set; }
        public bool MpinEnabled { get; set; }
        public DateTime LastLoginDate { get; set; }
    }
} 