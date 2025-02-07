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
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

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
  final TextEditingController _sponsorIdController = TextEditingController();
  final AuthService _authService = AuthService();
  final RegistrationService _registrationService = RegistrationService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'SA');
  DateTime? _selectedDate;
  DateTime? _selectedExpiryDate;
  DateTime? _tempSelectedDate;
  DateTime? _tempSelectedExpiryDate;
  bool _isLoading = false;
  bool _isHijri = true; // Default to Hijri as per Saudi standards
  String? _errorMessage;
  late final AnimationController _animationController;
  bool _termsAccepted = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  bool _isExpat = false;

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

    // 💡 Add listener to national ID field
    _nationalIdController.addListener(_checkIfExpat);
  }

  // 💡 Check if the user is an expat based on national ID
  void _checkIfExpat() {
    if (_nationalIdController.text.isNotEmpty) {
      setState(() {
        _isExpat = _nationalIdController.text.startsWith('2');
      });
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      if (sdkInt >= 33) {
        // Android 13 and above
        final photos = await Permission.photos.request();
        return photos.isGranted;
      } else {
        // Android 12 and below
        final storage = await Permission.storage.request();
        return storage.isGranted;
      }
    } else if (Platform.isIOS) {
      return true; // iOS doesn't require explicit permission for downloads
    }
    return false;
  }

  Future<void> _downloadPdf(String type, String url) async {
    if (_isDownloading) return;

    try {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        Navigator.of(context).pop(); // Close popup first
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isArabic 
                  ? 'يرجى منح الإذن للتطبيق للوصول إلى وحدة التخزين لتنزيل الملف'
                  : 'Please grant storage permission to download the file'
              ),
              action: SnackBarAction(
                label: widget.isArabic ? 'الإعدادات' : 'Settings',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        _isDownloading = true;
        _downloadProgress = 0;
      });

      final fileName = type == 'terms' 
          ? (widget.isArabic ? 'الشروط-والأحكام.pdf' : 'terms-and-conditions.pdf')
          : (widget.isArabic ? 'سياسة-الخصوصية.pdf' : 'privacy-policy.pdf');

      final directory = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final savePath = '${directory.path}/$fileName';
      final dio = Dio();

      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
        _downloadProgress = 0;
      });

      Navigator.of(context).pop(); // Close popup first
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic 
                ? 'تم تحميل الملف بنجاح إلى ${directory.path}'
                : 'File downloaded successfully to ${directory.path}'
            ),
            duration: Duration(seconds: 5),
            action: Platform.isAndroid ? SnackBarAction(
              label: widget.isArabic ? 'فتح المجلد' : 'Open Folder',
              onPressed: () async {
                final uri = Uri.parse('content://com.android.externalstorage.documents/document/primary%3ADownload');
                await launchUrl(uri);
              },
            ) : SnackBarAction(
              label: widget.isArabic ? 'عرض' : 'View',
              onPressed: () async {
                final uri = Uri.file(savePath);
                await launchUrl(uri);
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0;
      });
      
      Navigator.of(context).pop(); // Close popup first
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            widget.isArabic 
              ? 'فشل تحميل الملف: $e'
              : 'Failed to download file: $e'
          )),
        );
      }
    }
  }

  Future<void> _openPdf(String type) async {
    String url = type == 'terms' 
      ? 'https://icreditdept.com/api/terms.pdf'
      : 'https://icreditdept.com/api/privacy.pdf';
    
    try {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              insetPadding: EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              type == 'terms' 
                                ? (widget.isArabic ? 'الشروط والأحكام' : 'Terms & Conditions')
                                : (widget.isArabic ? 'سياسة الخصوصية' : 'Privacy Policy'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_isDownloading)
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                value: _downloadProgress,
                                strokeWidth: 2,
                              ),
                            )
                          else
                            IconButton(
                              icon: Icon(Icons.download),
                              onPressed: () => _downloadPdf(type, url),
                              tooltip: widget.isArabic ? 'تحميل' : 'Download',
                            ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: widget.isArabic ? 'إغلاق' : 'Close',
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1),
                    Expanded(
                      child: SfPdfViewer.network(
                        url,
                        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not load $type document: ${details.error}')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening $type document: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nationalIdController.removeListener(_checkIfExpat);
    _nationalIdController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _idExpiryController.dispose();
    _emailController.dispose();
    _sponsorIdController.dispose();
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

    // 💡 Validate sponsor ID for expats
    if (_isExpat && _sponsorIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic 
              ? 'رقم الكفيل مطلوب للمقيمين'
              : 'Sponsor ID is required for expats'
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 💡 Convert dates to Hijri format for API (using hyphens instead of slashes)
    String dobHijri = '';
    String expiryHijri = '';
    
    if (_selectedDate != null) {
      if (!_isHijri) {
        // Convert Gregorian to Hijri
        final hijri = HijriCalendar.fromDate(_selectedDate!);
        dobHijri = '${hijri.hYear}-${hijri.hMonth.toString().padLeft(2, '0')}-${hijri.hDay.toString().padLeft(2, '0')}';
        print('💡 Converted DOB from Gregorian to Hijri: $dobHijri');
      } else {
        // Already in Hijri format, just parse from the text
        final parts = _dobController.text.split('/');
        if (parts.length >= 3) {
          final day = parts[0];
          final month = parts[1];
          final year = parts[2].split(' ')[0]; // Remove the 'H' or 'هـ' suffix
          dobHijri = '$year-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}';
          print('💡 Parsed DOB from Hijri text: $dobHijri');
        }
      }
    }
    
    if (_selectedExpiryDate != null) {
      if (!_isHijri) {
        // Convert Gregorian to Hijri
        final hijri = HijriCalendar.fromDate(_selectedExpiryDate!);
        expiryHijri = '${hijri.hYear}-${hijri.hMonth.toString().padLeft(2, '0')}-${hijri.hDay.toString().padLeft(2, '0')}';
        print('💡 Converted Expiry from Gregorian to Hijri: $expiryHijri');
      } else {
        // Already in Hijri format, just parse from the text
        final parts = _idExpiryController.text.split('/');
        if (parts.length >= 3) {
          final day = parts[0];
          final month = parts[1];
          final year = parts[2].split(' ')[0]; // Remove the 'H' or 'هـ' suffix
          expiryHijri = '$year-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}';
          print('💡 Parsed Expiry from Hijri text: $expiryHijri');
        }
      }
    }

    // 💡 Check terms acceptance
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic 
              ? 'يجب الموافقة على الشروط والأحكام وسياسة الخصوصية للمتابعة'
              : 'You must agree to the Terms & Conditions and Privacy Policy to continue'
          ),
          backgroundColor: Colors.red,
        ),
      );
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

      // 💡 3. Get expat info and address if applicable
      Map<String, dynamic>? expatInfo;
      Map<String, dynamic>? expatAddress;
      
      if (_isExpat) {
        setState(() => _isLoading = true);
        _animationController.repeat();

        // Get expat info
        expatInfo = await _registrationService.getExpatInfo(
          _nationalIdController.text,
          _sponsorIdController.text,
        );

        if (expatInfo['status'] != 'success') {
          _animationController.stop();
          setState(() => _isLoading = false);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                expatInfo['message'] ?? 'Failed to get expat information',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Get expat address
        expatAddress = await _registrationService.getExpatAddress(
          _nationalIdController.text,
          dobHijri,
          addressLanguage: widget.isArabic ? 'A' : 'E',
        );

        if (expatAddress['status'] != 'success') {
          _animationController.stop();
          setState(() => _isLoading = false);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                expatAddress['message'] ?? 'Failed to get expat address',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Stop loading before navigation
      _animationController.stop();
      setState(() => _isLoading = false);

      // 💡 Navigate to password setup with essential data only
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordSetupScreen(
              nationalId: _nationalIdController.text,
              email: _emailController.text,
              phone: _phoneController.text,
              dateOfBirthHijri: dobHijri,
              idExpiryDateHijri: expiryHijri,
              isArabic: widget.isArabic,
              sponsorId: _isExpat ? _sponsorIdController.text : null,
              expatInfo: _isExpat && expatInfo != null ? expatInfo['data'] as Map<String, dynamic> : null,
              expatAddress: _isExpat && expatAddress != null ? expatAddress['data'] as Map<String, dynamic> : null,
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

                          // 💡 Sponsor ID Field (only visible for expats)
                          if (_isExpat)
                            Theme(
                              data: Theme.of(context).copyWith(
                                inputDecorationTheme: inputDecorationTheme,
                              ),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _sponsorIdController,
                                    decoration: InputDecoration(
                                      labelText: widget.isArabic
                                          ? 'رقم الكفيل'
                                          : 'Sponsor ID',
                                      hintText: widget.isArabic
                                          ? 'أدخل رقم الكفيل'
                                          : 'Enter Sponsor ID',
                                      prefixIcon: Icon(Icons.business,
                                          color: primaryColor),
                                    ),
                                    validator: (value) {
                                      if (_isExpat && (value == null || value.isEmpty)) {
                                        return widget.isArabic
                                            ? 'رقم الكفيل مطلوب للمقيمين'
                                            : 'Sponsor ID is required for expats';
                                      }
                                      if (value != null && value.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(value)) {
                                        return widget.isArabic
                                            ? 'يجب أن يكون رقم الكفيل 10 أرقام'
                                            : 'Sponsor ID must be 10 digits';
                                      }
                                      return null;
                                    },
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),

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

                          // 💡 Email Field moved here, after phone
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

                          // 💡 Terms and Conditions with modern styling
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Color(themeProvider.isDarkMode 
                                  ? Constants.darkSurfaceColor 
                                  : Constants.lightSurfaceColor),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(themeProvider.isDarkMode 
                                      ? Constants.darkPrimaryColor 
                                      : Constants.lightPrimaryColor).withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Directionality(
                              textDirection: widget.isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                              child: Row(
                                mainAxisAlignment: widget.isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                                children: [
                                  Transform.scale(
                                    scale: 1.2,
                                    child: Checkbox(
                                      value: _termsAccepted,
                                      onChanged: (value) {
                                        setState(() => _termsAccepted = value ?? false);
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      activeColor: Color(themeProvider.isDarkMode 
                                          ? Constants.darkPrimaryColor 
                                          : Constants.lightPrimaryColor),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      alignment: widget.isArabic ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Wrap(
                                        alignment: widget.isArabic ? WrapAlignment.end : WrapAlignment.start,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            widget.isArabic ? 'أوافق على ' : 'I agree to the ',
                                            textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                                            style: TextStyle(
                                              color: Color(themeProvider.isDarkMode 
                                                  ? Constants.darkLabelTextColor 
                                                  : Constants.lightLabelTextColor),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _openPdf('terms'),
                                            child: Text(
                                              widget.isArabic ? 'الشروط والأحكام' : 'Terms & Conditions',
                                              textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                                              style: TextStyle(
                                                color: Color(themeProvider.isDarkMode 
                                                    ? Constants.darkPrimaryColor 
                                                    : Constants.lightPrimaryColor),
                                                decoration: TextDecoration.underline,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            widget.isArabic ? ' و ' : ' and ',
                                            textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                                            style: TextStyle(
                                              color: Color(themeProvider.isDarkMode 
                                                  ? Constants.darkLabelTextColor 
                                                  : Constants.lightLabelTextColor),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _openPdf('privacy'),
                                            child: Text(
                                              widget.isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
                                              textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                                              style: TextStyle(
                                                color: Color(themeProvider.isDarkMode 
                                                    ? Constants.darkPrimaryColor 
                                                    : Constants.lightPrimaryColor),
                                                decoration: TextDecoration.underline,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
