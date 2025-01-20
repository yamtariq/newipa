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
import 'account_page.dart';

class AccountPageAr extends StatefulWidget {
  final bool isArabic;
  const AccountPageAr({super.key, this.isArabic = true});

  @override
  State<AccountPageAr> createState() => _AccountPageArState();
}

class _AccountPageArState extends State<AccountPageAr> {
  final AuthService _authService = AuthService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final Color primaryColor = const Color(0xFF0077B6);
  String _userName = '';
  bool _isBiometricsEnabled = false;
  String _currentLanguage = 'العربية';
  bool _isLoading = true;
  int _tabIndex = 4;  // For Account tab (settings)
  Map<String, dynamic> _userData = {};
  bool isDeviceRegistered = false;

  double get screenHeight => MediaQuery.of(context).size.height;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? '';
      final isBiometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;

      setState(() {
        _userName = userName;
        _isBiometricsEnabled = isBiometricsEnabled;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newValue = !_isBiometricsEnabled;
      await prefs.setBool('biometrics_enabled', newValue);
      
      if (newValue) {
        final canCheckBiometrics = await _localAuth.canCheckBiometrics;
        if (!canCheckBiometrics) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('البصمة غير متوفرة على هذا الجهاز')),
          );
          return;
        }
      }

      setState(() {
        _isBiometricsEnabled = newValue;
      });
    } catch (e) {
      print('Error toggling biometrics: $e');
    }
  }

  Future<void> _changeMPIN() async {
    final prefs = await SharedPreferences.getInstance();
    final String? nationalId = prefs.getString('nationalId');
    final String? password = prefs.getString('password');
    
    if (nationalId != null && password != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MPINSetupScreen(
            nationalId: nationalId,
            password: password,
            showSteps: false,
          ),
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    // Navigate to password change screen
    // TODO: Implement password change screen
  }

  Future<void> _toggleLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _currentLanguage == 'العربية' ? 'English' : 'العربية');
    setState(() {
      _currentLanguage = _currentLanguage == 'العربية' ? 'English' : 'العربية';
    });
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOutDevice();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (route) => false,
      );
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16),
        textDirection: TextDirection.rtl,
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الحساب'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 60),
              Center(
                child: Image.asset(
                                      'assets/images/nayifat-logo-no-bg.png',
                                      height: screenHeight * 0.06,
                                    ),
              ),
              const SizedBox(height: 20),
              Text(
                _userName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingItem(
                      icon: Icons.fingerprint,
                      title: 'البصمة',
                      onTap: _toggleBiometrics,
                      trailing: Switch(
                        value: _isBiometricsEnabled,
                        onChanged: (_) => _toggleBiometrics(),
                        activeColor: primaryColor,
                      ),
                    ),
                    const Divider(),
                    _buildSettingItem(
                      icon: Icons.pin,
                      title: 'تغيير MPIN',
                      onTap: _changeMPIN,
                    ),
                    const Divider(),
                    _buildSettingItem(
                      icon: Icons.lock,
                      title: 'تغيير كلمة المرور',
                      onTap: _changePassword,
                    ),
                    const Divider(),
                    _buildSettingItem(
                      icon: Icons.language,
                      title: 'اللغة',
                      onTap: _toggleLanguage,
                      trailing: Text(_currentLanguage),
                    ),
                    const Divider(),
                    _buildSettingItem(
                      icon: Icons.logout,
                      title: 'تسجيل الخروج',
                      onTap: _signOut,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: primaryColor,
            boxShadow: [
              BoxShadow(
                color: primaryColor,
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: CircleNavBar(
            activeIcons: [
              Icon(Icons.headset_mic, color: primaryColor),
              Icon(Icons.credit_card, color: primaryColor),
              Icon(Icons.home, color: primaryColor),
              Icon(Icons.account_balance, color: primaryColor),
              Icon(Icons.settings, color: primaryColor),
            ],
            inactiveIcons: [
              Icon(Icons.headset_mic, color: primaryColor),
              Icon(Icons.credit_card, color: primaryColor),
              Icon(Icons.home, color: primaryColor),
              Icon(Icons.account_balance, color: primaryColor),
              Icon(Icons.settings, color: primaryColor),
            ],
            levels: widget.isArabic 
              ? const ["الدعم", "البطاقات", "الرئيسية", "التمويل", "حسابي"]
              : const ["Support", "Cards", "Home", "Loans", "Account"],
            activeLevelsStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0077B6),
            ),
            inactiveLevelsStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0077B6),
            ),
            color: Colors.white,
            height: 70,
            circleWidth: 60,
            activeIndex: 4,  // Account tab
            onTap: (index) {
              if (index == 2) {  // Home tab
                setState(() {
                  _tabIndex = index;
                });
                return;  // Don't navigate if we're already home
              }

              // For other tabs, navigate and update index only if navigation succeeds
              Widget page;
              switch (index) {
                case 0:
                  page = widget.isArabic ? const CustomerServiceScreen(isArabic: true) : const CustomerServiceScreen(isArabic: false);
                  break;
                case 1:
                  page = widget.isArabic ? const CardsPageAr() : const CardsPage();
                  break;
                case 3:
                  page = widget.isArabic ? const LoansPageAr() : const LoansPage();
                  break;
                case 4:
                  page = widget.isArabic ? const AccountPageAr() : const AccountPage();
                  break;
                default:
                  return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => page,
                ),
              ).then((_) {
                setState(() {
                  _tabIndex = 2;
                });
              });
            },
            cornerRadius: const BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
              bottomRight: Radius.circular(0),
              bottomLeft: Radius.circular(0),
            ),
            shadowColor: Colors.transparent,
            elevation: 20,
          ),
        ),
      ),
    );
  }
}