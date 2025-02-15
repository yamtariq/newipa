import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth/mpin_setup_screen.dart';
import 'auth/sign_in_screen.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'customer_service_screen.dart';
import 'cards_page.dart';
import 'loans_page.dart';
import 'cards_page_ar.dart';
import 'loans_page_ar.dart';
import '../screens/main_page.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../widgets/otp_dialog.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'splash_screen.dart';
import '../screens/main_page.dart';
import '../utils/constants.dart';
import '../services/theme_service.dart';
import 'auth/forget_password_screen.dart';

class AccountPage extends StatefulWidget {
  final bool isArabic;
  const AccountPage({super.key, this.isArabic = false});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final AuthService _authService = AuthService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  String _userName = '';
  bool _isBiometricsEnabled = false;
  bool _isBiometricsAvailable = false;
  String _biometricsError = '';
  String _currentLanguage = 'English';
  bool _isLoading = true;
  bool _isSignedIn = false;
  int _tabIndex = 4;  // For Account tab (settings)

  // Add ThemeProvider getter
  ThemeProvider get themeProvider => Provider.of<ThemeProvider>(context, listen: false);

  double get screenHeight => MediaQuery.of(context).size.height;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkBiometricsAvailability();
    _checkSignInStatus();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? '';
      final nationalId = prefs.getString('national_id') ?? '';
      final isBiometricsEnabled = prefs.getBool('biometrics_enabled_$nationalId') ?? false;

      setState(() {
        _userName = userName;
        _isBiometricsEnabled = isBiometricsEnabled;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkBiometricsAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
      final List<BiometricType> availableBiometrics = 
          await _localAuth.getAvailableBiometrics();
      
      setState(() {
        _isBiometricsAvailable = isAvailable && availableBiometrics.isNotEmpty;
        if (!_isBiometricsAvailable) {
          _biometricsError = widget.isArabic 
              ? 'السمات الحيوية غير متوفرة على هذا الجهاز'
              : 'Biometric authentication is not available on this device';
        }
      });
    } catch (e) {
      setState(() {
        _isBiometricsAvailable = false;
        _biometricsError = widget.isArabic 
            ? 'حدث خطأ أثناء التحقق من توفر السمات الحيوية'
            : 'Error checking biometric availability';
      });
    }
  }

  Future<void> _checkSignInStatus() async {
    final isSignedIn = await _authService.isSessionActive();
    setState(() {
      _isSignedIn = isSignedIn;
    });
  }

  Future<void> _toggleBiometrics() async {
    if (!_isBiometricsAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _biometricsError,
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.black : Colors.white,
            ),
          ),
          backgroundColor: themeProvider.primaryColor,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final nationalId = prefs.getString('national_id') ?? '';
      
      if (_isBiometricsEnabled) {
        // Verify biometrics before disabling
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: widget.isArabic 
              ? 'يرجى الموافقة لتعطيل المصادقة بالسمات الحيوية'
              : 'Please authenticate to disable biometric login',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (!didAuthenticate) return;

        // Clear biometric status from SharedPreferences
        await prefs.remove('biometrics_enabled_$nationalId');
        await prefs.remove('biometrics_enabled'); // Clear old key too
        setState(() => _isBiometricsEnabled = false);
      } else {
        // Enable biometrics
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: widget.isArabic 
              ? 'يرجى الموافقة لتمكين المصادقة بالسمات الحيوية'
              : 'Please authenticate to enable biometric login',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (!didAuthenticate) return;

        try {
          await _authService.enableBiometric(nationalId);
          await prefs.setBool('biometrics_enabled_$nationalId', true);
          setState(() => _isBiometricsEnabled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isArabic 
                    ? 'تم تفعيل المصادقة بالسمات الحيوية بنجاح'
                    : 'Biometric authentication enabled successfully',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } catch (e) {
          print('Error enabling biometrics: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isArabic 
                    ? 'حدث خطأ أثناء تفعيل المصادقة بالسمات الحيوية'
                    : 'Error enabling biometric authentication',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic 
                ? 'حدث خطأ أثناء تحديث إعدادات المصادقة بالسمات الحيوية'
                : 'Error updating biometric settings',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _changeMPIN() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nationalId = prefs.getString('national_id') ?? '';
      final password = prefs.getString('password') ?? '';
      
      // First verify current MPIN before allowing change
      bool? shouldProceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final themeProvider = Provider.of<ThemeProvider>(context);
          final textColor = themeProvider.primaryColor;
          
          return AlertDialog(
            backgroundColor: themeProvider.surfaceColor,
            title: Text(
              widget.isArabic ? 'تغيير رمز الدخول' : 'Change MPIN',
              textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              widget.isArabic 
                  ? 'هل أنت متأكد أنك تريد تغيير رمز الدخول الخاص بك؟'
                  : 'Are you sure you want to change your MPIN?',
              textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                color: textColor,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  widget.isArabic ? 'إلغاء' : 'Cancel',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  widget.isArabic ? 'متابعة' : 'Continue',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (shouldProceed != true || !mounted) return;

      // Verify biometrics if enabled
      if (_isBiometricsEnabled && _isBiometricsAvailable) {
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: widget.isArabic 
              ? 'يرجى المصادقة لتغيير رمز الدخول'
              : 'Please authenticate to change MPIN',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (!didAuthenticate || !mounted) return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MPINSetupScreen(
            nationalId: nationalId,
            password: password,
            isArabic: widget.isArabic,
            isChangingMPIN: true,  // Add this flag to MPINSetupScreen
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic 
                ? 'حدث خطأ أثناء تغيير رمز الدخول'
                : 'Error changing MPIN',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.black : Colors.white,
            ),
          ),
          backgroundColor: themeProvider.primaryColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForgetPasswordScreen(
          isArabic: widget.isArabic,
        ),
      ),
    );
  }

  void _toggleLanguage() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final textColor = themeProvider.primaryColor;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeProvider.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: themeProvider.primaryColor,
            ),
          ),
          title: Column(
            children: [
              Text(
                'Change Language',
                style: TextStyle(
                  color: themeProvider.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'تغيير اللغة',
                style: TextStyle(
                  color: themeProvider.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isArabic 
                    ? 'Are you sure you want to change the language to English?'
                    : 'Are you sure you want to change the language to Arabic?',
                style: TextStyle(
                  fontSize: 16,
                  color: themeProvider.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isArabic 
                    ? 'هل أنت متأكد أنك تريد تغيير اللغة إلى الإنجليزية؟'
                    : 'هل أنت متأكد أنك تريد تغيير اللغة إلى العربية؟',
                style: TextStyle(
                  fontSize: 16,
                  color: themeProvider.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Column(
                        children: [
                          Text(
                            'Cancel',
                            style: TextStyle(
                              color: themeProvider.primaryColor.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'إلغاء',
                            style: TextStyle(
                              color: themeProvider.primaryColor.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('isArabic', !widget.isArabic);
                        
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MainPage(
                              isArabic: !widget.isArabic,
                              onLanguageChanged: (bool value) {},
                              userData: const {},
                              isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Text(
                            'Confirm',
                            style: TextStyle(
                              color: themeProvider.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'تأكيد',
                            style: TextStyle(
                              color: themeProvider.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    try {
      print('\n=== SIGN OFF SEQUENCE START ===');
      print('1. Sign Off button clicked');

      final prefs = await SharedPreferences.getInstance();
      final nationalId = prefs.getString('national_id') ?? '';

      // Call the complete signOut method
      print('2. Calling AuthService.signOut()');
      await _authService.signOut();
      print('3. AuthService.signOut() completed');

      if (!mounted) return;
      
      print('4. Navigating to MainPage');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainPage(
            isArabic: widget.isArabic,
            onLanguageChanged: (bool value) {},
            userData: const {},
            isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
          ),
        ),
      );
      print('5. Sign Off sequence completed successfully');
      print('=== SIGN OFF SEQUENCE END ===\n');
    } catch (e) {
      print('ERROR in Sign Off sequence: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic 
                ? 'حدث خطأ أثناء تسجيل الخروج'
                : 'Error signing off: ${e.toString()}',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.black : Colors.white,
            ),
          ),
          backgroundColor: themeProvider.primaryColor,
        ),
      );
    }
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Color(themeProvider.isDarkMode 
            ? Constants.darkFormBackgroundColor
            : Constants.lightFormBackgroundColor),
        borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
        border: Border.all(
          color: Color(themeProvider.isDarkMode 
              ? Constants.darkFormBorderColor
              : Constants.lightFormBorderColor),
          width: 1.0,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon, 
          color: Color(themeProvider.isDarkMode 
              ? Constants.darkIconColor
              : Constants.lightIconColor),
        ),
        title: Text(
          widget.isArabic ? _getArabicTitle(title) : title,
          style: TextStyle(
            fontSize: 16,
            color: Color(themeProvider.isDarkMode 
                ? Constants.darkLabelTextColor
                : Constants.lightLabelTextColor),
          ),
        ),
        trailing: trailing ?? Icon(
          widget.isArabic ? Icons.arrow_forward_ios : Icons.arrow_forward_ios,
          size: 16,
          color: Color(themeProvider.isDarkMode 
              ? Constants.darkHintTextColor
              : Constants.lightHintTextColor),
        ),
        onTap: onTap,
      ),
    );
  }

  String _getArabicTitle(String englishTitle) {
    switch (englishTitle) {
      case 'Biometric Authentication':
        return 'السمات الحيوية';
      case 'Change MPIN':
        return 'تغيير رمز الدخول';
      case 'Change Password':
        return 'تغيير كلمة المرور';
      case 'Language':
        return 'اللغة';
      case 'Sign Off':
        return 'تسجيل خروج';
      case 'Dark Mode':
        return 'الوضع الداكن';
      default:
        return englishTitle;
    }
  }

  Widget _buildStyledFormField({
    required TextEditingController controller,
    required String labelText,
    required bool obscureText,
    required bool isArabic,
    required Function(void Function()) setDialogState,
    required ThemeProvider themeProvider,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? themeProvider.primaryColor.withOpacity(0.08)
            : themeProvider.primaryColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.primaryColor.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        textAlign: isArabic ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          color: themeProvider.primaryColor,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          alignLabelWithHint: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: themeProvider.primaryColor.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: themeProvider.primaryColor.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: themeProvider.primaryColor.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          labelStyle: TextStyle(color: themeProvider.primaryColor.withOpacity(0.8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: Colors.transparent,
          suffixIcon: isArabic ? IconButton(
            icon: Icon(
              obscureText ? Icons.visibility : Icons.visibility_off,
              color: themeProvider.primaryColor,
            ),
            onPressed: () => setDialogState(() => obscureText = !obscureText),
          ) : null,
          prefixIcon: isArabic ? null : IconButton(
            icon: Icon(
              obscureText ? Icons.visibility : Icons.visibility_off,
              color: themeProvider.primaryColor,
            ),
            onPressed: () => setDialogState(() => obscureText = !obscureText),
          ),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = themeProvider.primaryColor;

    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: themeProvider.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 100,
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        widget.isArabic ? 'حسابي' : 'Account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: Image.asset(
                        'assets/images/nayifat-logo-no-bg.png',
                        height: MediaQuery.of(context).size.height * 0.06,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: [
                          const SizedBox(height: 20),
                          // Theme Toggle
                          _buildSettingItem(
                            icon: themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            title: 'Dark Mode',
                            onTap: () {},
                            trailing: Transform.scale(
                              scale: 0.9,
                              child: Switch(
                                value: themeProvider.isDarkMode,
                                onChanged: (bool value) async {
                                  await themeProvider.setDarkMode(value);
                                },
                                activeColor: themeProvider.primaryColor,
                                activeTrackColor: Color(themeProvider.isDarkMode 
                                    ? Constants.darkSwitchTrackColor
                                    : Constants.lightSwitchTrackColor),
                                inactiveThumbColor: Color(themeProvider.isDarkMode 
                                    ? Constants.darkSwitchInactiveThumbColor
                                    : Constants.lightSwitchInactiveThumbColor),
                                inactiveTrackColor: Color(themeProvider.isDarkMode 
                                    ? Constants.darkSwitchInactiveTrackColor
                                    : Constants.lightSwitchInactiveTrackColor),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                trackOutlineColor: MaterialStateProperty.all(
                                  Color(themeProvider.isDarkMode 
                                      ? Constants.darkSwitchTrackOutlineColor
                                      : Constants.lightSwitchTrackOutlineColor)
                                ),
                              ),
                            ),
                          ),
                          if (_isSignedIn) ...[
                            _buildSettingItem(
                              icon: Icons.fingerprint,
                              title: 'Biometric Authentication',
                              onTap: () {
                                if (!_isBiometricsAvailable) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _biometricsError,
                                        style: TextStyle(
                                          color: themeProvider.isDarkMode ? Colors.black : Colors.white,
                                        ),
                                      ),
                                      backgroundColor: themeProvider.primaryColor,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                } else {
                                  _toggleBiometrics();
                                }
                              },
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!_isBiometricsAvailable)
                                    Icon(
                                      Icons.error_outline,
                                      color: themeProvider.primaryColor,
                                      size: 20,
                                    )
                                  else
                                    Switch(
                                      value: _isBiometricsEnabled,
                                      onChanged: (_) => _toggleBiometrics(),
                                      activeColor: themeProvider.primaryColor,
                                      activeTrackColor: Color(themeProvider.isDarkMode 
                                          ? Constants.darkSwitchTrackColor
                                          : Constants.lightSwitchTrackColor),
                                      inactiveThumbColor: Color(themeProvider.isDarkMode 
                                          ? Constants.darkSwitchInactiveThumbColor
                                          : Constants.lightSwitchInactiveThumbColor),
                                      inactiveTrackColor: Color(themeProvider.isDarkMode 
                                          ? Constants.darkSwitchInactiveTrackColor
                                          : Constants.lightSwitchInactiveTrackColor),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      trackOutlineColor: MaterialStateProperty.all(
                                        Color(themeProvider.isDarkMode 
                                            ? Constants.darkSwitchTrackOutlineColor
                                            : Constants.lightSwitchTrackOutlineColor)
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            _buildSettingItem(
                              icon: Icons.pin,
                              title: 'Change MPIN',
                              onTap: _changeMPIN,
                            ),
                            _buildSettingItem(
                              icon: Icons.lock,
                              title: 'Change Password',
                              onTap: _changePassword,
                            ),
                          ],
                          _buildSettingItem(
                            icon: Icons.language,
                            title: widget.isArabic ? 'اللغة Language' : 'Language اللغة',
                            onTap: _toggleLanguage,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.isArabic ? 'العربية' : 'English',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  widget.isArabic ? Icons.arrow_forward_ios : Icons.arrow_forward_ios,
                                  size: 16,
                                  color: themeProvider.primaryColor,
                                ),
                              ],
                            ),
                          ),
                          if (_isSignedIn)
                            _buildSettingItem(
                              icon: Icons.logout,
                              title: 'Sign Off',
                              onTap: _signOut,
                              trailing: Container(
                                margin: const EdgeInsets.only(left: 8),
                                child: TextButton(
                                  onPressed: _signOut,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    backgroundColor: themeProvider.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
                                    ),
                                  ),
                                  child: Text(
                                    widget.isArabic ? 'تسجيل خروج' : 'Sign Off',
                                    style: TextStyle(
                                      color: themeProvider.isDarkMode ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Color(themeProvider.isDarkMode 
                ? Constants.darkNavbarBackground 
                : Constants.lightNavbarBackground),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(themeProvider.isDarkMode 
                    ? Constants.darkNavbarGradientStart
                    : Constants.lightNavbarGradientStart),
                Color(themeProvider.isDarkMode 
                    ? Constants.darkNavbarGradientEnd
                    : Constants.lightNavbarGradientEnd),
              ],
            ),
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
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: CircleNavBar(
              activeIcons: widget.isArabic ? [
                Icon(Icons.settings, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarActiveIcon
                        : Constants.lightNavbarActiveIcon)),
                Icon(Icons.account_balance, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarActiveIcon
                        : Constants.lightNavbarActiveIcon)),
                Icon(Icons.home, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarActiveIcon
                        : Constants.lightNavbarActiveIcon)),
                Icon(Icons.credit_card, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarActiveIcon
                        : Constants.lightNavbarActiveIcon)),
                Icon(Icons.headset_mic, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarActiveIcon
                        : Constants.lightNavbarActiveIcon)),
              ] : [
                Icon(Icons.headset_mic, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarActiveIcon
                        : Constants.lightNavbarActiveIcon)),
                Icon(Icons.credit_card, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarActiveIcon
                        : Constants.lightNavbarActiveIcon)),
                Icon(Icons.home, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarActiveIcon
                        : Constants.lightNavbarActiveIcon)),
                Icon(Icons.account_balance, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarActiveIcon
                        : Constants.lightNavbarActiveIcon)),
                Icon(Icons.settings, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarActiveIcon
                        : Constants.lightNavbarActiveIcon)),
              ],
              inactiveIcons: widget.isArabic ? [
                Icon(Icons.settings, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarInactiveIcon
                        : Constants.lightNavbarInactiveIcon)),
                Icon(Icons.account_balance, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarInactiveIcon
                        : Constants.lightNavbarInactiveIcon)),
                Icon(Icons.home, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarInactiveIcon
                        : Constants.lightNavbarInactiveIcon)),
                Icon(Icons.credit_card, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarInactiveIcon
                        : Constants.lightNavbarInactiveIcon)),
                Icon(Icons.headset_mic, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarInactiveIcon
                        : Constants.lightNavbarInactiveIcon)),
              ] : [
                Icon(Icons.headset_mic, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarInactiveIcon
                        : Constants.lightNavbarInactiveIcon)),
                Icon(Icons.credit_card, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarInactiveIcon
                        : Constants.lightNavbarInactiveIcon)),
                Icon(Icons.home, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarInactiveIcon
                        : Constants.lightNavbarInactiveIcon)),
                Icon(Icons.account_balance, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarInactiveIcon
                        : Constants.lightNavbarInactiveIcon)),
                Icon(Icons.settings, 
                    color: Color(themeProvider.isDarkMode 
                        ? Constants.darkNavbarInactiveIcon
                        : Constants.lightNavbarInactiveIcon)),
              ],
              activeLevelsStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(themeProvider.isDarkMode 
                    ? Constants.darkNavbarActiveText
                    : Constants.lightNavbarActiveText),
              ),
              inactiveLevelsStyle: TextStyle(
                fontSize: 14,
                color: Color(themeProvider.isDarkMode 
                    ? Constants.darkNavbarInactiveText
                    : Constants.lightNavbarInactiveText),
              ),
              levels: widget.isArabic 
                ? const ["حسابي", "التمويل", "الرئيسية", "البطاقات", "الدعم"]
                : const ["Support", "Cards", "Home", "Loans", "Account"],
              color: Color(themeProvider.isDarkMode 
                  ? Constants.darkNavbarBackground 
                  : Constants.lightNavbarBackground),  // Base color
              height: 70,
              circleWidth: 60,
              activeIndex: widget.isArabic ? 0 : 4,
              onTap: (index) {
                if ((widget.isArabic && index == 0) || (!widget.isArabic && index == 4)) {
                  setState(() {
                    _tabIndex = index;
                  });
                  return;  // Don't navigate if we're already on account
                }

                Widget? page;
                if (widget.isArabic) {
                  switch (index) {
                    case 0:
                      return; // Already on account
                    case 1:
                      page = const LoansPageAr();
                      break;
                    case 2:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainPage(
                            isArabic: true,
                            onLanguageChanged: (bool value) {},
                            userData: const {},
                            isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
                          ),
                        ),
                      );
                      return;
                    case 3:
                      page = const CardsPageAr();
                      break;
                    case 4:
                      page = const CustomerServiceScreen(isArabic: true);
                      break;
                  }
                } else {
                  switch (index) {
                    case 0:
                      page = const CustomerServiceScreen(isArabic: false);
                      break;
                    case 1:
                      page = const CardsPage();
                      break;
                    case 2:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainPage(
                            isArabic: false,
                            onLanguageChanged: (bool value) {},
                            userData: const {},
                            isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
                          ),
                        ),
                      );
                      return;
                    case 3:
                      page = const LoansPage();
                      break;
                    case 4:
                      return; // Already on account
                  }
                }

                if (page != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => page!),
                  );
                }
              },
              cornerRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(0),
                bottomRight: Radius.circular(0),
                bottomLeft: Radius.circular(0),
              ),
              shadowColor: themeProvider.primaryColor.withOpacity(0.15),
              elevation: 8,
            ),
          ),
        ),
      ),
    );
  }
}