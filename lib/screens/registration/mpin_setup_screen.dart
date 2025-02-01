import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/registration_service.dart';
import 'biometric_setup_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';

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
  final AuthService _authService = AuthService();
  final RegistrationService _registrationService = RegistrationService();

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
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // 1. Set MPIN in the backend
        final mpinResult = await _registrationService.setMPIN(
          widget.nationalId,
          enteredPin,
        );

        if (mpinResult['status'] != 'success') {
          throw Exception(mpinResult['message']);
        }

        // 2. Store MPIN locally using secure storage
        await _authService.storeMPIN(enteredPin);

        if (!mounted) return;

        // 3. Navigate to biometric setup
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BiometricSetupScreen(
              nationalId: widget.nationalId,
              password: widget.password,
              mpin: enteredPin,
              isArabic: widget.isArabic,
              showSteps: widget.showSteps,
              onSetupComplete: (bool success) async {
                if (success) {
                  await _registrationService.completeRegistration(
                    nationalId: widget.nationalId,
                    password: widget.password,
                    mpin: enteredPin,
                    enableBiometric: true,
                  );
                }
              },
            ),
          ),
        );
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _confirmPin.fillRange(0, _confirmPin.length, '');
          _isConfirming = false;
        });
      } finally {
        setState(() => _isLoading = false);
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final inactiveColor = themeProvider.isDarkMode 
        ? Colors.grey[700]
        : Colors.grey[300];

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
              color: isFilled ? primaryColor : inactiveColor!,
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

  Widget _buildNumpadButton(String value, {bool isSpecial = false}) {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: true).isDarkMode;
    final themeColor = isDarkMode 
        ? Color(Constants.darkPrimaryColor) 
        : Color(Constants.lightPrimaryColor);
    final bool isBackspace = value == '⌫';
    final bool isClear = value == 'C';
    
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) => setState(() {}),
      onTapCancel: () => setState(() {}),
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDarkMode 
              ? Color(Constants.darkFormBackgroundColor)
              : (isSpecial ? themeColor : Colors.white),
          gradient: !isSpecial ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode ? [
              Color(Constants.darkGradientStartColor),
              Color(Constants.darkGradientEndColor),
            ] : [
              Colors.white,
              Colors.white,
            ],
          ) : null,
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                  ? Color(Constants.darkPrimaryShadowColor)
                  : Color(Constants.lightPrimaryShadowColor),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: isDarkMode 
                  ? Color(Constants.darkSecondaryShadowColor)
                  : Color(Constants.lightSecondaryShadowColor),
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
              splashColor: themeColor.withOpacity(0.1),
              highlightColor: themeColor.withOpacity(0.05),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode 
                        ? Color(Constants.darkFormBorderColor)
                        : Color(Constants.lightFormBorderColor),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: isBackspace
                      ? Icon(
                          Icons.backspace_rounded,
                          color: isDarkMode ? themeColor : (isSpecial ? Colors.white : themeColor),
                          size: 28,
                        )
                      : isClear
                          ? Text(
                              'C',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w100,
                                color: isDarkMode ? themeColor : (isSpecial ? Colors.white : themeColor),
                                letterSpacing: 1,
                              ),
                            )
                          : Text(
                              value,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode 
                                    ? Color(Constants.darkLabelTextColor)
                                    : Color(Constants.lightLabelTextColor),
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

  Widget _buildNumpad() {
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Color(themeProvider.isDarkMode 
        ? Constants.darkBackgroundColor 
        : Constants.lightBackgroundColor);
    final primaryColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final surfaceColor = Color(themeProvider.isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              // Background Logo
              Positioned(
                top: -100,
                right: widget.isArabic ? null : -100,
                left: widget.isArabic ? -100 : null,
                child: themeProvider.isDarkMode
                  ? Image.asset(
                      'assets/images/nayifat-circle-grey.png',
                      width: 240,
                      height: 240,
                    )
                  : Opacity(
                      opacity: 0.2,
                      child: Image.asset(
                        'assets/images/nayifatlogocircle-nobg.png',
                        width: 240,
                        height: 240,
                      ),
                    ),
              ),

              // Main Content
              Column(
                children: [
                  const SizedBox(height: 40),
                  // Title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      children: [
                        Text(
                          widget.isArabic ? 'إنشاء رمز الدخول' : 'Create MPIN',
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
                                    color: isActive || isPast ? primaryColor : surfaceColor,
                                    border: Border.all(
                                      color: isActive || isPast ? primaryColor : Colors.grey[300]!,
                                      width: 1,
                                    ),
                                    boxShadow: isActive ? [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ] : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.isArabic 
                                          ? '${3 - stepIndex}'
                                          : '${stepIndex + 1}',
                                      style: TextStyle(
                                        color: isActive || isPast
                                            ? (themeProvider.isDarkMode ? Colors.black : Colors.white)
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                final stepIndex = index ~/ 2;
                                final isPastLine = stepIndex < 2;
                                return Container(
                                  width: 60,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isPastLine ? [
                                        primaryColor,
                                        primaryColor,
                                      ] : [
                                        primaryColor.withOpacity(0.5),
                                        Colors.grey[300]!,
                                      ],
                                    ),
                                  ),
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
                                final isPast = stepIndex < 2;
                                return SizedBox(
                                  width: 80,
                                  child: Text(
                                    steps[stepIndex],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isActive || isPast 
                                          ? primaryColor 
                                          : Colors.grey[600],
                                      fontWeight: isActive || isPast 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              } else {
                                return const SizedBox(width: 40);
                              }
                            }),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey[600],
                    ),
                  ],

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              Text(
                                _isConfirming
                                    ? (widget.isArabic ? 'أدخل رمز الدخول مرة أخرى للتأكيد' : 'Enter MPIN again to confirm')
                                    : (widget.isArabic ? 'أدخل رمز دخول مكون من 6 أرقام' : 'Enter a 6-digit MPIN'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildPINDisplay(_isConfirming ? _confirmPin : _pin),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                            ],
                          ),
                          _buildNumpad(),
                          // Add some bottom padding for scrolling
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
