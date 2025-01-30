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
} 