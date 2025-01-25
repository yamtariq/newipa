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

class _InitialRegistrationScreenState extends State<InitialRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final RegistrationService _registrationService = RegistrationService();
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'SA');
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isHijri = false;
  String? _errorMessage;

  final List<String> _stepsEn = ['Basic', 'Password', 'MPIN'];

  final List<String> _stepsAr = ['معلومات', 'كلمة المرور', 'رمز الدخول'];

  @override
  void dispose() {
    _nationalIdController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _emailController.dispose();
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime initialDate =
        DateTime.now().subtract(const Duration(days: 365 * 18));
    final DateTime firstDate = DateTime(1900);
    final DateTime lastDate = DateTime.now();

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
        lastDate: HijriCalendar.fromDate(DateTime.now()),
        firstDate: HijriCalendar.fromDate(
            DateTime.now().subtract(const Duration(days: 365 * 75))),
        initialDatePickerMode: DatePickerMode.day,
        locale: widget.isArabic
            ? const Locale('ar', 'SA')
            : const Locale('en', 'US'),
      );

      if (picked != null) {
        setState(() {
          _selectedDate =
              picked.hijriToGregorian(picked.hYear, picked.hMonth, picked.hDay);
          _dobController.text = widget.isArabic
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
          _selectedDate = picked;
          _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
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

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Check if user is already registered
      final registrationCheck = await _registrationService.checkRegistration(
        _nationalIdController.text,
      );

      print('Registration check response: $registrationCheck');

      // Check if user is already registered before proceeding with Nafath
      if (registrationCheck['status'] == 'error') {
        if (registrationCheck['message'] == 'This ID already registered' ||
            registrationCheck['message']?.contains('already registered') == true) {
          // Show dialog to sign in
          if (!mounted) return;
          final result = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 100,
                    child: Lottie.asset(
                      'assets/animations/caution.json',
                      repeat: true,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isArabic
                        ? 'هذه الهوية/الإقامة مسجلة بالفعل. هل تريد تسجيل الدخول إلى حسابك؟'
                        : 'This National/Iqama ID is already registered. Would you like to sign in to your account?',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    widget.isArabic ? 'إلغاء' : 'Cancel',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0077B6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    widget.isArabic ? 'تسجيل الدخول' : 'Sign In',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          );

          if (result == true) {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SignInScreen(
                  isArabic: widget.isArabic,
                  nationalId: _nationalIdController.text,
                  startWithPassword: true,
                ),
              ),
            );
          }
          return;
        } else {
          throw Exception(registrationCheck['message'] ?? 'Registration check failed');
        }
      }

      // Step 2: Show Nafath verification dialog
      if (!mounted) return;
      final nafathResult = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => NafathVerificationDialog(
          nationalId: _nationalIdController.text,
          isArabic: widget.isArabic,
          onCancel: () {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );

      if (nafathResult == null || nafathResult['verified'] != true) {
        throw Exception(widget.isArabic
            ? 'فشل التحقق من نفاذ'
            : 'Nafath verification failed');
      }

      // Store Nafath verification data
      final nafathData = {
        'transId': nafathResult['transId'],
        'random': nafathResult['random'],
        'response': nafathResult['response'],
      };

      // Step 3: Get government data
      final govData = await _registrationService.getGovernmentData(
        _nationalIdController.text,
      );

      if (govData['status'] != 'success') {
        throw Exception(widget.isArabic
            ? 'عذراً، التسجيل غير متاح حالياً'
            : 'Sorry, registration is not possible at this time');
      }

      // Store data locally with Nafath verification
      await _registrationService.storeRegistrationData(
        nationalId: _nationalIdController.text,
        email: _emailController.text.trim(),
        phone: _phoneController.text,
        userData: govData['data'],
        nafathData: nafathData,
      );

      // Navigate to password setup using pushReplacement to prevent going back
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PasswordSetupScreen(
            nationalId: _nationalIdController.text,
            isArabic: widget.isArabic,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                                onTap: () => _selectDate(context),
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
                            onPressed: _isLoading ? null : _handleNext,
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
            ],
          ),
        ),
      ),
    );
  }
}
