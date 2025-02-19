import 'package:flutter/material.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact_details.dart';
import '../services/api_service.dart';
import '../services/content_update_service.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'cards_page.dart';
import 'loans_page.dart';
import 'account_page.dart';
import 'cards_page_ar.dart';
import 'loans_page_ar.dart';
import 'main_page.dart';
import 'map_with_branches.dart';
import '../utils/constants.dart';
import '../services/theme_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class CustomerServiceScreen extends StatefulWidget {
  final bool isArabic;
  final String? source;
  final String? applicationNumber;

  const CustomerServiceScreen({
    super.key,
    required this.isArabic,
    this.source,
    this.applicationNumber,
  });

  @override
  State<CustomerServiceScreen> createState() => _CustomerServiceScreenState();
}

class _CustomerServiceScreenState extends State<CustomerServiceScreen> {
  int _tabIndex = 0;
  ContactDetails? _contactDetails;
  bool _isLoading = true;
  final ApiService _apiService = ApiService();
  final ContentUpdateService _contentUpdateService = ContentUpdateService();
  bool _shouldMakeApiCall = true;

  double get screenHeight => MediaQuery.of(context).size.height;

  @override
  void initState() {
    super.initState();
    _loadData();
    _contentUpdateService.addListener(_onContentUpdated);
  }

  @override
  void dispose() {
    _contentUpdateService.removeListener(_onContentUpdated);
    super.dispose();
  }

  void _onContentUpdated() {
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      _contactDetails = _contentUpdateService.getContactDetails(isArabic: widget.isArabic);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading contact details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  void _launchEmail() {
    _launchUrl('mailto:${_contactDetails?.email ?? "CustomerCare@nayifat.com"}');
  }

  void _launchPhone() {
    _launchUrl('tel:${_contactDetails?.phone ?? "8001000088"}');
  }

  Future<void> _launchSocialLink(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $url')),
      );
    }
  }

  Widget _buildHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);

    return Container(
      height: 100,
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 90.0),
            child: Center(
              child: Text(
                widget.isArabic ? 'خدمة العملاء' : 'Customer Service',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
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

  Widget _buildContactSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final cardColor = Color(themeProvider.isDarkMode 
        ? Constants.darkFormBackgroundColor 
        : Constants.lightFormBackgroundColor);

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
        border: Border.all(
          color: Color(themeProvider.isDarkMode 
              ? Constants.darkFormBorderColor 
              : Constants.lightFormBorderColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(themeProvider.isDarkMode 
                ? Constants.darkPrimaryShadowColor 
                : Constants.lightPrimaryShadowColor),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: widget.isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Container(
            width: double.infinity,
            alignment: widget.isArabic ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              widget.isArabic ? 'اتصل بنا' : 'Contact Us',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            alignment: widget.isArabic ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onTap: _launchPhone,
              child: _buildContactItem(
                Icons.phone,
                _contactDetails?.phone ?? "8001000088",
                fontSize: 13,
                isLink: true,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            alignment: widget.isArabic ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onTap: _launchEmail,
              child: _buildContactItem(
                Icons.email,
                _contactDetails?.email ?? "CustomerCare@nayifat.com",
                fontSize: 13,
                isLink: true,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            alignment: widget.isArabic ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapWithBranchesScreen(isArabic: widget.isArabic),
                  ),
                );
              },
              child: _buildContactItem(
                Icons.location_on,
                widget.isArabic ? 'ابحث عن أقرب فرع' : 'Find Nearest Branch',
                fontSize: 14,
                isLink: true,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSocialLinks(color: primaryColor),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String text, {
    double fontSize = 16,
    bool isLink = false,
    Color? color,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeColor = color ?? Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);

    return Row(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: themeColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: isLink ? themeColor : Color(themeProvider.isDarkMode 
                  ? Constants.darkLabelTextColor 
                  : Constants.lightLabelTextColor),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinks({Color? color}) {
    if (_contactDetails == null) return const SizedBox.shrink();

    final Map<String, IconData> socialIcons = {
      'linkedin': FontAwesomeIcons.linkedinIn,
      'instagram': FontAwesomeIcons.instagram,
      'twitter': FontAwesomeIcons.xTwitter,
      'facebook': FontAwesomeIcons.facebookF,
    };

    // Define fixed order for social media links
    final orderedSocialKeys = ['linkedin', 'instagram', 'twitter', 'facebook'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      textDirection: TextDirection.ltr, // Always keep LTR order for social icons
      children: orderedSocialKeys.map((key) {
        final url = _contactDetails!.socialLinks[key] ?? '';
        if (url.isEmpty) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: IconButton(
            icon: FaIcon(socialIcons[key] ?? FontAwesomeIcons.link),
            onPressed: () => _launchSocialLink(url),
            color: color ?? Theme.of(context).primaryColor,
            iconSize: 20,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        );
      }).where((widget) => widget is! SizedBox).toList(),
    );
  }

  Widget _buildContactForm() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final cardColor = Color(themeProvider.isDarkMode 
        ? Constants.darkFormBackgroundColor 
        : Constants.lightFormBackgroundColor);
    final inputBgColor = Color(themeProvider.isDarkMode 
        ? Constants.darkFormBackgroundColor 
        : Constants.lightFormBackgroundColor);
    final textColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);
    final hintColor = Color(themeProvider.isDarkMode 
        ? Constants.darkHintTextColor 
        : Constants.lightHintTextColor);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
        border: Border.all(
          color: Color(themeProvider.isDarkMode 
              ? Constants.darkFormBorderColor 
              : Constants.lightFormBorderColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(themeProvider.isDarkMode 
                ? Constants.darkPrimaryShadowColor 
                : Constants.lightPrimaryShadowColor),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: widget.isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Container(
            width: double.infinity,
            alignment: widget.isArabic ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              widget.isArabic ? 'نموذج الاتصال' : 'Contact Form',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          CustomerForm(isArabic: widget.isArabic),
        ],
      ),
    );
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
    final navBackgroundColor = Color(themeProvider.isDarkMode 
        ? Constants.darkNavbarBackground 
        : Constants.lightNavbarBackground);
    final secondaryTextColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);

    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: widget.isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildContactSection(),
                _buildContactForm(),
                const SizedBox(height: 20),
              ],
            ),
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
              ] : [
                Icon(Icons.headset_mic, color: Color(themeProvider.isDarkMode 
                    ? Constants.darkNavbarActiveIcon 
                    : Constants.lightNavbarActiveIcon)),
                Icon(Icons.credit_card, color: Color(themeProvider.isDarkMode 
                    ? Constants.darkNavbarActiveIcon 
                    : Constants.lightNavbarActiveIcon)),
                Icon(Icons.home, color: Color(themeProvider.isDarkMode 
                    ? Constants.darkNavbarActiveIcon 
                    : Constants.lightNavbarActiveIcon)),
                Icon(Icons.account_balance, color: Color(themeProvider.isDarkMode 
                    ? Constants.darkNavbarActiveIcon 
                    : Constants.lightNavbarActiveIcon)),
                Icon(Icons.settings, color: Color(themeProvider.isDarkMode 
                    ? Constants.darkNavbarActiveIcon 
                    : Constants.lightNavbarActiveIcon)),
              ],
              inactiveIcons: widget.isArabic ? [
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
              ] : [
                Icon(Icons.headset_mic, color: Color(themeProvider.isDarkMode 
                    ? Constants.darkNavbarInactiveIcon 
                    : Constants.lightNavbarInactiveIcon)),
                Icon(Icons.credit_card, color: Color(themeProvider.isDarkMode 
                    ? Constants.darkNavbarInactiveIcon 
                    : Constants.lightNavbarInactiveIcon)),
                Icon(Icons.home, color: Color(themeProvider.isDarkMode 
                    ? Constants.darkNavbarInactiveIcon 
                    : Constants.lightNavbarInactiveIcon)),
                Icon(Icons.account_balance, color: Color(themeProvider.isDarkMode 
                    ? Constants.darkNavbarInactiveIcon 
                    : Constants.lightNavbarInactiveIcon)),
                Icon(Icons.settings, color: Color(themeProvider.isDarkMode 
                    ? Constants.darkNavbarInactiveIcon 
                    : Constants.lightNavbarInactiveIcon)),
              ],
              levels: widget.isArabic 
                ? const ["حسابي", "التمويل", "الرئيسية", "البطاقات", "الدعم"]
                : const ["Support", "Cards", "Home", "Loans", "Account"],
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
              color: Color(themeProvider.isDarkMode 
                  ? Constants.darkNavbarBackground 
                  : Constants.lightNavbarBackground),
              height: 70,
              circleWidth: 60,
              activeIndex: widget.isArabic ? 4 : 0,
              onTap: (index) {
                if ((widget.isArabic && index == 4) || (!widget.isArabic && index == 0)) {
                  setState(() {
                    _tabIndex = index;
                  });
                  return;  // Don't navigate if we're already on support
                }

                Widget? page;
                if (widget.isArabic) {
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
                      page = const CardsPageAr();
                      break;
                  }
                } else {
                  switch (index) {
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
                            userData: {},
                            initialRoute: '',
                            isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
                          ),
                        ),
                      );
                      return;
                    case 3:
                      page = const LoansPage();
                      break;
                    case 4:
                      page = widget.isArabic
                          ? const AccountPage(isArabic: true)
                          : const AccountPage(isArabic: false);
                      break;
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
              shadowColor: Colors.transparent,
              elevation: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomerForm extends StatefulWidget {
  final bool isArabic;

  const CustomerForm({super.key, required this.isArabic});

  @override
  _CustomerFormState createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  String formType = 'complaint';
  String requestType = 'loans';
  final TextEditingController bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  final ApiService _apiService = ApiService();

  void _showSuccessDialog(BuildContext context, String complaintNumber) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final textColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: Color(themeProvider.isDarkMode 
              ? Constants.darkSurfaceColor 
              : Constants.lightSurfaceColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success animation
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 800),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 64 * value,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                widget.isArabic ? 'تم الإرسال بنجاح!' : 'Successfully Submitted!',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isArabic 
                    ? 'رقم الشكوى: $complaintNumber' 
                    : 'Complaint Number: $complaintNumber',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                bodyController.clear();
              },
              child: Text(
                widget.isArabic ? 'حسناً' : 'OK',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.isArabic ? 'خطأ' : 'Error',
          style: TextStyle(color: Colors.red),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isArabic ? 'حسناً' : 'OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    print('\n=== CUSTOMER CARE FORM SUBMISSION START ===');
    
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    setState(() => _isSubmitting = true);
    print('Setting submission state to true');

    try {
      print('\n1. GETTING USER DATA');
      // Get user data from secure storage
      final storage = const FlutterSecureStorage();
      final userDataStr = await storage.read(key: 'user_data');
      print('Raw user data from storage: $userDataStr');
      
      String? nationalId;
      String? phone;
      String? customerName;

      if (userDataStr == null || !json.decode(userDataStr)['isSessionActive']) {
        print('No active session found, showing guest user form');
        final guestData = await _showGuestUserForm();
        if (guestData == null) {
          print('Guest form cancelled');
          setState(() => _isSubmitting = false);
          return;
        }
        nationalId = guestData['nationalId'];
        phone = guestData['phone'];
        customerName = guestData['customerName'];
      } else {
        final userData = json.decode(userDataStr);
        print('Parsed user data: $userData');
        
        print('\n2. EXTRACTING USER DETAILS');
        nationalId = userData['national_id'] ?? await storage.read(key: 'national_id');
        phone = userData['phone'];
        customerName = userData['name'] ?? '';
      }

      print('Extracted user details:');
      print('- National ID: $nationalId');
      print('- Phone: $phone');
      print('- Customer Name: $customerName');

      if (nationalId == null || phone == null || customerName == null || customerName.isEmpty) {
        print('❌ Missing required user information:');
        print('- National ID present: ${nationalId != null}');
        print('- Phone present: ${phone != null}');
        print('- Customer Name present: ${customerName?.isNotEmpty}');
        throw Exception('Required user information is missing');
      }

      print('\n3. PREPARING REQUEST');
      print('Form Data:');
      print('- Form Type: $formType');
      print('- Request Type: ${formType == 'request' ? requestType : 'N/A'}');
      print('- Complaint Text: ${bodyController.text}');

      final request = CustomerCareRequest(
        nationalId: nationalId,
        phone: phone,
        customerName: customerName,
        subject: formType,
        subSubject: formType == 'request' ? requestType : formType,
        complaint: bodyController.text,
      );

      print('\n4. SUBMITTING REQUEST');
      final response = await _apiService.submitCustomerCare(request);

      print('\n5. PROCESSING RESPONSE');
      print('Response success: ${response.success}');
      print('Response message: ${response.message}');
      print('Complaint number: ${response.complaintNumber}');

      if (response.success) {
        print('✅ Request submitted successfully');
        _showSuccessDialog(context, response.complaintNumber!);
      } else {
        print('❌ Request submission failed');
        _showErrorDialog(response.message);
      }
    } catch (e) {
      print('\n❌ ERROR IN FORM SUBMISSION');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: ${StackTrace.current}');
      
      _showErrorDialog(widget.isArabic 
          ? 'حدث خطأ. يرجى المحاولة مرة أخرى.'
          : 'An error occurred. Please try again.');
    } finally {
      setState(() => _isSubmitting = false);
      print('\n=== CUSTOMER CARE FORM SUBMISSION END ===\n');
    }
  }

  Future<Map<String, String>?> _showGuestUserForm() async {
    final formKey = GlobalKey<FormState>();
    final nationalIdController = TextEditingController();
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    
    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            widget.isArabic ? 'الرجاء تزويدنا بمعلوماتك' : 'Please provide your details',
            textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: widget.isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nationalIdController,
                    decoration: InputDecoration(
                      labelText: widget.isArabic ? 'رقم الهوية' : 'National/Iqama ID',
                      alignLabelWithHint: true,
                      floatingLabelAlignment: widget.isArabic ? FloatingLabelAlignment.start : FloatingLabelAlignment.start,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
                    textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return widget.isArabic ? ' رقم الهوية مطلوب' : 'ID is required';
                      }
                      if (!RegExp(r'^[12]\d{9}$').hasMatch(value)) {
                        return widget.isArabic 
                            ? 'يجب أن يبدأ رقم الهوية بـ 1 أو 2 ويتكون من 10 أرقام'
                            : 'ID should start with 1 or 2 and be 10 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: widget.isArabic ? 'رقم الجوال' : 'Phone Number',
                      hintText: widget.isArabic ? '9665xxxxxxxx' : '9665xxxxxxxx',
                      
                      alignLabelWithHint: true,
                      floatingLabelAlignment: widget.isArabic ? FloatingLabelAlignment.start : FloatingLabelAlignment.start,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
                    textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return widget.isArabic ? ' رقم الجوال مطلوب' : 'Phone number is required';
                      }
                      if (!RegExp(r'^9665\d{8}$').hasMatch(value)) {
                        return widget.isArabic 
                            ? 'يجب أن يبدأ رقم الجوال بـ 9665 ويتكون من 12 رقم'
                            : 'Phone should start with 9665 and be 12 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: widget.isArabic ? 'الاسم الكامل' : 'Full Name',
                      hintText: widget.isArabic ? 'الاسم الكامل' : 'Full Name',
                      alignLabelWithHint: true,
                      floatingLabelAlignment: widget.isArabic ? FloatingLabelAlignment.start : FloatingLabelAlignment.start,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
                    textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return widget.isArabic ? 'مطلوب الاسم الكامل' : 'Full name is required';
                      }
                      if (value.length < 3) {
                        return widget.isArabic 
                            ? 'يجب أن يتكون الاسم من 3 أحرف على الأقل'
                            : 'Name should be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(widget.isArabic ? 'إلغاء' : 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop({
                    'nationalId': nationalIdController.text,
                    'phone': phoneController.text,
                    'customerName': nameController.text,
                  });
                }
              },
              child: Text(widget.isArabic ? 'تأكيد' : 'Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final cardColor = Color(themeProvider.isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    final inputBgColor = Color(themeProvider.isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    final textColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);
    final hintColor = Color(themeProvider.isDarkMode 
        ? Constants.darkHintTextColor 
        : Constants.lightHintTextColor);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: widget.isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Constants.formBorderRadius),
              border: Border.all(
                color: Color(themeProvider.isDarkMode 
                    ? Constants.darkFormBorderColor 
                    : Constants.lightFormBorderColor),
              ),
              color: inputBgColor,
            ),
            child: Directionality(
              textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: DropdownButton<String>(
                value: formType,
                isExpanded: true,
                alignment: widget.isArabic ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                underline: const SizedBox(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: primaryColor.withOpacity(0.5),
                ),
                dropdownColor: inputBgColor,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
                selectedItemBuilder: (BuildContext context) {
                  return [
                    'complaint',
                    'request',
                    'suggestion',
                  ].map<Widget>((String item) {
                    return Container(
                      alignment: widget.isArabic ? Alignment.centerRight : Alignment.centerLeft,
                      child: Text(
                        item == 'complaint'
                            ? (widget.isArabic ? 'شكوى' : 'Complaint')
                            : item == 'request'
                                ? (widget.isArabic ? 'طلب' : 'Request')
                                : (widget.isArabic ? 'اقتراح' : 'Suggestion'),
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList();
                },
                onChanged: (String? newValue) {
                  setState(() {
                    formType = newValue!;
                    bodyController.clear();
                  });
                },
                items: [
                  DropdownMenuItem(
                    alignment: widget.isArabic ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                    value: 'complaint',
                    child: Text(
                      widget.isArabic ? 'شكوى' : 'Complaint',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    alignment: widget.isArabic ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                    value: 'request',
                    child: Text(
                      widget.isArabic ? 'طلب' : 'Request',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    alignment: widget.isArabic ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                    value: 'suggestion',
                    child: Text(
                      widget.isArabic ? 'اقتراح' : 'Suggestion',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (formType == 'request')
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                border: Border.all(
                  color: Color(themeProvider.isDarkMode 
                      ? Constants.darkFormBorderColor 
                      : Constants.lightFormBorderColor),
                ),
                color: inputBgColor,
              ),
              child: Directionality(
                textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: DropdownButton<String>(
                  value: requestType,
                  isExpanded: true,
                  alignment: widget.isArabic ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                  underline: const SizedBox(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: primaryColor.withOpacity(0.5),
                  ),
                  dropdownColor: inputBgColor,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                  selectedItemBuilder: (BuildContext context) {
                    return [
                      'loans',
                      'credit cards',
                      'sme',
                      'others',
                    ].map<Widget>((String item) {
                      return Container(
                        alignment: widget.isArabic ? Alignment.centerRight : Alignment.centerLeft,
                        child: Text(
                          item == 'loans'
                              ? (widget.isArabic ? 'تمويل' : 'Loans')
                              : item == 'credit cards'
                                  ? (widget.isArabic ? 'بطاقات الائتمان' : 'Credit Cards')
                                  : item == 'sme'
                                      ? (widget.isArabic ? 'المشاريع الصغيرة' : 'SME')
                                      : (widget.isArabic ? 'أخرى' : 'Others'),
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: textColor,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  onChanged: (String? newValue) {
                    setState(() {
                      requestType = newValue!;
                    });
                  },
                  items: [
                    DropdownMenuItem(
                      alignment: widget.isArabic ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                      value: 'loans',
                      child: Text(
                        widget.isArabic ? 'تمويل' : 'Loans',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      alignment: widget.isArabic ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                      value: 'credit cards',
                      child: Text(
                        widget.isArabic ? 'بطاقات الائتمان' : 'Credit Cards',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      alignment: widget.isArabic ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                      value: 'sme',
                      child: Text(
                        widget.isArabic ? 'المشاريع الصغيرة' : 'SME',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      alignment: widget.isArabic ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                      value: 'others',
                      child: Text(
                        widget.isArabic ? 'أخرى' : 'Others',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (formType == 'request') const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Constants.formBorderRadius),
              border: Border.all(
                color: Color(themeProvider.isDarkMode 
                    ? Constants.darkFormBorderColor 
                    : Constants.lightFormBorderColor),
              ),
              color: inputBgColor,
            ),
            child: TextFormField(
              controller: bodyController,
              maxLines: 4,
              textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
              textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return widget.isArabic 
                      ? 'هذا الحقل مطلوب'
                      : 'This field is required';
                }
                return null;
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
                hintText: formType == 'complaint'
                    ? (widget.isArabic
                        ? 'وصف الشكوى مع المنتج *'
                        : 'Describe the complaint along with the product *')
                    : formType == 'request'
                        ? (widget.isArabic
                            ? 'وصف الطلب مع المنتج *'
                            : 'Describe the request with the product *')
                        : (widget.isArabic
                            ? 'اكتب أفكارك لتحسين خدماتنا *'
                            : 'Write your ideas to improve our services *'),
                hintStyle: TextStyle(
                  color: hintColor,
                  fontSize: 14,
                ),
                alignLabelWithHint: true,
                errorStyle: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
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
              child: _isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(themeProvider.isDarkMode 
                              ? Constants.darkBackgroundColor 
                              : Constants.lightSurfaceColor),
                        ),
                      ),
                    )
                  : Text(
                      widget.isArabic ? 'إرسال' : 'Submit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(themeProvider.isDarkMode 
                            ? Constants.darkBackgroundColor 
                            : Constants.lightSurfaceColor),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
