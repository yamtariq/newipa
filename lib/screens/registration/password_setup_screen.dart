import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../../services/auth_service.dart';
import '../../services/registration_service.dart';
import 'mpin_setup_screen.dart';

class PasswordSetupScreen extends StatefulWidget {
  final String nationalId;
  final bool isArabic;

  const PasswordSetupScreen({
    Key? key,
    required this.nationalId,
    this.isArabic = false,
  }) : super(key: key);

  @override
  State<PasswordSetupScreen> createState() => _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends State<PasswordSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _registrationService = RegistrationService();
  final _authService = AuthService();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  double _passwordStrength = 0.0;

  final List<String> _stepsEn = ['Basic', 'Password', 'MPIN'];
  final List<String> _stepsAr = ['معلومات', 'كلمة المرور', 'رمز الدخول'];

  @override
  void initState() {
    super.initState();
    // Disable back button
    SystemChannels.platform.invokeMethod('SystemNavigator.preventPopRoute');
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;

    double strength = 0;

    // Length check
    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.2;

    // Character types check
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;

    return strength;
  }

  bool _meetsRequirements(String password) {
    return password.length >= 8 &&
        password.length <= 24 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        !password.contains(' ') &&
        !password.toLowerCase().contains(widget.nationalId.toLowerCase());
  }

  Widget _buildStepIndicator() {
    final steps = widget.isArabic ? _stepsAr : _stepsEn;
    final currentStep = 1; // Password step
    final primaryColor = Color(0xFF0077B6);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(steps.length * 2 - 1, (index) {
                  if (index % 2 == 0) {
                    final stepIndex = index ~/ 2;
                    final isActive = stepIndex == currentStep;
                    final isPast = stepIndex < currentStep;
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
                          '${stepIndex + 1}',
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
                children: List.generate(steps.length * 2 - 1, (index) {
                  if (index % 2 == 0) {
                    final stepIndex = index ~/ 2;
                    final isActive = stepIndex == currentStep;
                    return SizedBox(
                      width: 80,
                      child: Text(
                        steps[stepIndex],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isActive ? primaryColor : (stepIndex < currentStep ? primaryColor : Colors.grey[600]),
                          fontWeight:
                              isActive ? FontWeight.bold : (stepIndex < currentStep ? FontWeight.bold : FontWeight.normal),
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
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final Color indicatorColor;
    final String strengthText;

    if (_passwordStrength >= 0.8) {
      indicatorColor = Colors.green;
      strengthText = widget.isArabic ? 'قوية' : 'Strong';
    } else if (_passwordStrength >= 0.5) {
      indicatorColor = Colors.yellow;
      strengthText = widget.isArabic ? 'متوسطة' : 'Medium';
    } else {
      indicatorColor = Colors.red;
      strengthText = widget.isArabic ? 'ضعيفة' : 'Weak';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _passwordStrength,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strengthText,
          style: TextStyle(
            color: indicatorColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementsList() {
    final password = _passwordController.text;
    final requirements = [
      {
        'met': password.length >= 8 && password.length <= 24,
        'text': widget.isArabic ? '8-24 حرف' : '8-24 characters',
      },
      {
        'met': password.contains(RegExp(r'[A-Z]')),
        'text': widget.isArabic
            ? 'حرف كبير واحد على الأقل'
            : 'At least one uppercase letter',
      },
      {
        'met': password.contains(RegExp(r'[a-z]')),
        'text': widget.isArabic
            ? 'حرف صغير واحد على الأقل'
            : 'At least one lowercase letter',
      },
      {
        'met': password.contains(RegExp(r'[0-9]')),
        'text': widget.isArabic ? 'رقم واحد على الأقل' : 'At least one number',
      },
      {
        'met': !password.contains(' '),
        'text': widget.isArabic ? 'لا يحتوي على مسافات' : 'No spaces allowed',
      },
      {
        'met':
            !password.toLowerCase().contains(widget.nationalId.toLowerCase()),
        'text': widget.isArabic
            ? 'لا يحتوي على رقم الهوية'
            : 'Cannot contain National ID',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: requirements.map((requirement) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                requirement['met'] as bool ? Icons.check_circle : Icons.cancel,
                color: requirement['met'] as bool ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                requirement['text'] as String,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Get stored registration data
      final registrationData = await _registrationService.getStoredRegistrationData();
      if (registrationData == null) {
        throw Exception('Registration data not found');
      }

      // Update stored data with password
      await _registrationService.storeRegistrationData(
        nationalId: registrationData['national_id'],
        password: _passwordController.text,
        email: registrationData['email'],
        phone: registrationData['phone'],
        userData: registrationData['userData'],
      );

      // Navigate to MPIN setup
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MPINSetupScreen(
              nationalId: widget.nationalId,
              password: _passwordController.text,
              isArabic: widget.isArabic,
              showSteps: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF0077B6);
    final backgroundColor = Color(0xFFF5F6FA);
    final inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red[300]!, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red[300]!, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: Colors.grey[700]),
      hintStyle: TextStyle(color: Colors.grey[400]),
    );

    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Directionality(
        textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Column(
                        children: [
                          Text(
                            widget.isArabic
                                ? 'إنشاء كلمة المرور'
                                : 'Create Password',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
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

                    // Progress Indicator
                    _buildStepIndicator(),

                    // Form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Password Field
                              Theme(
                                data: Theme.of(context).copyWith(
                                  inputDecorationTheme: inputDecorationTheme,
                                ),
                                child: TextFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
                                  },
                                  decoration: InputDecoration(
                                    labelText: widget.isArabic
                                        ? 'كلمة المرور'
                                        : 'Password',
                                    hintText: widget.isArabic
                                        ? 'أدخل كلمة المرور'
                                        : 'Enter password',
                                    prefixIcon: Icon(Icons.lock_outline,
                                        color: primaryColor),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _passwordStrength =
                                          _calculatePasswordStrength(value);
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return widget.isArabic
                                          ? 'كلمة المرور مطلوبة'
                                          : 'Password is required';
                                    }
                                    if (!_meetsRequirements(value)) {
                                      return widget.isArabic
                                          ? 'كلمة المرور لا تلبي المتطلبات'
                                          : 'Password does not meet requirements';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Password Strength Indicator
                              _buildPasswordStrengthIndicator(),
                              const SizedBox(height: 20),

                              // Requirements List
                              _buildRequirementsList(),
                              const SizedBox(height: 20),

                              // Confirm Password Field
                              Theme(
                                data: Theme.of(context).copyWith(
                                  inputDecorationTheme: inputDecorationTheme,
                                ),
                                child: TextFormField(
                                  controller: _confirmPasswordController,
                                  focusNode: _confirmPasswordFocusNode,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: InputDecoration(
                                    labelText: widget.isArabic
                                        ? 'تأكيد كلمة المرور'
                                        : 'Confirm Password',
                                    hintText: widget.isArabic
                                        ? 'أعد إدخال كلمة المرور'
                                        : 'Re-enter password',
                                    prefixIcon: Icon(Icons.lock_outline,
                                        color: primaryColor),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return widget.isArabic
                                          ? 'تأكيد كلمة المرور مطلوب'
                                          : 'Password confirmation is required';
                                    }
                                    if (value != _passwordController.text) {
                                      return widget.isArabic
                                          ? 'كلمات المرور غير متطابقة'
                                          : 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom Buttons
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                                foregroundColor: Colors.black87,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                widget.isArabic ? 'إلغاء' : 'Cancel',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleNext,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(
                                      widget.isArabic ? 'التالي' : 'Next',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
