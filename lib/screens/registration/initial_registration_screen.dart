import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:hijri_picker/hijri_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/auth_service.dart';
import '../../services/registration_service.dart';
import '../../widgets/otp_dialog.dart';
import '../auth/sign_in_screen.dart';
import 'password_setup_screen.dart';
import '../main_page.dart';
import '../../widgets/device_dialogs.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/nafath_verification_dialog.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'package:flutter_holo_date_picker/widget/date_picker_widget.dart';
import '../../widgets/custom_hijri_picker.dart';

class InitialRegistrationScreen extends StatefulWidget {
  final bool isArabic;

  const InitialRegistrationScreen({
    Key? key,
    this.isArabic = false,
  }) : super(key: key);

  @override
  State<InitialRegistrationScreen> createState() =>
      _InitialRegistrationScreenState();
}

class _InitialRegistrationScreenState extends State<InitialRegistrationScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _idExpiryController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  final RegistrationService _registrationService = RegistrationService();
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'SA');
  DateTime? _selectedDate;
  DateTime? _selectedExpiryDate;
  DateTime? _tempSelectedDate;
  DateTime? _tempSelectedExpiryDate;
  bool _isLoading = false;
  bool _isHijri = true; // Default to Hijri as per Saudi standards
  String? _errorMessage;
  late final AnimationController _animationController;

  final List<String> _stepsEn = ['Basic', 'Password', 'MPIN'];

  final List<String> _stepsAr = ['معلومات', 'كلمة المرور', 'رمز الدخول'];

  @override
  void initState() {
    super.initState();
    // Set locale for Hijri calendar
    HijriCalendar.setLocal(widget.isArabic ? 'ar' : 'en');
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _nationalIdController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _idExpiryController.dispose();
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildStepIndicator() {
    final steps = widget.isArabic ? _stepsAr : _stepsEn;
    final currentStep = 0; // First step
    final themeProvider = Provider.of<ThemeProvider>(context);
    final activeColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final inactiveColor = Color(themeProvider.isDarkMode 
        ? Constants.darkSurfaceColor
        : Constants.lightSurfaceColor);
    final inactiveBorderColor = Color(themeProvider.isDarkMode 
        ? Constants.darkFormBorderColor 
        : Constants.lightFormBorderColor);
    final activeTextColor = themeProvider.isDarkMode ? Colors.black : Colors.white;
    final inactiveTextColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              // Circles and lines
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(steps.length * 2 - 1, (index) {
                  if (index % 2 == 0) {
                    final stepIndex = index ~/ 2;
                    final isActive = stepIndex == currentStep;
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? activeColor : inactiveColor,
                        border: Border.all(
                          color: isActive ? activeColor : inactiveBorderColor,
                          width: 1,
                        ),
                        boxShadow: isActive ? [
                          BoxShadow(
                            color: activeColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Center(
                        child: Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isActive 
                                ? activeTextColor
                                : inactiveTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Container(
                      width: 60,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            activeColor.withOpacity(0.5),
                            inactiveBorderColor,
                          ],
                        ),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }
                }),
              ),
              const SizedBox(height: 8),
              // Step labels
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
                          color: isActive 
                              ? activeColor
                              : inactiveTextColor,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
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
          color: inactiveBorderColor,
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isExpiryDate) async {
    final DateTime initialDate = isExpiryDate 
        ? DateTime.now()
        : DateTime.now().subtract(const Duration(days: 365 * 18));
    final DateTime firstDate = isExpiryDate 
        ? DateTime.now()
        : DateTime(1900);
    final DateTime lastDate = isExpiryDate 
        ? DateTime(2100)
        : DateTime.now();

    // Show calendar type selector
    final calendarType = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              widget.isArabic ? 'اختر نوع التقويم' : 'Select Calendar Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(widget.isArabic
                    ? 'التقويم الميلادي'
                    : 'Gregorian Calendar'),
                onTap: () => Navigator.pop(context, 'gregorian'),
              ),
              ListTile(
                title:
                    Text(widget.isArabic ? 'التقويم الهجري' : 'Hijri Calendar'),
                onTap: () => Navigator.pop(context, 'hijri'),
              ),
            ],
          ),
        );
      },
    );

    if (calendarType == null) return;

    setState(() => _isHijri = calendarType == 'hijri');

    if (_isHijri) {
      // Set locale for Hijri calendar
      HijriCalendar.setLocal(widget.isArabic ? 'ar' : 'en');

      // Show Hijri date picker
      final HijriCalendar? picked = await showHijriDatePicker(
        context: context,
        initialDate: HijriCalendar.fromDate(initialDate),
        lastDate: HijriCalendar.fromDate(lastDate),
        firstDate: HijriCalendar.fromDate(firstDate),
        initialDatePickerMode: DatePickerMode.day,
        locale: widget.isArabic
            ? const Locale('ar', 'SA')
            : const Locale('en', 'US'),
      );

      if (picked != null) {
        setState(() {
          if (isExpiryDate) {
            _selectedExpiryDate = picked.hijriToGregorian(picked.hYear, picked.hMonth, picked.hDay);
            _idExpiryController.text = widget.isArabic
                ? '${picked.hDay}/${picked.hMonth}/${picked.hYear} هـ'
                : '${picked.hDay}/${picked.hMonth}/${picked.hYear} H';
          } else {
            _selectedDate = picked.hijriToGregorian(picked.hYear, picked.hMonth, picked.hDay);
            _dobController.text = widget.isArabic
                ? '${picked.hDay}/${picked.hMonth}/${picked.hYear} هـ'
                : '${picked.hDay}/${picked.hMonth}/${picked.hYear} H';
          }
        });
      }
    } else {
      // Show Gregorian date picker
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Color(0xFF0077B6),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          if (isExpiryDate) {
            _selectedExpiryDate = picked;
            _idExpiryController.text = DateFormat('dd/MM/yyyy').format(picked);
          } else {
            _selectedDate = picked;
            _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
          }
        });
      }
    }
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime initialDate = DateTime.now();
    final DateTime firstDate = DateTime.now();
    final DateTime lastDate = DateTime(2100);

    if (_isHijri) {
      // Set locale for Hijri calendar
      HijriCalendar.setLocal(widget.isArabic ? 'ar' : 'en');

      // Show Hijri date picker
      final HijriCalendar? picked = await showHijriDatePicker(
        context: context,
        initialDate: HijriCalendar.fromDate(initialDate),
        lastDate: HijriCalendar.fromDate(lastDate),
        firstDate: HijriCalendar.fromDate(firstDate),
        initialDatePickerMode: DatePickerMode.day,
        locale: widget.isArabic
            ? const Locale('ar', 'SA')
            : const Locale('en', 'US'),
      );

      if (picked != null) {
        setState(() {
          _selectedExpiryDate = picked.hijriToGregorian(picked.hYear, picked.hMonth, picked.hDay);
          _idExpiryController.text = widget.isArabic
              ? '${picked.hDay}/${picked.hMonth}/${picked.hYear} هـ'
              : '${picked.hDay}/${picked.hMonth}/${picked.hYear} H';
        });
      }
    } else {
      // Show Gregorian date picker
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Color(0xFF0077B6),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          _selectedExpiryDate = picked;
          _idExpiryController.text = DateFormat('dd/MM/yyyy').format(picked);
        });
      }
    }
  }

  String _getArabicMonth(int month) {
    const months = [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الثاني',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة'
    ];
    return months[month - 1];
  }

  String _getEnglishMonth(int month) {
    const months = [
      'Muharram',
      'Safar',
      'Rabi Al-Awwal',
      'Rabi Al-Thani',
      'Jumada Al-Awwal',
      'Jumada Al-Thani',
      'Rajab',
      'Shaban',
      'Ramadan',
      'Shawwal',
      'Dhul Qadah',
      'Dhul Hijjah'
    ];
    return months[month - 1];
  }

  bool _validateAge(DateTime birthDate) {
    final DateTime today = DateTime.now();
    final int age = today.year - birthDate.year;
    if (age < 18) return false;
    if (age > 18) return true;
    if (today.month < birthDate.month) return false;
    if (today.month > birthDate.month) return true;
    return today.day >= birthDate.day;
  }

  void _handleLanguageChange(bool newIsArabic) {
    // This is a valid callback that satisfies the non-null requirement
    // We don't need to do anything here since we're navigating away
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    // Start the rotation animation
    _animationController.repeat();

    try {
      print('Starting registration process...');
      
      // 1. Validate identity first
      final validationResult = await _registrationService.validateIdentity(
        _nationalIdController.text,
        _phoneController.text,
      );

      print('Validation result: $validationResult');

      if (validationResult['status'] != 'success') {
        // Stop loading and animation before showing error
        _animationController.stop();
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              validationResult['message'] ?? 'Validation failed',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2. Generate and verify OTP
      final otpResult = await _registrationService.generateOTP(
        _nationalIdController.text,
        mobileNo: _phoneController.text,
      );
      
      print('OTP generation result: $otpResult');
      
      if (otpResult['status'] != 'success') {
        // Stop loading and animation before showing error
        _animationController.stop();
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              otpResult['message'] ?? 'Failed to generate OTP',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Stop loading and animation before showing OTP dialog
      _animationController.stop();
      setState(() => _isLoading = false);

      // Show OTP dialog
      final otpVerified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => OTPDialog(
          nationalId: _nationalIdController.text,
          onResendOTP: () async {
            // Show loading during resend
            setState(() => _isLoading = true);
            _animationController.repeat();
            
            final result = await _registrationService.generateOTP(
              _nationalIdController.text,
              mobileNo: _phoneController.text,
            );
            
            // Hide loading after resend
            _animationController.stop();
            setState(() => _isLoading = false);
            
            return result;
          },
          onVerifyOTP: (otp) => _registrationService.verifyOTP(_nationalIdController.text, otp),
          isArabic: widget.isArabic,
        ),
      );

      if (otpVerified != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic ? 'فشل التحقق من رمز التحقق' : 'OTP verification failed',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading for government data fetch
      setState(() => _isLoading = true);
      _animationController.repeat();

      // 3. Get Yakeen data
      final governmentData = await _registrationService.getGovernmentData(
        _nationalIdController.text,
        dateOfBirthHijri: _dobController.text,
        idExpiryDate: _idExpiryController.text,
      );

      if (governmentData['status'] != 'success') {
        throw Exception(governmentData['message']);
      }

      // 4. Store registration data locally
      await _registrationService.storeRegistrationData(
        nationalId: _nationalIdController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        userData: governmentData['data'],
      );

      // Stop loading before navigation
      _animationController.stop();
      setState(() => _isLoading = false);

      // 5. Navigate to password setup
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordSetupScreen(
              nationalId: _nationalIdController.text,
              isArabic: widget.isArabic,
            ),
          ),
        );
      }
    } catch (e) {
      print('Registration error: $e');
      // Stop loading and animation before showing error
      _animationController.stop();
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    final inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: Color(themeProvider.isDarkMode 
          ? Constants.darkFormBackgroundColor 
          : Constants.lightFormBackgroundColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Constants.formBorderRadius),
        borderSide: BorderSide(
          color: Color(themeProvider.isDarkMode 
              ? Constants.darkFormBorderColor 
              : Constants.lightFormBorderColor),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Constants.formBorderRadius),
        borderSide: BorderSide(
          color: Color(themeProvider.isDarkMode 
              ? Constants.darkFormBorderColor 
              : Constants.lightFormBorderColor),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Constants.formBorderRadius),
        borderSide: BorderSide(
          color: Color(themeProvider.isDarkMode 
              ? Constants.darkPrimaryColor 
              : Constants.lightPrimaryColor),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Constants.formBorderRadius),
        borderSide: BorderSide(
          color: Colors.red[300]!,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Constants.formBorderRadius),
        borderSide: BorderSide(
          color: Colors.red[300]!,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(
        color: Color(themeProvider.isDarkMode 
            ? Constants.darkLabelTextColor 
            : Constants.lightLabelTextColor),
      ),
      hintStyle: TextStyle(
        color: Color(themeProvider.isDarkMode 
            ? Constants.darkHintTextColor 
            : Constants.lightHintTextColor),
      ),
      prefixIconColor: Color(themeProvider.isDarkMode 
          ? Constants.darkIconColor 
          : Constants.lightIconColor),
    );

    return Directionality(
      textDirection:
          widget.isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Color(themeProvider.isDarkMode 
            ? Constants.darkBackgroundColor 
            : Constants.lightBackgroundColor),
        body: Stack(
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
                // Title with decoration
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Text(
                        widget.isArabic ? 'التسجيل' : 'Registration',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Color(themeProvider.isDarkMode 
                                  ? Constants.darkPrimaryColor 
                                  : Constants.lightPrimaryColor),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Color(themeProvider.isDarkMode 
                              ? Constants.darkPrimaryColor 
                              : Constants.lightPrimaryColor),
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
                          // National ID Field
                          Theme(
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: inputDecorationTheme,
                            ),
                            child: TextFormField(
                              controller: _nationalIdController,
                              decoration: InputDecoration(
                                labelText: widget.isArabic
                                    ? 'رقم الهوية الوطنية أو الإقامة'
                                    : 'National ID or IQAMA ID',
                                hintText: widget.isArabic
                                    ? 'أدخل رقم الهوية'
                                    : 'Enter National ID',
                                prefixIcon: Icon(Icons.credit_card,
                                    color: primaryColor),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return widget.isArabic
                                      ? 'رقم الهوية الوطنية أو الإقامة مطلوب'
                                      : 'National ID is required';
                                }
                                if (!RegExp(r'^[12]\d{9}$').hasMatch(value)) {
                                  return widget.isArabic
                                      ? 'يجب أن يكون رقم الهوية 10 أرقام ويبدأ بـ 1 أو 2'
                                      : 'ID must be 10 digits and start with 1 or 2';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Phone Number Field
                          Theme(
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: inputDecorationTheme,
                            ),
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: widget.isArabic
                                    ? 'رقم الجوال'
                                    : 'Mobile Number',
                                hintText: widget.isArabic
                                    ? 'أدخل رقم الجوال'
                                    : 'Enter mobile number',
                                hintTextDirection: ui.TextDirection.ltr,
                                suffixIcon: widget.isArabic
                                    ? Container(
                                        width: 50,
                                        alignment: Alignment.centerLeft,
                                        padding:
                                            const EdgeInsets.only(left: 8),
                                        child: Directionality(
                                          textDirection: ui.TextDirection.ltr,
                                          child: Text(
                                            '+966 ',
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      )
                                    : null,
                                prefixIcon: !widget.isArabic
                                    ? Icon(Icons.phone_android,
                                        color: primaryColor)
                                    : Icon(Icons.phone_android,
                                        color: primaryColor),
                                prefix: !widget.isArabic
                                    ? Text(
                                        '+966 ',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      )
                                    : null,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return widget.isArabic
                                      ? 'رقم الجوال مطلوب'
                                      : 'Mobile number is required';
                                }
                                if (!RegExp(r'^5\d{8}$').hasMatch(value)) {
                                  return widget.isArabic
                                      ? 'يجب أن يكون رقم الجوال 9 أرقام ويبدأ بـ 5'
                                      : 'Mobile number must be 9 digits and start with 5';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              textAlign: TextAlign.left,
                              textDirection: ui.TextDirection.ltr,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Date of Birth Field
                          Theme(
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: inputDecorationTheme,
                            ),
                            child: TextFormField(
                              controller: _dobController,
                              decoration: InputDecoration(
                                labelText: widget.isArabic
                                    ? 'تاريخ الميلاد'
                                    : 'Date of Birth',
                                hintText: widget.isArabic
                                    ? 'اختر تاريخ الميلاد'
                                    : 'Select date of birth',
                                prefixIcon: Icon(Icons.calendar_today,
                                    color: primaryColor),
                              ),
                              readOnly: true,
                              onTap: () async {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    int selectedTabIndex = 0;
                                    // Initialize temp date
                                    _tempSelectedDate = _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18));
                                    return Dialog(
                                      backgroundColor: themeProvider.isDarkMode 
                                          ? Colors.grey[900]
                                          : Color(Constants.lightFormBackgroundColor),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)
                                      ),
                                      child: DefaultTabController(
                                        length: 2,
                                        child: StatefulBuilder(
                                          builder: (context, setState) => Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TabBar(
                                                onTap: (index) {
                                        setState(() {
                                                    selectedTabIndex = index;
                                        });
                                      },
                                                tabs: [
                                                  Tab(text: widget.isArabic ? 'هجري' : 'Hijri'),
                                                  Tab(text: widget.isArabic ? 'ميلادي' : 'Gregorian'),
                                                ],
                                                labelColor: primaryColor,
                                                unselectedLabelColor: Color(themeProvider.isDarkMode 
                                                    ? Constants.darkLabelTextColor 
                                                    : Constants.lightLabelTextColor),
                                                indicatorColor: primaryColor,
                                              ),
                                              const SizedBox(height: 20),
                                              SizedBox(
                                                height: 200,
                                                child: TabBarView(
                                                  children: [
                                                    // Hijri Calendar
                                                    Builder(
                                                      builder: (context) {
                                                        final now = HijriCalendar.now();
                                                        return CustomHijriPicker(
                                                          isArabic: widget.isArabic,
                                                          minYear: now.hYear - 90,
                                                          maxYear: now.hYear,
                                                          initialYear: now.hYear - 18,
                                                          primaryColor: primaryColor,
                                                          isDarkMode: themeProvider.isDarkMode,
                                                          onDateSelected: (day, month, year) {
                                                            print('Selected Hijri Date: $day/$month/$year');
                                                            // Convert to Gregorian for storage
                                                            final hijri = HijriCalendar()
                                                              ..hYear = year
                                                              ..hMonth = month
                                                              ..hDay = day;
                                                            final gregorian = hijri.hijriToGregorian(year, month, day);
                                                            setState(() {
                                                              _tempSelectedDate = gregorian;
                                                            });
                                                          },
                                                        );
                                                      }
                                                    ),
                                                    // Gregorian Calendar
                                                    Builder(
                                                      builder: (context) {
                                                        return DatePickerWidget(
                                                          looping: true,
                                                          firstDate: DateTime(1900),
                                                          lastDate: DateTime.now(),
                                                          initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
                                                          dateFormat: "dd/MM/yyyy",
                                                          locale: widget.isArabic ? DateTimePickerLocale.ar : DateTimePickerLocale.en_us,
                                                          pickerTheme: DateTimePickerTheme(
                                                            backgroundColor: Colors.transparent,
                                                            itemTextStyle: TextStyle(
                                                              color: Color(themeProvider.isDarkMode 
                                                                  ? Constants.darkLabelTextColor 
                                                                  : Constants.lightLabelTextColor),
                                                              fontSize: 18,
                                                            ),
                                                            dividerColor: primaryColor,
                                                          ),
                                                          onChange: (DateTime newDate, _) {
                                                            setState(() {
                                                              _tempSelectedDate = newDate;
                                                            });
                                                          },
                                                        );
                                                      }
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    TextButton(
                                                      onPressed: () => Navigator.of(context).pop(),
                                                      child: Text(
                                                        widget.isArabic ? 'إلغاء' : 'Cancel',
                                                        style: TextStyle(
                                                          color: Color(themeProvider.isDarkMode 
                                                              ? Constants.darkLabelTextColor 
                                                              : Constants.lightLabelTextColor),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    TextButton(
                                                      onPressed: () {
                                                        if (_tempSelectedDate != null) {
                                                          final isHijri = selectedTabIndex == 0;
                                                          if (isHijri) {
                                                            final hijri = HijriCalendar.fromDate(_tempSelectedDate!);
                                                            setState(() {
                                                              _selectedDate = _tempSelectedDate;
                                          _dobController.text = widget.isArabic
                                                                  ? '${hijri.hDay}/${hijri.hMonth}/${hijri.hYear} هـ'
                                                                  : '${hijri.hDay}/${hijri.hMonth}/${hijri.hYear} H';
                                                            });
                                                          } else {
                                                            setState(() {
                                                              _selectedDate = _tempSelectedDate;
                                                              _dobController.text = DateFormat('dd/MM/yyyy').format(_tempSelectedDate!);
                                                            });
                                                          }
                                                        }
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: Text(
                                                        widget.isArabic ? 'موافق' : 'OK',
                                                        style: TextStyle(
                                                          color: primaryColor,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return widget.isArabic
                                      ? 'تاريخ الميلاد مطلوب'
                                      : 'Date of birth is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ID Expiry Field
                          Theme(
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: inputDecorationTheme,
                            ),
                            child: TextFormField(
                              controller: _idExpiryController,
                              decoration: InputDecoration(
                                labelText: widget.isArabic
                                    ? 'تاريخ انتهاء الهوية'
                                    : 'ID Expiry Date',
                                hintText: widget.isArabic
                                    ? 'أدخل تاريخ انتهاء الهوية'
                                    : 'Enter ID Expiry Date',
                                prefixIcon: Icon(Icons.calendar_today,
                                    color: primaryColor),
                              ),
                              readOnly: true,
                              onTap: () async {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    int selectedTabIndex = 0;
                                    // Initialize temp date
                                    _tempSelectedExpiryDate = _selectedExpiryDate ?? DateTime.now();
                                    return Dialog(
                                      backgroundColor: themeProvider.isDarkMode 
                                          ? Colors.grey[900]
                                          : Color(Constants.lightFormBackgroundColor),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)
                                      ),
                                      child: DefaultTabController(
                                        length: 2,
                                        child: StatefulBuilder(
                                          builder: (context, setState) => Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TabBar(
                                                onTap: (index) {
                                        setState(() {
                                                    selectedTabIndex = index;
                                        });
                                      },
                                                tabs: [
                                                  Tab(text: widget.isArabic ? 'هجري' : 'Hijri'),
                                                  Tab(text: widget.isArabic ? 'ميلادي' : 'Gregorian'),
                                                ],
                                                labelColor: primaryColor,
                                                unselectedLabelColor: Color(themeProvider.isDarkMode 
                                                    ? Constants.darkLabelTextColor 
                                                    : Constants.lightLabelTextColor),
                                                indicatorColor: primaryColor,
                                              ),
                                              const SizedBox(height: 20),
                                              SizedBox(
                                                height: 200,
                                                child: TabBarView(
                                                  children: [
                                                    // Hijri Calendar for ID Expiry
                                                    Builder(
                                                      builder: (context) {
                                                        final now = HijriCalendar.now();
                                                        return CustomHijriPicker(
                                                          isArabic: widget.isArabic,
                                                          minYear: now.hYear,
                                                          maxYear: now.hYear + 10,
                                                          initialYear: now.hYear,
                                                          primaryColor: primaryColor,
                                                          isDarkMode: themeProvider.isDarkMode,
                                                          onDateSelected: (day, month, year) {
                                                            print('Selected Hijri Date: $day/$month/$year');
                                                            // Convert to Gregorian for storage
                                                            final hijri = HijriCalendar()
                                                              ..hYear = year
                                                              ..hMonth = month
                                                              ..hDay = day;
                                                            final gregorian = hijri.hijriToGregorian(year, month, day);
                                                            setState(() {
                                                              _tempSelectedExpiryDate = gregorian;
                                                            });
                                                          },
                                                        );
                                                      }
                                                    ),
                                                    // Gregorian Calendar for ID Expiry
                                                    Builder(
                                                      builder: (context) {
                                                        return DatePickerWidget(
                                                          looping: true,
                                                          firstDate: DateTime.now(),
                                                          lastDate: DateTime(2100),
                                                          initialDate: _selectedExpiryDate ?? DateTime.now(),
                                                          dateFormat: "dd/MM/yyyy",
                                                          locale: widget.isArabic ? DateTimePickerLocale.ar : DateTimePickerLocale.en_us,
                                                          pickerTheme: DateTimePickerTheme(
                                                            backgroundColor: Colors.transparent,
                                                            itemTextStyle: TextStyle(
                                                              color: Color(themeProvider.isDarkMode 
                                                                  ? Constants.darkLabelTextColor 
                                                                  : Constants.lightLabelTextColor),
                                                              fontSize: 18,
                                                            ),
                                                            dividerColor: primaryColor,
                                                          ),
                                                          onChange: (DateTime newDate, _) {
                                                            setState(() {
                                                              _tempSelectedExpiryDate = newDate;
                                                            });
                                                          },
                                                        );
                                                      }
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    TextButton(
                                                      onPressed: () => Navigator.of(context).pop(),
                                                      child: Text(
                                                        widget.isArabic ? 'إلغاء' : 'Cancel',
                                                        style: TextStyle(
                                                          color: Color(themeProvider.isDarkMode 
                                                              ? Constants.darkLabelTextColor 
                                                              : Constants.lightLabelTextColor),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    TextButton(
                                                      onPressed: () {
                                                        if (_tempSelectedExpiryDate != null) {
                                                          final isHijri = selectedTabIndex == 0;
                                                          if (isHijri) {
                                                            final hijri = HijriCalendar.fromDate(_tempSelectedExpiryDate!);
                                                            setState(() {
                                                              _selectedExpiryDate = _tempSelectedExpiryDate;
                                          _idExpiryController.text = widget.isArabic
                                                                  ? '${hijri.hDay}/${hijri.hMonth}/${hijri.hYear} هـ'
                                                                  : '${hijri.hDay}/${hijri.hMonth}/${hijri.hYear} H';
                                                            });
                                                          } else {
                                                            setState(() {
                                                              _selectedExpiryDate = _tempSelectedExpiryDate;
                                                              _idExpiryController.text = DateFormat('dd/MM/yyyy').format(_tempSelectedExpiryDate!);
                                                            });
                                                          }
                                                        }
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: Text(
                                                        widget.isArabic ? 'موافق' : 'OK',
                                                        style: TextStyle(
                                                          color: primaryColor,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return widget.isArabic
                                      ? 'تاريخ انتهاء الهوية مطلوب'
                                      : 'ID Expiry Date is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Email Field
                          Theme(
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: inputDecorationTheme,
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: widget.isArabic
                                    ? 'البريد الإلكتروني'
                                    : 'Email',
                                hintText: widget.isArabic
                                    ? 'أدخل البريد الإلكتروني'
                                    : 'Enter email',
                                prefixIcon: Icon(Icons.email_outlined,
                                    color: primaryColor),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return widget.isArabic
                                      ? 'البريد الإلكتروني مطلوب'
                                      : 'Email is required';
                                }
                                if (!RegExp(
                                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return widget.isArabic
                                      ? 'البريد الإلكتروني غير صحيح'
                                      : 'Invalid email format';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.emailAddress,
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
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkSurfaceColor 
                        : Constants.lightSurfaceColor),
                    boxShadow: [
                      BoxShadow(
                        color: Color(themeProvider.isDarkMode 
                            ? Constants.darkNavbarShadowPrimary
                            : Constants.lightNavbarShadowPrimary),
                        offset: const Offset(0, -2),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Color(themeProvider.isDarkMode 
                            ? Constants.darkNavbarShadowSecondary
                            : Constants.lightNavbarShadowSecondary),
                        offset: const Offset(0, -1),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(themeProvider.isDarkMode 
                                ? Constants.darkFormBackgroundColor
                                : Constants.lightFormBackgroundColor),
                            foregroundColor: Color(themeProvider.isDarkMode 
                                ? Constants.darkLabelTextColor 
                                : Constants.lightLabelTextColor),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
                              side: BorderSide(
                                color: Color(themeProvider.isDarkMode 
                                    ? Constants.darkFormBorderColor 
                                    : Constants.lightFormBorderColor),
                              ),
                            ),
                          ),
                          child: Text(
                            widget.isArabic ? 'إلغاء' : 'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(themeProvider.isDarkMode 
                                  ? Constants.darkLabelTextColor 
                                  : Constants.lightLabelTextColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegistration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(themeProvider.isDarkMode 
                                ? Constants.darkPrimaryColor 
                                : Constants.lightPrimaryColor),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        themeProvider.isDarkMode ? Colors.black : Colors.white),
                                  ),
                                )
                              : Text(
                                  widget.isArabic ? 'التالي' : 'Next',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: themeProvider.isDarkMode ? Colors.black : Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RotationTransition(
                        turns: CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.linear,
                        ),
                        child: Image.asset(
                          themeProvider.isDarkMode
                              ? 'assets/images/nayifat-circle-grey.png'
                              : 'assets/images/nayifatlogocircle-nobg.png',
                          width: 100,
                          height: 100,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.isArabic ? 'جاري المعالجة...' : 'Processing...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
