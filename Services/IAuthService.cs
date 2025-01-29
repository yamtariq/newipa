using NayifatAPI.Models.Auth;
using System.Threading.Tasks;

namespace NayifatAPI.Services
{
    public interface IAuthService
    {
        Task<AuthResult> RegisterUser(RegisterRequest request);
        Task<AuthResult> SetUserDetails(UserDetailsRequest request);
        Task<AuthResult> SetupMpin(MpinSetupRequest request);
        Task<AuthResult> SetupBiometrics(BiometricsRequest request);
        Task<SignInResult> SignIn(SignInRequest request);
        Task<OtpResponse> VerifyOTP(OtpRequest request);
        Task<OtpResponse> ResendOTP(OtpRequest request);
    }

    public class AuthResult
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public string ErrorCode { get; set; }
        public object Data { get; set; }
    }

    public class SignInResult
    {
        public bool Success { get; set; }
        public string AccessToken { get; set; }
        public string RefreshToken { get; set; }
        public UserProfile UserProfile { get; set; }
        public DeviceStatus DeviceStatus { get; set; }
    }

    public class UserProfile
    {
        public string NationalId { get; set; }
        public string FullNameEn { get; set; }
        public string FullNameAr { get; set; }
        public string Email { get; set; }
        public string Phone { get; set; }
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