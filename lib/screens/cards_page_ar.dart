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
      
      if (sessionProvider.isSignedIn) {
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
              'البطاقات',
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
    final adData = contentUpdateService.getCardAd(isArabic: true);
    
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
                'assets/images/cards_ad_ar.JPG',
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
              builder: (context) => const CardApplicationStartScreen(isArabic: true),
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
          sessionProvider.isSignedIn ? 'تقدم بطلب بطاقة' : 'اكمل تسجيل الدخول للطلب',
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

  Widget _buildCardsList() {
    if (_cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'لا توجد بطاقات نشطة',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 250 + (_cards.length - 1) * 70.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Stack(
        children: List.generate(_cards.length, (index) {
          final actualIndex = (_selectedCardIndex + index) % _cards.length;
          final card = _cards[actualIndex];
          
          // Safely convert all values
          final cardType = card['type']?.toString() ?? 'بطاقة ائتمان';
          final cardNumber = card['number']?.toString() ?? '**** **** **** ****';
          final cardStatus = card['status']?.toString() ?? 'نشط';
          
          // Determine card colors based on type
          final List<Color> cardColors = cardType.toLowerCase().contains('gold') || cardType.contains('ذهبية')
              ? [const Color(0xFF1A1A1A), const Color(0xFF333333)]
              : cardType.toLowerCase().contains('platinum') || cardType.contains('بلاتينية')
                  ? [const Color(0xFFE5E5E5), const Color(0xFFC0C0C0)]
                  : [const Color(0xFF1A1A1A), const Color(0xFF333333)];

          final Color textColor = cardType.toLowerCase().contains('platinum') || cardType.contains('بلاتينية')
              ? Colors.black 
              : Colors.white;
          
          final Color shadowColor = cardType.toLowerCase().contains('platinum') || cardType.contains('بلاتينية')
              ? const Color(0xFFC0C0C0)
              : Colors.black;

          // Only allow clicking on cards that aren't in front
          final bool isClickable = index > 0;

          return AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            top: index * 70.0,
            left: _isCardAnimating[index] ? MediaQuery.of(context).size.width : 0,
            right: _isCardAnimating[index] ? -MediaQuery.of(context).size.width : 0,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 500),
              scale: _isCardAnimating[index] ? 0.95 : 1.0,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(0.1),
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: isClickable ? () => _selectCard(index) : null,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: cardColors,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        // Main shadow
                        BoxShadow(
                          color: shadowColor.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 15),
                          spreadRadius: -5,
                        ),
                        // Highlight shadow
                        BoxShadow(
                          color: shadowColor.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 8),
                          spreadRadius: -2,
                        ),
                        // Edge shadow
                        BoxShadow(
                          color: shadowColor.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Decorative Card Elements
                        Positioned(
                          left: -50,
                          top: -50,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: textColor.withOpacity(0.05),
                            ),
                          ),
                        ),
                        // Card Logo
                        Positioned(
                          top: 20,
                          left: 20,
                          child: SvgPicture.asset(
                            'assets/images/nayifat-logo.svg',
                            height: 40,
                            colorFilter: ColorFilter.mode(
                              textColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        // Card Type
                        Positioned(
                          top: 20,
                          right: 20,
                          child: Text(
                            cardType,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Card Number
                        Positioned(
                          bottom: 60,
                          right: 20,
                          child: Text(
                            cardNumber,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 22,
                              letterSpacing: 2,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        // Card Status
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: textColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: textColor.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              cardStatus,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0077B6),
          ),
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
            'اكمل تسجيل الدخول لعرض بطاقاتك',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الوصول إلى معلومات البطاقات الخاصة بك، والتقدم بطلب للحصول على بطاقات جديدة، وتتبع طلباتك.',
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              'البطاقات الخاصة بك',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.black : const Color(0xFF0077B6),
                              ),
                            ),
                          ),
                          _buildCardsList(),
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
                          userData: const {},
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
        ),
      ),
    );
  }
} 