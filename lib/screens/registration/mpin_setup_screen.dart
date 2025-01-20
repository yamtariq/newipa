import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/registration_service.dart';
import 'biometric_setup_screen.dart';

class MPINSetupScreen extends StatefulWidget {
  final String nationalId;
  final bool isArabic;
  final bool showSteps;
  final String password;

  const MPINSetupScreen({
    Key? key,
    required this.nationalId,
    required this.isArabic,
    required this.password,
    this.showSteps = true,
  }) : super(key: key);

  @override
  State<MPINSetupScreen> createState() => _MPINSetupScreenState();
}

class _MPINSetupScreenState extends State<MPINSetupScreen> {
  final List<String> _pin = List.filled(6, '');
  final List<String> _confirmPin = List.filled(6, '');
  bool _isConfirming = false;
  bool _isLoading = false;
  String? _errorMessage;
  final Color primaryColor = const Color(0xFF0077B6);
  final AuthService _authService = AuthService();

  void _handleDigit(String value) {
    setState(() {
      // Clear error message when user starts entering digits
      if (_errorMessage != null) {
        _errorMessage = null;
      }
      
      final targetPin = _isConfirming ? _confirmPin : _pin;
      final emptyIndex = targetPin.indexOf('');
      if (emptyIndex != -1) {
        targetPin[emptyIndex] = value;
        
        // If current PIN is complete
        if (!targetPin.contains('')) {
          if (_isConfirming) {
            // Both PINs are complete, verify and proceed
            _handleMPINSetup();
          } else {
            // First PIN is complete, move to confirmation
            _isConfirming = true;
          }
        }
      }
    });
  }

  void _handleBackspace() {
    setState(() {
      final targetPin = _isConfirming ? _confirmPin : _pin;
      final lastFilledIndex = targetPin.lastIndexWhere((digit) => digit.isNotEmpty);
      if (lastFilledIndex != -1) {
        targetPin[lastFilledIndex] = '';
      } else if (_isConfirming && _confirmPin.every((digit) => digit.isEmpty)) {
        // If confirmation PIN is empty, go back to first PIN
        _isConfirming = false;
      }
    });
  }

  void _handleClear() {
    setState(() {
      if (_isConfirming) {
        _confirmPin.fillRange(0, _confirmPin.length, '');
      } else {
        _pin.fillRange(0, _pin.length, '');
      }
    });
  }

  Future<void> _handleMPINSetup() async {
    final enteredPin = _pin.join();
    final confirmedPin = _confirmPin.join();
    
    if (enteredPin == confirmedPin) {
      setState(() => _isLoading = true);

      try {
        // Save MPIN using AuthService
        await _authService.storeMPIN(enteredPin);

        if (!mounted) return;

        // Navigate to biometric setup
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => BiometricSetupScreen(
              nationalId: widget.nationalId,
              password: widget.password,
              mpin: enteredPin,
              isArabic: widget.isArabic,
              showSteps: widget.showSteps,
              onSetupComplete: (success) {
                // Handle biometric setup completion
              },
            ),
          ),
        );
      } catch (e) {
        if (mounted) {
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
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      setState(() {
        _errorMessage = widget.isArabic 
            ? 'رمز الدخول غير متطابق'
            : 'MPIN does not match';
        _confirmPin.fillRange(0, _confirmPin.length, '');
        _isConfirming = false;
      });
    }
  }

  Widget _buildPINDisplay(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final bool isFilled = digits[index].isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 20,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? primaryColor : Colors.transparent,
            border: Border.all(
              color: isFilled ? primaryColor : Colors.grey[300]!,
              width: 2,
            ),
            boxShadow: isFilled ? [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              )
            ] : null,
          ),
        );
      }),
    );
  }

  Widget _buildNumpad() {
    final primaryColor = const Color(0xFF0077B6);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['1', '2', '3']
                .map((number) => _buildNumpadButton(number))
                .toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['4', '5', '6']
                .map((number) => _buildNumpadButton(number))
                .toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['7', '8', '9']
                .map((number) => _buildNumpadButton(number))
                .toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumpadButton('C', isSpecial: true),
              _buildNumpadButton('0'),
              _buildNumpadButton('⌫', isSpecial: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadButton(String value, {bool isSpecial = false}) {
    final bool isBackspace = value == '⌫';
    final bool isClear = value == 'C';
    final primaryColor = const Color(0xFF0077B6);
    
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) => setState(() {}),
      onTapCancel: () => setState(() {}),
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          gradient: !isSpecial ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipOval(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading
                  ? null
                  : () {
                      if (isBackspace) {
                        _handleBackspace();
                      } else if (isClear) {
                        _handleClear();
                      } else {
                        _handleDigit(value);
                      }
                    },
              splashColor: primaryColor.withOpacity(0.1),
              highlightColor: primaryColor.withOpacity(0.05),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: isBackspace
                      ? Icon(
                          Icons.backspace_rounded,
                          color: primaryColor,
                          size: 28,
                        )
                      : isClear
                          ? Text(
                              'C',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w100,
                                color: primaryColor,
                                letterSpacing: 1,
                              ),
                            )
                          : Text(
                              value,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                                letterSpacing: 1,
                              ),
                            ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0077B6);
    final backgroundColor = const Color(0xFFF5F6FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: constraints.maxHeight < 600 
                  ? const AlwaysScrollableScrollPhysics() 
                  : const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  minWidth: constraints.maxWidth,
                ),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      // Background Logo
                      Positioned(
                        top: -75,
                        right: widget.isArabic ? null : -75,
                        left: widget.isArabic ? -75 : null,
                        child: Opacity(
                          opacity: 0.2,
                          child: Image.asset(
                            'assets/images/nayifatlogocircle-nobg.png',
                            width: 200,
                            height: 200,
                          ),
                        ),
                      ),

                      // Main Content
                      Column(
                        children: [
                          const SizedBox(height: 40),
                          // Title with decoration
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Column(
                              children: [
                                Text(
                                  _isConfirming
                                      ? (widget.isArabic ? 'تأكيد رمز الدخول' : 'Confirm MPIN')
                                      : (widget.isArabic ? 'إنشاء رمز دخول سريع' : 'Create MPIN'),
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 60,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (widget.showSteps) ...[
                            // Progress Indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(3 * 2 - 1, (index) {
                                      if (index % 2 == 0) {
                                        final stepIndex = index ~/ 2;
                                        final isActive = stepIndex == 2;
                                        final isPast = stepIndex < 2;
                                        return Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isActive || isPast
                                                ? primaryColor
                                                : Colors.grey[300],
                                          ),
                                          child: Center(
                                            child: Text(
                                              widget.isArabic 
                                                  ? '${3 - stepIndex}'
                                                  : '${stepIndex + 1}',
                                              style: TextStyle(
                                                color: isActive || isPast
                                                    ? Colors.white
                                                    : Colors.grey[600],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        return Container(
                                          width: 60,
                                          height: 2,
                                          color: Colors.grey[300],
                                          margin: const EdgeInsets.symmetric(horizontal: 4),
                                        );
                                      }
                                    }),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(3 * 2 - 1, (index) {
                                      if (index % 2 == 0) {
                                        final stepIndex = index ~/ 2;
                                        final steps = widget.isArabic
                                            ? ['رمز الدخول', 'كلمة المرور', 'معلومات']
                                            : ['Basic', 'Password', 'MPIN'];
                                        final isActive = stepIndex == 2;
                                        return SizedBox(
                                          width: 80,
                                          child: Text(
                                            steps[stepIndex],
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: isActive ? primaryColor : (stepIndex < 2 ? primaryColor : Colors.grey[600]),
                                              fontWeight: isActive ? FontWeight.bold : (stepIndex < 2 ? FontWeight.bold : FontWeight.normal),
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      } else {
                                        return SizedBox(width: 40);
                                      }
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                          ],

                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 40),
                                Text(
                                  _isConfirming
                                      ? (widget.isArabic ? 'أدخل رمز الدخول مرة أخرى للتأكيد' : 'Enter MPIN again to confirm')
                                      : (widget.isArabic ? 'أدخل رمز دخول مكون من 6 أرقام' : 'Enter a 6-digit MPIN'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 40),
                                _buildPINDisplay(_isConfirming ? _confirmPin : _pin),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            child: _buildNumpad(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
