import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import '../models/loan.dart';
import '../services/loan_service.dart';
import '../widgets/loan_card.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'loan_application/loan_application_start_screen.dart';
// Import Arabic pages
import 'cards_page_ar.dart';
import 'account_page.dart';
import 'main_page.dart';
import 'customer_service_screen.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import 'package:provider/provider.dart' as provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/sign_in_screen.dart';
import '../services/content_update_service.dart';
import '../providers/theme_provider.dart';

class LoansPageAr extends StatefulWidget {
  const LoansPageAr({Key? key}) : super(key: key);

  @override
  State<LoansPageAr> createState() => _LoansPageArState();
}

class _LoansPageArState extends State<LoansPageAr> {
  final LoanService _loanService = LoanService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<Loan> _loans = [];
  String? _applicationStatus;
  int _tabIndex = 3;
  bool isDeviceRegistered = false;

  double get screenHeight => MediaQuery.of(context).size.height;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkDeviceRegistration();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Provider.of<SessionProvider>(context, listen: false).checkSession();
        _setupPeriodicSessionCheck();
      }
    });
  }

  Future<void> _checkDeviceRegistration() async {
    try {
      final isDeviceReg = await _authService.isDeviceRegistered();
      setState(() {
        isDeviceRegistered = isDeviceReg;
      });
    } catch (e) {
      print('Error checking device registration: $e');
    }
  }

  Future<void> _navigateToSignIn() async {
    if (isDeviceRegistered) {
      // Check biometric and MPIN settings
      final isBiometricEnabled = await _authService.isBiometricEnabled();
      final isMPINSet = await _authService.isMPINSet();
      
      print('Auth Settings - Biometric Enabled: $isBiometricEnabled, MPIN Set: $isMPINSet'); // Debug log
      
      // If either biometric or MPIN is set up, don't start with password screen
      final startWithPassword = !(isBiometricEnabled || isMPINSet);
      
      print('Starting with password screen: $startWithPassword'); // Debug log

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SignInScreen(isArabic: true, startWithPassword: startWithPassword),
          ),
        );
      }
    } else {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SignInScreen(isArabic: true, startWithPassword: true),
          ),
        );
      }
    }
  }

  void _setupPeriodicSessionCheck() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        Provider.of<SessionProvider>(context, listen: false).checkSession();
        _setupPeriodicSessionCheck();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final isSignedIn = Provider.of<SessionProvider>(context, listen: false).isSignedIn;
      
      List<Loan> loans = [];
      String? status;
      
      if (isSignedIn) {
        loans = await _loanService.getUserLoans();
        status = await _loanService.getCurrentApplicationStatus(isArabic: true);
      }
      
      setState(() {
        _loans = loans;
        _applicationStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildHeader() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode ? Colors.black : const Color(0xFF0077B6);

    return Container(
      height: 100,
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center title
          Center(
            child: Text(
              'التمويل',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
          ),
          // Logo positioned at right
          Positioned(
            right: 0,
            child: isDarkMode 
              ? ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/nayifat-logo-no-bg.png',
                    height: screenHeight * 0.06,
                  ),
                )
              : Image.asset(
                  'assets/images/nayifat-logo-no-bg.png',
                  height: screenHeight * 0.06,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvertBanner() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final contentUpdateService = ContentUpdateService();
    final adData = contentUpdateService.getLoanAd(isArabic: true);
    
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.grey[400]! : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: adData != null && adData['image_bytes'] != null
            ? Image.memory(
                adData['image_bytes'],
                fit: BoxFit.fill,
                width: double.infinity,
              )
            : Image.asset(
                'assets/images/loans_ad_ar.JPG',
                fit: BoxFit.fill,
                width: double.infinity,
              ),
      ),
    );
  }

  Widget _buildApplyNowButton() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final sessionProvider = Provider.of<SessionProvider>(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: sessionProvider.isSignedIn ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LoanApplicationStartScreen(isArabic: true),
            ),
          );
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode ? Colors.black : const Color(0xFF0077B6),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: Text(
          sessionProvider.isSignedIn ? 'تقدم بطلب تمويل' : 'اكمل تسجيل الدخول للطلب',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationStatus() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode ? Colors.black : const Color(0xFF0077B6);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[100] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: themeColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            'حالة الطلب: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
          ),
          Expanded(
            child: Text(
              _applicationStatus ?? 'لا توجد طلبات نشطة',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.black87 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoansList() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode ? Colors.black : const Color(0xFF0077B6);

    if (_loans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'لا توجد تمويل نشطة',
            style: TextStyle(
              color: isDarkMode ? Colors.black54 : Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'التمويل الخاصة بك',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _loans.length,
          itemBuilder: (context, index) {
            final loan = _loans[index];
            return LoanCard(loan: loan);
          },
        ),
      ],
    );
  }

  Widget _buildSignInPrompt() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode ? Colors.black : const Color(0xFF0077B6);

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[100] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: themeColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'اكمل تسجيل الدخول لعرض تمويلك',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الوصول إلى معلومات التمويل الخاص بك، والتقدم بطلب للحصول على تمويلض جديدة، وتتبع طلباتك.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.black87 : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _navigateToSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.black.withOpacity(0.1) : Colors.red[50],
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              side: BorderSide(
                color: isDarkMode ? Colors.black : Colors.red,
              ),
            ),
            child: Text(
              'تسجيل الدخول',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.black : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = Provider.of<SessionProvider>(context).isSignedIn;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.grey[100] : Colors.white,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        _buildAdvertBanner(),
                        if (isSignedIn) ...[
                          _buildApplyNowButton(),
                          _buildApplicationStatus(),
                          _buildLoansList(),
                        ] else
                          _buildSignInPrompt(),
                      ],
                    ),
                  ),
                ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[700] : const Color(0xFF0077B6),
            boxShadow: [
              BoxShadow(
                color: isDarkMode ? Colors.grey[900]! : const Color(0xFF0077B6),
                blurRadius: isDarkMode ? 10 : 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: CircleNavBar(
              activeIcons: [
                Icon(Icons.settings, color: isDarkMode ? Colors.grey[400] : const Color(0xFF0077B6)),
                Icon(Icons.account_balance, color: isDarkMode ? Colors.grey[400] : const Color(0xFF0077B6)),
                Icon(Icons.home, color: isDarkMode ? Colors.grey[400] : const Color(0xFF0077B6)),
                Icon(Icons.credit_card, color: isDarkMode ? Colors.grey[400] : const Color(0xFF0077B6)),
                Icon(Icons.headset_mic, color: isDarkMode ? Colors.grey[400] : const Color(0xFF0077B6)),
              ],
              inactiveIcons: [
                Icon(Icons.settings, color: isDarkMode ? Colors.grey[400] : const Color(0xFF0077B6)),
                Icon(Icons.account_balance, color: isDarkMode ? Colors.grey[400] : const Color(0xFF0077B6)),
                Icon(Icons.home, color: isDarkMode ? Colors.grey[400] : const Color(0xFF0077B6)),
                Icon(Icons.credit_card, color: isDarkMode ? Colors.grey[400] : const Color(0xFF0077B6)),
                Icon(Icons.headset_mic, color: isDarkMode ? Colors.grey[400] : const Color(0xFF0077B6)),
              ],
              levels: const ["حسابي", "التمويل", "الرئيسية", "البطاقات", "الدعم"],
              activeLevelsStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.grey[400] : const Color(0xFF0077B6),
              ),
              inactiveLevelsStyle: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : const Color(0xFF0077B6),
              ),
              color: isDarkMode ? Colors.black : Colors.white,
              height: 70,
              circleWidth: 60,
              activeIndex: 1,
              onTap: (index) {
                Widget? page;
                switch (index) {
                  case 0:
                    page = const AccountPage(isArabic: true);
                    break;
                  case 1:
                    return; // Already on Loans page
                  case 2:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MainPage(
                          isArabic: true,
                          onLanguageChanged: (bool value) {},
                          userData: const {},
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
              shadowColor: Colors.transparent,
              elevation: 20,
            ),
          ),
        ),
      ),
    );
  }
} 