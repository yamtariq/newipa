class MPINSetupScreen extends StatefulWidget {
  final String nationalId;
  final String password;
  final Map<String, dynamic> user;
  final bool isArabic;

  const MPINSetupScreen({
    Key? key,
    required this.nationalId,
    required this.password,
    required this.user,
    this.isArabic = false,
  }) : super(key: key);

  @override
  State<MPINSetupScreen> createState() => _MPINSetupScreenState();
}

class _MPINSetupScreenState extends State<MPINSetupScreen> {
  // ... existing code ...

  Future<void> _handleMPINSetup() async {
    if (_pin.join() == _confirmPin.join() && _isValidPin(_pin)) {
      setState(() => _isLoading = true);
      
      try {
        // Save MPIN using AuthService
        final mpin = _pin.join();
        await _authService.storeMPIN(mpin);
        
        if (!mounted) return;
        
        // Navigate to biometric setup
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => BiometricSetupScreen(
              isArabic: widget.isArabic,
              userData: {
                'nationalId': widget.nationalId,
                'password': widget.password,
                'mpin': mpin,
                ...widget.user,
              },
            ),
          ),
        );
      } catch (e) {
        print('Error saving MPIN: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic 
                  ? 'حدث خطأ أثناء حفظ رمز الدخول'
                  : 'Error saving MPIN',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
} 