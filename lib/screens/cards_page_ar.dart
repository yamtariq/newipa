import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import '../services/auth_service.dart';
import '../services/card_service.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import 'package:provider/provider.dart' as provider;
// Import Arabic pages
import 'loans_page_ar.dart';
import 'account_page.dart';
import 'main_page.dart';
import 'customer_service_screen.dart';
import 'card_application/card_application_start_screen.dart';
import 'auth/sign_in_screen.dart';
import '../services/content_update_service.dart';
import '../providers/theme_provider.dart';
import '../services/theme_service.dart';
import '../utils/constants.dart';

class CardsPageAr extends StatefulWidget {
  const CardsPageAr({Key? key}) : super(key: key);

  @override
  State<CardsPageAr> createState() => _CardsPageArState();
}

class _CardsPageArState extends State<CardsPageAr> {
  final CardService _cardService = CardService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<dynamic> _cards = [];
  String? _applicationStatus;
  int _selectedCardIndex = 0;
  bool isDeviceRegistered = false;
  int _tabIndex = 3;

  double get screenHeight => MediaQuery.of(context).size.height;

  // Animation controller
  late List<bool> _isCardAnimating;

  @override
  void initState() {
    super.initState();
    _checkDeviceRegistration();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (mounted) {
      await Provider.of<SessionProvider>(context, listen: false).checkSession();
      await _loadData();
      _setupPeriodicSessionCheck();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isCardAnimating = List.generate(_cards.length, (index) => false);
  }

  // Method to handle card selection
  void _selectCard(int index) {
    if (_selectedCardIndex == index) return;
    
    setState(() {
      _isCardAnimating = List.generate(_cards.length, (i) => true);
      // Calculate the new index to bring the clicked card to front
      _selectedCardIndex = (_selectedCardIndex + (_cards.length - index)) % _cards.length;
    });

    // Reset animation flags after animation completes
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isCardAnimating = List.generate(_cards.length, (i) => false);
        });
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

  void _setupPeriodicSessionCheck() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        Provider.of<SessionProvider>(context, listen: false).checkSession();
        _setupPeriodicSessionCheck();
      }
    });
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

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      await sessionProvider.checkSession();
      
      List<dynamic> cards = [];
      String? status;
      
      if (sessionProvider.hasActiveSession) {
        cards = await _cardService.getUserCards();
        status = await _cardService.getCurrentApplicationStatus(isArabic: true);
      }
      
      setState(() {
        _cards = cards;
        _applicationStatus = status;
        _isLoading = false;
        _isCardAnimating = List.generate(cards.length, (index) => false);
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final backgroundColor = Color(themeProvider.isDarkMode 
        ? Constants.darkBackgroundColor 
        : Constants.lightBackgroundColor);
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
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
                        _buildHeader(primaryColor),
                        _buildAdvertBanner(),
                        if (Provider.of<SessionProvider>(context).hasActiveSession) ...[
                          _buildApplyNowButton(),
                          _buildApplicationStatus(primaryColor),
                          _buildCardsList(primaryColor),
                        ] else
                          _buildSignInPrompt(primaryColor),
                      ],
                    ),
                  ),
                ),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              'البطاقات',
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
              height: screenHeight * 0.06,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvertBanner() {
    final contentUpdateService = ContentUpdateService();
    final adData = contentUpdateService.getCardAd(isArabic: true);
    
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
        child: adData != null && adData['image_bytes'] != null
            ? Image.memory(
                adData['image_bytes'],
                fit: BoxFit.fill,
                width: double.infinity,
              )
            : Image.asset(
                'assets/images/cards_ad_ar.JPG',
                fit: BoxFit.fill,
                width: double.infinity,
              ),
      ),
    );
  }

  Widget _buildApplyNowButton() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final sessionProvider = Provider.of<SessionProvider>(context);
    final primaryColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final surfaceColor = Color(themeProvider.isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: sessionProvider.hasActiveSession ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CardApplicationStartScreen(isArabic: true),
            ),
          );
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
          ),
          elevation: themeProvider.isDarkMode ? 0 : 2,
          side: BorderSide(
            color: primaryColor,
          ),
        ),
        child: Text(
          sessionProvider.hasActiveSession ? 'تقدم بطلب بطاقة' : 'اكمل تسجيل الدخول للطلب',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: surfaceColor,
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationStatus(Color textColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final surfaceColor = Color(themeProvider.isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(Constants.formBorderRadius),
        border: Border.all(
          color: Color(themeProvider.isDarkMode 
              ? Constants.darkFormBorderColor 
              : Constants.lightFormBorderColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            'حالة الطلب: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Expanded(
            child: Text(
              _applicationStatus ?? 'لا توجد طلبات نشطة',
              style: TextStyle(
                fontSize: 16,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsList(Color textColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'لا توجد بطاقات نشطة',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 400 + (_cards.length - 1) * 70.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Stack(
        children: List.generate(_cards.length, (index) {
          final actualIndex = (_selectedCardIndex + index) % _cards.length;
          final card = _cards[actualIndex];
          
          final cardStatus = card['status']?.toString() ?? 'نشط';
          
          final bool isClickable = index > 0;

          return AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            top: index * 50.0,
            left: _isCardAnimating[index] ? -MediaQuery.of(context).size.width : 0,
            right: 0,
            child: Container(
              width: MediaQuery.of(context).size.width - 32, // Full width minus margins
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: isClickable ? () => _selectCard(index) : null,
                    child: Row(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.45,
                          height: 280,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                                spreadRadius: -8,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                                spreadRadius: -4,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
                            child: AspectRatio(
                              aspectRatio: 0.63,
                              child: Image.asset(
                                'assets/images/platinum.jpg',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: textColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cardStatus,
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'الحد المتاح',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card['available_limit']?.toString() ?? ' 0.00 ريال',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'حد البطاقة',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card['card_limit']?.toString() ?? ' 0.00 ريال',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: textColor,
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
        }),
      ),
    );
  }

  Widget _buildSignInPrompt(Color textColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final surfaceColor = Color(themeProvider.isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
        border: Border.all(
          color: Color(themeProvider.isDarkMode 
              ? Constants.darkFormBorderColor 
              : Constants.lightFormBorderColor),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'اكمل تسجيل الدخول لعرض بطاقاتك',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الوصول إلى معلومات البطاقات الخاصة بك، والتقدم بطلب للحصول على بطاقات جديدة، وتتبع طلباتك.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _navigateToSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: textColor,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
              ),
            ),
            child: Text(
              'تسجيل الدخول',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: surfaceColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final navBackgroundColor = Color(themeProvider.isDarkMode 
        ? Constants.darkNavbarBackground 
        : Constants.lightNavbarBackground);

    return Container(
      decoration: BoxDecoration(
        color: navBackgroundColor,
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
          activeIcons: [
            Icon(Icons.settings, color: Color(themeProvider.isDarkMode 
                ? Constants.darkNavbarActiveIcon 
                : Constants.lightNavbarActiveIcon)),
            Icon(Icons.account_balance, color: Color(themeProvider.isDarkMode 
                ? Constants.darkNavbarActiveIcon 
                : Constants.lightNavbarActiveIcon)),
            Icon(Icons.home, color: Color(themeProvider.isDarkMode 
                ? Constants.darkNavbarActiveIcon 
                : Constants.lightNavbarActiveIcon)),
            Icon(Icons.credit_card, color: Color(themeProvider.isDarkMode 
                ? Constants.darkNavbarActiveIcon 
                : Constants.lightNavbarActiveIcon)),
            Icon(Icons.headset_mic, color: Color(themeProvider.isDarkMode 
                ? Constants.darkNavbarActiveIcon 
                : Constants.lightNavbarActiveIcon)),
          ],
          inactiveIcons: [
            Icon(Icons.settings, color: Color(themeProvider.isDarkMode 
                ? Constants.darkNavbarInactiveIcon 
                : Constants.lightNavbarInactiveIcon)),
            Icon(Icons.account_balance, color: Color(themeProvider.isDarkMode 
                ? Constants.darkNavbarInactiveIcon 
                : Constants.lightNavbarInactiveIcon)),
            Icon(Icons.home, color: Color(themeProvider.isDarkMode 
                ? Constants.darkNavbarInactiveIcon 
                : Constants.lightNavbarInactiveIcon)),
            Icon(Icons.credit_card, color: Color(themeProvider.isDarkMode 
                ? Constants.darkNavbarInactiveIcon 
                : Constants.lightNavbarInactiveIcon)),
            Icon(Icons.headset_mic, color: Color(themeProvider.isDarkMode 
                ? Constants.darkNavbarInactiveIcon 
                : Constants.lightNavbarInactiveIcon)),
          ],
          levels: const ["حسابي", "التمويل", "الرئيسية", "البطاقات", "الدعم"],
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
          color: navBackgroundColor,
          height: 70,
          circleWidth: 60,
          activeIndex: 3,
          onTap: (index) {
            Widget? page;
            switch (index) {
              case 0:
                page = const AccountPage(isArabic: true);
                break;
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
                      userData: {},
                      initialRoute: '',
                      isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
                    ),
                  ),
                );
                return;
              case 3:
                return; // Already on Cards page
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
    );
  }
} 