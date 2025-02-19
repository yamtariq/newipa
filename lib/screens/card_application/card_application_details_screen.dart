import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../../widgets/custom_button.dart';
import 'card_offer_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/constants.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/document_upload_service.dart';
import '../../services/card_service.dart';
import 'package:lottie/lottie.dart';

class CardApplicationDetailsScreen extends StatefulWidget {
  final bool isArabic;
  const CardApplicationDetailsScreen({Key? key, this.isArabic = false}) : super(key: key);

  @override
  State<CardApplicationDetailsScreen> createState() => _CardApplicationDetailsScreenState();
}

class _CardApplicationDetailsScreenState extends State<CardApplicationDetailsScreen> with SingleTickerProviderStateMixin {
  final _secureStorage = const FlutterSecureStorage();
  final _cardService = CardService();
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  Map<String, String> _uploadedFiles = {};
  bool _salaryChanged = false;
  bool _consentAccepted = false;
  bool get isArabic => widget.isArabic;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      print('\n=== CARD APPLICATION DETAILS - DATA FETCH START ===');
      
      // 💡 Initialize data containers
      Map<String, dynamic> mergedData = {};
      Map<String, String> dataSource = {}; // Track where each field came from for debugging
      
      // 1. Read from FlutterSecureStorage
      final userDataStr = await _secureStorage.read(key: 'user_data');
      final registrationDataStr = await _secureStorage.read(key: 'registration_data');
      final selectedSalaryStr = await _secureStorage.read(key: 'selected_salary_data');
      final dakhliSalaryStr = await _secureStorage.read(key: 'dakhli_salary_data');
      
      print('1. Secure Storage - user_data: $userDataStr');
      print('2. Secure Storage - registration_data: $registrationDataStr');
      print('3. Secure Storage - selected_salary_data: $selectedSalaryStr');
      print('4. Secure Storage - dakhli_salary_data: $dakhliSalaryStr');

      // 2. Read from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final prefsUserDataStr = prefs.getString('user_data');
      final prefsRegistrationDataStr = prefs.getString('registration_data');
      
      print('5. SharedPreferences - user_data: $prefsUserDataStr');
      print('6. SharedPreferences - registration_data: $prefsRegistrationDataStr');

      // 3. Parse all available data
      Map<String, dynamic>? secureUserData;
      Map<String, dynamic>? secureRegistrationData;
      Map<String, dynamic>? prefsUserData;
      Map<String, dynamic>? prefsRegistrationData;
      
      try {
        if (userDataStr != null) {
          secureUserData = json.decode(userDataStr);
          print('7. Parsed secure user data: $secureUserData');
        }
      } catch (e) {
        print('Error parsing secure user data: $e');
      }
      
      try {
        if (registrationDataStr != null) {
          secureRegistrationData = json.decode(registrationDataStr);
          print('8. Parsed secure registration data: $secureRegistrationData');
        }
      } catch (e) {
        print('Error parsing secure registration data: $e');
      }
      
      try {
        if (prefsUserDataStr != null) {
          prefsUserData = json.decode(prefsUserDataStr);
          print('9. Parsed prefs user data: $prefsUserData');
        }
      } catch (e) {
        print('Error parsing prefs user data: $e');
      }
      
      try {
        if (prefsRegistrationDataStr != null) {
          prefsRegistrationData = json.decode(prefsRegistrationDataStr);
          print('10. Parsed prefs registration data: $prefsRegistrationData');
        }
      } catch (e) {
        print('Error parsing prefs registration data: $e');
      }

      // 4. Extract and merge data with priority
      
      // 4.1 Handle Names
      if (secureUserData?['fullName']?.toString().isNotEmpty == true) {
        mergedData['name'] = secureUserData!['fullName'];
        mergedData['arabic_name'] = secureUserData['arabicName'] ?? secureUserData['fullName'];
        dataSource['name'] = 'secure_user_data';
      } else if (secureRegistrationData?['userData']?['firstName']?.toString().isNotEmpty == true) {
        final userData = secureRegistrationData!['userData'];
        mergedData['name'] = '${userData['englishFirstName'] ?? ''} ${userData['englishLastName'] ?? ''}'.trim();
        mergedData['arabic_name'] = '${userData['firstName'] ?? ''} ${userData['familyName'] ?? ''}'.trim();
        dataSource['name'] = 'secure_registration_data';
      } else if (prefsRegistrationData?['userData']?['firstName']?.toString().isNotEmpty == true) {
        final userData = prefsRegistrationData!['userData'];
        mergedData['name'] = '${userData['englishFirstName'] ?? ''} ${userData['englishLastName'] ?? ''}'.trim();
        mergedData['arabic_name'] = '${userData['firstName'] ?? ''} ${userData['familyName'] ?? ''}'.trim();
        dataSource['name'] = 'prefs_registration_data';
      } else if (prefsUserData?['first_name_en']?.toString().isNotEmpty == true) {
        mergedData['name'] = '${prefsUserData!['first_name_en']} ${prefsUserData['family_name_en']}'.trim();
        mergedData['arabic_name'] = '${prefsUserData['first_name_ar']} ${prefsUserData['family_name_ar']}'.trim();
        dataSource['name'] = 'prefs_user_data';
      }

      // 4.2 Handle National ID
      mergedData['national_id'] = secureUserData?['nationalId'] ?? 
                                 secureUserData?['national_id'] ?? 
                                 secureRegistrationData?['national_id'] ?? 
                                 prefsRegistrationData?['national_id'] ?? 
                                 prefsUserData?['national_id'];
      dataSource['national_id'] = 'found_in: ${_findDataSource('national_id', secureUserData, secureRegistrationData, prefsUserData, prefsRegistrationData)}';

      // 4.3 Handle Email
      mergedData['email'] = secureUserData?['email'] ?? 
                           secureRegistrationData?['email'] ?? 
                           prefsRegistrationData?['email'] ?? 
                           prefsUserData?['email'];
      dataSource['email'] = 'found_in: ${_findDataSource('email', secureUserData, secureRegistrationData, prefsUserData, prefsRegistrationData)}';

      // 4.4 Handle Dependents
      final dependentsCount = secureRegistrationData?['userData']?['totalNumberOfCurrentDependents'] ?? 
                            prefsRegistrationData?['userData']?['totalNumberOfCurrentDependents'] ?? 
                            prefsUserData?['dependents'] ?? 
                            '0';
      mergedData['dependents'] = dependentsCount.toString();
      dataSource['dependents'] = 'found_in: ${_findDataSource('dependents', secureUserData, secureRegistrationData, prefsUserData, prefsRegistrationData)}';

      // 4.5 Handle ID Expiry Date (specific to card application)
      mergedData['id_expiry_date'] = secureRegistrationData?['userData']?['idExpiryDate'] ??
                                    secureRegistrationData?['userData']?['IdExpiryDate'] ??
                                    prefsRegistrationData?['userData']?['idExpiryDate'] ??
                                    prefsRegistrationData?['userData']?['IdExpiryDate'] ??
                                    secureUserData?['id_expiry_date'] ??
                                    prefsUserData?['id_expiry_date'];

      // 4.6 Handle Salary Data
      if (selectedSalaryStr != null) {
        final selectedSalary = json.decode(selectedSalaryStr);
        mergedData['salary'] = selectedSalary['amount']?.toString() ?? '0';
        mergedData['employer'] = selectedSalary['employer'];
        _uploadedFiles['salary'] = isArabic ? 'تم التحقق رقمياً' : 'Verified Digitally';
        dataSource['salary'] = 'selected_salary_data';
      } else if (dakhliSalaryStr != null) {
        final dakhliData = json.decode(dakhliSalaryStr);
        final salaries = List<Map<String, dynamic>>.from(dakhliData['salaries'] ?? []);
        if (salaries.isNotEmpty) {
          final highestSalary = salaries.reduce((a, b) => 
            double.parse(a['amount'].toString()) > double.parse(b['amount'].toString()) ? a : b);
          mergedData['salary'] = highestSalary['amount']?.toString() ?? '0';
          mergedData['employer'] = highestSalary['employer'];
          _uploadedFiles['salary'] = isArabic ? 'تم التحقق رقمياً' : 'Verified Digitally';
          dataSource['salary'] = 'dakhli_salary_data';
        }
      }

      // 4.7 Set default values and calculate expenses
      mergedData['salary'] ??= '0';
      double salary = double.parse(mergedData['salary']);
      mergedData['food_expense'] = (salary * 0.08).round().toString();
      mergedData['transportation_expense'] = (salary * 0.05).round().toString();
      mergedData['other_liabilities'] ??= '';

      // 4.8 Handle Name on Card (specific to card application)
      if (mergedData['nameOnCard'] == null || mergedData['nameOnCard'].toString().isEmpty) {
        String nameOnCard = mergedData['name']?.toString().trim().toUpperCase() ?? '';
        mergedData['nameOnCard'] = nameOnCard;
      }

      print('\n=== MERGED DATA SOURCES ===');
      dataSource.forEach((key, value) {
        print('$key: $value');
      });

      // 5. Update state with merged data
      setState(() {
        _userData = mergedData;
        _isLoading = false;
      });

      // 6. Sync back to secure storage if data came from SharedPreferences
      if (userDataStr == null && mergedData.isNotEmpty) {
        await _secureStorage.write(key: 'user_data', value: json.encode(mergedData));
        print('\nSynced merged data back to secure storage');
      }

      print('\n=== FINAL MERGED DATA ===');
      print(_userData);
      print('\n=== CARD APPLICATION DETAILS - DATA FETCH END ===\n');

    } catch (e) {
      print('\nERROR loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic 
              ? 'خطأ في تحميل بيانات المستخدم' 
              : 'Error loading user data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _findDataSource(String field, Map<String, dynamic>? secureUserData, 
      Map<String, dynamic>? secureRegistrationData, 
      Map<String, dynamic>? prefsUserData, 
      Map<String, dynamic>? prefsRegistrationData) {
    if (secureUserData?.containsKey(field) == true) return 'secure_user_data';
    if (secureRegistrationData?.containsKey(field) == true) return 'secure_registration_data';
    if (prefsUserData?.containsKey(field) == true) return 'prefs_user_data';
    if (prefsRegistrationData?.containsKey(field) == true) return 'prefs_registration_data';
    return 'default_value';
  }

  void _showError(String message) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.black : Colors.white,
          ),
        ),
        backgroundColor: Color(themeProvider.isDarkMode 
            ? Constants.darkPrimaryColor 
            : Constants.lightPrimaryColor),
      ),
    );
  }

  Future<void> _updateField(String field, String currentValue) async {
    print('Attempting to update field: $field with current value: $currentValue');
    print('Current uploaded files before update: $_uploadedFiles');
    
    // Remove 'SA' prefix for IBAN when showing in dialog
    if (field == 'ibanNo' && currentValue.startsWith('SA')) {
      currentValue = currentValue.substring(2);
      print('Removed SA prefix for IBAN, new value: $currentValue');
    }
    
    String? newValue = await showDialog<String>(
      context: context,
      builder: (context) => _buildUpdateDialog(field, currentValue),
    );

    if (newValue != null && newValue != currentValue) {
      print('Field $field is being updated from "$currentValue" to "$newValue"');
      setState(() {
        if (field == 'ibanNo') {
          // Ensure IBAN starts with SA and handle null safety
          String formattedIban = newValue.startsWith('SA') ? newValue : 'SA$newValue';
          print('Formatted IBAN: $formattedIban');
          _userData['ibanNo'] = formattedIban;
          // Don't reset document when IBAN is changed if we have a new document
          if (!_uploadedFiles.containsKey('ibanNo')) {
            print('No new IBAN document uploaded, keeping existing document');
          }
          print('Current uploaded files after IBAN update: $_uploadedFiles');
        } else if (field == 'salary') {
          print('Updating salary and recalculating expenses');
          // Safe parsing since we've validated the input in the dialog
          double salaryValue = double.parse(newValue);
          _userData['food_expense'] = (salaryValue * 0.08).round().toString();
          _userData['transportation_expense'] = (salaryValue * 0.05).round().toString();
          print('New food expense: ${_userData['food_expense']}');
          print('New transportation expense: ${_userData['transportation_expense']}');
          
          // Update the salary value immediately
          setState(() {
            _userData[field] = newValue;
            // Set _salaryChanged to true only if we don't have a document yet
            if (!_uploadedFiles.containsKey('salary')) {
              _salaryChanged = true;
            }
          });
        } else if (field == 'food_expense' || field == 'transportation_expense') {
          print('Updating expense field: $field');
          // Calculate total expenses
          double salary = double.parse(_userData['salary']?.toString() ?? '0');
          double otherExpense = field == 'food_expense'
              ? double.parse(_userData['transportation_expense']?.toString() ?? '0')
              : double.parse(_userData['food_expense']?.toString() ?? '0');
          double newExpense = double.parse(newValue);
          
          print('Current salary: $salary');
          print('Other expense: $otherExpense');
          print('New expense: $newExpense');
          print('Total expenses: ${newExpense + otherExpense}');
          print('90% of salary: ${salary * 0.9}');
          
          // Check if total expenses exceed 90% of salary
          if ((newExpense + otherExpense) > (salary * 0.9)) {
            print('Expense update rejected: Total expenses would exceed 90% of salary');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isArabic 
                  ? 'مجموع المصاريف لا يمكن أن يتجاوز 90٪ من الراتب'
                  : 'Total expenses cannot exceed 90% of salary'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          _userData[field] = newValue;
          print('Expense updated successfully');
        } else {
          print('Updating other field: $field');
          _userData[field] = newValue;
        }
      });
    } else {
      print('No update performed for field: $field (newValue is null or unchanged)');
    }
  }

  Widget _buildLoadingOverlay() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final surfaceColor = Color(themeProvider.isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    final textColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);

    return Stack(
      children: [
        // Semi-transparent background
        Container(
          color: Colors.black.withOpacity(0.5),
        ),
        // Loading content
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top fading logo
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Lottie.asset(
                    'assets/animations/loan_processing.json',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading animation: $error');
                      return const CircularProgressIndicator();
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isArabic ? 'جاري معالجة طلبك' : 'Processing Your Application',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  isArabic 
                    ? 'يرجى الانتظار بينما نقوم بتجهيز عرض البطاقة الخاص بك'
                    : 'Please wait while we prepare your card offer',
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Bottom rotating logo
                SizedBox(
                  width: 40,
                  height: 40,
                  child: RotationTransition(
                    turns: _rotationController,
                    child: Image.asset(
                      themeProvider.isDarkMode
                        ? 'assets/images/nayifat-circle-grey.png'
                        : 'assets/images/nayifatlogocircle-nobg.png',
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateDialog(String field, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    final bool requiresDocument = field == 'salary';
    String? fileName = _uploadedFiles[field];
    bool showDocumentUpload = field != 'salary';
    String? validationError;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          final themeProvider = Provider.of<ThemeProvider>(context);
          final primaryColor = Color(themeProvider.isDarkMode 
              ? Constants.darkPrimaryColor 
              : Constants.lightPrimaryColor);
          final backgroundColor = Color(themeProvider.isDarkMode 
              ? Constants.darkBackgroundColor 
              : Constants.lightBackgroundColor);
          final surfaceColor = Color(themeProvider.isDarkMode 
              ? Constants.darkSurfaceColor 
              : Constants.lightSurfaceColor);
          final textColor = Color(themeProvider.isDarkMode 
              ? Constants.darkLabelTextColor 
              : Constants.lightLabelTextColor);
          final borderColor = Color(themeProvider.isDarkMode 
              ? Constants.darkFormBorderColor 
              : Constants.lightFormBorderColor);
          final hintColor = Color(themeProvider.isDarkMode 
              ? Constants.darkHintTextColor 
              : Constants.lightHintTextColor);

          return AlertDialog(
            backgroundColor: surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: borderColor),
            ),
            title: Text(
              isArabic ? _getArabicFieldTitle(field) : _getEnglishFieldTitle(field),
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: isArabic ? _getArabicInputLabel(field) : field.replaceAll('_', ' ').toUpperCase(),
                    labelStyle: TextStyle(color: hintColor),
                    errorText: validationError,
                    errorMaxLines: 3,
                    errorStyle: TextStyle(
                      color: Colors.red,
                      height: 1.2,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    filled: true,
                    fillColor: surfaceColor,
                    alignLabelWithHint: true,
                  ),
                  keyboardType: _getKeyboardType(field),
                  onChanged: (value) {
                    setDialogState(() {
                      if (field == 'salary') {
                        showDocumentUpload = value != currentValue;
                        
                        if (value.isEmpty) {
                          validationError = isArabic ? 'الراتب مطلوب' : 'Salary is required';
                        } else if (!RegExp(r'^\d+$').hasMatch(value)) {
                          validationError = isArabic ? 'أرقام فقط' : 'Numbers only';
                        } else {
                          int? salary = int.tryParse(value);
                          if (salary == null || salary < 2000) {
                            validationError = isArabic ? 'الحد الأدنى 2000' : 'Minimum 2000';
                          } else {
                            validationError = null;
                            // 💡 Show document upload UI when salary is changed
                            if (showDocumentUpload && fileName == null) {
                              validationError = isArabic 
                                ? 'يجب تحميل خطاب الراتب'
                                : 'Salary letter is required';
                            }
                          }
                        }
                      } else if (field == 'email') {
                        if (value.isEmpty) {
                          validationError = isArabic ? 'البريد الإلكتروني مطلوب' : 'Email is required';
                        } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          validationError = isArabic ? 'بريد إلكتروني غير صالح' : 'Invalid email format';
                        } else {
                          validationError = null;
                        }
                      } else if (field == 'nameOnCard') {
                        if (value.isEmpty) {
                          validationError = isArabic ? 'الاسم على البطاقة مطلوب' : 'Name on card is required';
                        } else if (!RegExp(r'^[A-Z\s]+$').hasMatch(value)) {
                          validationError = isArabic 
                            ? 'يجب أن يحتوي الاسم على أحرف إنجليزية كبيرة فقط'
                            : 'Name must contain only capital English letters';
                        } else if (value.length > 26) {
                          validationError = isArabic
                            ? 'يجب ألا يتجاوز الاسم 26 حرفاً'
                            : 'Name cannot exceed 26 characters';
                        } else {
                          validationError = null;
                        }
                      } else if (field == 'food_expense' || field == 'transportation_expense') {
                        // Get the minimum allowed value (current calculated value)
                        double salary = double.parse(_userData['salary']?.toString() ?? '0');
                        double minValue = field == 'food_expense' 
                          ? salary * 0.08 
                          : salary * 0.05;
                        
                        // Get the other expense value
                        double otherExpense = field == 'food_expense'
                          ? double.parse(_userData['transportation_expense']?.toString() ?? '0')
                          : double.parse(_userData['food_expense']?.toString() ?? '0');
                        
                        if (value.isEmpty) {
                          validationError = isArabic ? 'القيمة مطلوبة' : 'Value is required';
                        } else if (!RegExp(r'^\d+$').hasMatch(value)) {
                          validationError = isArabic ? 'أرقام فقط' : 'Numbers only';
                        } else {
                          double newValue = double.parse(value);
                          if (newValue < minValue) {
                            validationError = isArabic 
                              ? 'لا يمكن أن تكون القيمة أقل من ${minValue.round()}'
                              : 'Value cannot be less than ${minValue.round()}';
                          } else if ((newValue + otherExpense) > (salary * 0.9)) {
                            validationError = isArabic
                              ? 'مجموع المصاريف لا يمكن أن يتجاوز 90٪ من الراتب'
                              : 'Total expenses cannot exceed 90% of salary';
                          } else {
                            validationError = null;
                          }
                        }
                      }
                    });
                  },
                ),
                if (requiresDocument && showDocumentUpload) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                        );
                        
                        if (result != null) {
                          final file = result.files.single;
                          
                          // Check file size (max 10MB)
                          if (file.size > 10 * 1024 * 1024) {
                            setDialogState(() {
                              validationError = isArabic 
                                ? 'يجب أن يكون حجم الملف أقل من 10 ميجابايت'
                                : 'File size must be less than 10MB';
                            });
                            return;
                          }

                          // 💡 Upload document
                          final documentUploadService = DocumentUploadService();
                          final nationalId = _userData['national_id']?.toString() ?? '';
                          
                          if (nationalId.isEmpty) {
                            setDialogState(() {
                              validationError = isArabic 
                                ? 'لم يتم العثور على رقم الهوية'
                                : 'National ID not found';
                            });
                            return;
                          }

                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) => _buildLoadingOverlay(),
                          );

                          // Upload document
                          final success = await documentUploadService.uploadDocument(
                            nationalId: nationalId,
                            documentType: field,
                            filePath: file.path!,
                            fileName: file.name,
                            productType: 'card',
                          );

                          // Hide loading dialog
                          Navigator.of(context).pop();

                          if (success) {
                            setDialogState(() {
                              fileName = file.name;
                              validationError = null;
                            });
                            _uploadedFiles[field] = file.name;
                          } else {
                            setDialogState(() {
                              validationError = isArabic 
                                ? 'فشل تحميل المستند. الرجاء المحاولة مرة أخرى'
                                : 'Failed to upload document. Please try again';
                            });
                          }
                        }
                      } catch (e) {
                        print('Error picking/uploading file: $e');
                        setDialogState(() {
                          validationError = isArabic 
                            ? 'خطأ في تحميل الملف: ${e.toString()}'
                            : 'Error uploading file: ${e.toString()}';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: themeProvider.isDarkMode ? backgroundColor : surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text(fileName ?? (field == 'salary' 
                      ? (isArabic ? 'تحميل خطاب الراتب (مطلوب للتحديث)' : 'Upload Salary Letter (Required for Update)')
                      : '')),
                  ),
                  if (fileName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        fileName ?? '',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      ),
                    ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: hintColor,
                ),
                child: Text(isArabic ? 'إلغاء' : 'Cancel'),
              ),
              TextButton(
                onPressed: validationError != null
                    ? null
                    : () {
                        String finalValue = controller.text;
                        if (field == 'salary' && finalValue != currentValue) {
                          if (fileName == null) {
                            setDialogState(() {
                              validationError = isArabic 
                                ? 'يجب تحميل خطاب الراتب'
                                : 'Salary letter is required';
                            });
                            return;
                          }
                        }
                        Navigator.pop(context, finalValue);
                      },
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  disabledForegroundColor: hintColor,
                ),
                child: Text(
                  isArabic ? 'تحديث' : 'Update',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getEnglishFieldTitle(String field) {
    switch (field) {
      case 'salary':
        return 'Update Salary';
      case 'food_expense':
        return 'Update Food Expenses';
      case 'transportation_expense':
        return 'Update Transportation Expenses';
      case 'other_liabilities':
        return 'Update Other Liabilities';
      case 'email':
        return 'Update Email';
      default:
        return 'Update ${field.replaceAll('_', ' ').toUpperCase()}';
    }
  }

  String _getArabicFieldTitle(String field) {
    switch (field) {
      case 'salary':
        return 'تحديث الراتب';
      case 'food_expense':
        return 'تحديث مصاريف الطعام';
      case 'transportation_expense':
        return 'تحديث مصاريف المواصلات';
      case 'other_liabilities':
        return 'تحديث الالتزامات الأخرى';
      case 'email':
        return 'تحديث البريد الإلكتروني';
      default:
        return 'تحديث ${field.replaceAll('_', ' ')}';
    }
  }

  TextInputType _getKeyboardType(String field) {
    switch (field) {
      case 'salary':
      case 'food_expense':
      case 'transportation_expense':
      case 'other_liabilities':
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  Widget _buildInfoField(String label, String? value, {
    bool editable = false,
    String? fieldName,
    bool isRequired = true,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final textColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);
    final hintColor = Color(themeProvider.isDarkMode 
        ? Constants.darkHintTextColor 
        : Constants.lightHintTextColor);
    final borderColor = Color(themeProvider.isDarkMode 
        ? Constants.darkFormBorderColor 
        : Constants.lightFormBorderColor);
    final surfaceColor = Color(themeProvider.isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);

    String arabicLabel = _getArabicLabel(label);

    // 💡 Special handling for name on card field with improved error styling
    if (fieldName == 'nameOnCard') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${isArabic ? arabicLabel : label} ${isRequired ? '*' : ''}',
              style: TextStyle(
                fontSize: 14,
                color: hintColor,
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              initialValue: value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: isArabic ? 'أدخل الاسم باللغة الإنجليزية' : 'Enter name in English',
                hintStyle: TextStyle(color: hintColor),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryColor),
                ),
              ),
              onChanged: (newValue) {
                String? errorMessage;
                if (newValue.isEmpty) {
                  errorMessage = isArabic 
                    ? 'الاسم على البطاقة مطلوب'
                    : 'Name on card is required';
                } else if (!RegExp(r'^[A-Z\s]+$').hasMatch(newValue)) {
                  errorMessage = isArabic 
                    ? 'يجب أن يحتوي الاسم على أحرف إنجليزية كبيرة فقط'
                    : 'Name must contain only capital English letters';
                } else if (newValue.length > 26) {
                  errorMessage = isArabic
                    ? 'يجب ألا يتجاوز الاسم 26 حرفاً'
                    : 'Name cannot exceed 26 characters';
                }

                if (errorMessage != null) {
                  // Show error in a beautiful container
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      backgroundColor: Colors.red.shade700,
                      duration: const Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.height - 150,
                        left: 16,
                        right: 16,
                      ),
                    ),
                  );
                }
                setState(() {
                  _userData['nameOnCard'] = newValue;
                });
              },
            ),
            Divider(color: hintColor.withOpacity(0.5)),
          ],
        ),
      );
    }
    
    // Regular fields
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${isArabic ? arabicLabel : label} ${isRequired ? '*' : ''}',
            style: TextStyle(
              fontSize: 14,
              color: hintColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (editable)
                IconButton(
                  icon: Icon(Icons.edit, color: primaryColor),
                  onPressed: () => _updateField(
                    fieldName ?? label.toLowerCase().replaceAll(' ', '_'), 
                    value ?? ''
                  ),
                ),
            ],
          ),
          Divider(color: hintColor.withOpacity(0.5)),
        ],
      ),
    );
  }

  String _getArabicLabel(String englishLabel) {
    switch (englishLabel) {
      case 'Name':
        return 'الاسم';
      case 'National ID':
        return 'رقم الهوية';
      case 'Email':
        return 'البريد الإلكتروني';
      case 'Salary':
        return 'الراتب';
      case 'Food Expense':
        return 'مصاريف الطعام';
      case 'Transportation Expense':
        return 'مصاريف المواصلات';
      case 'Other Liabilities':
        return 'إلتزامات أخرى';
      case 'Number of Dependents':
        return 'عدد المعالين';
      case 'Name on Card':
        return 'الاسم على البطاقة';
      default:
        return englishLabel;
    }
  }

  String _getArabicInputLabel(String field) {
    switch (field) {
      case 'salary':
        return 'الراتب';
      case 'food_expense':
        return 'مصاريف الطعام';
      case 'transportation_expense':
        return 'مصاريف المواصلات';
      case 'other_liabilities':
        return 'إلتزامات أخرى';
      case 'email':
        return 'البريد الإلكتروني';
      case 'nameOnCard':
        return 'الاسم على البطاقة';
      default:
        return field;
    }
  }

  Widget _buildDocumentsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final textColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'المستندات المطلوبة' : 'Required Documents',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildDocumentUpload(
          'National ID',
          _uploadedFiles['national_id'],
          () => _pickFile('national_id'),
          required: true,
        ),
        if (_salaryChanged || _uploadedFiles.containsKey('salary'))
          _buildDocumentUpload(
            'Salary Letter',
            _uploadedFiles['salary'],
            _uploadedFiles.containsKey('salary') ? null : () => _pickFile('salary'),
            required: false,
            placeholder: _uploadedFiles.containsKey('salary') 
              ? (isArabic ? 'تم تحميل المستند' : 'Document uploaded')
              : null,
          ),
      ],
    );
  }

  Widget _buildDocumentUpload(String label, String? fileName, VoidCallback? onTap, {
    bool required = false,
    String? placeholder,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final textColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);
    final surfaceColor = Color(themeProvider.isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    final borderColor = Color(themeProvider.isDarkMode 
        ? Constants.darkFormBorderColor 
        : Constants.lightFormBorderColor);

    String arabicLabel = _getArabicDocumentLabel(label);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${isArabic ? arabicLabel : label} ${required ? '*' : ''}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(8),
                color: onTap == null ? surfaceColor.withOpacity(0.5) : null,
              ),
              child: Row(
                children: [
                  Icon(Icons.upload_file, color: textColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName ?? placeholder ?? (isArabic ? 'اختر ملف' : 'Choose File'),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onTap == null ? textColor.withOpacity(0.6) : textColor,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getArabicDocumentLabel(String englishLabel) {
    switch (englishLabel) {
      case 'National ID':
        return 'بطاقة الهوية';
      case 'Salary Letter':
        return 'خطاب الراتب';
      default:
        return englishLabel;
    }
  }

  Widget _buildUploadOverlay(BuildContext context, {required bool isArabic}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final surfaceColor = Color(themeProvider.isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    final textColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isArabic ? 'جاري تحميل المستند' : 'Uploading document',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic ? 'يرجى الانتظار' : 'Please wait',
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 14,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile(String field) async {
    print('Picking file for field: $field');
    print('Current uploaded files before picking: $_uploadedFiles');
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowCompression: true,
        withData: true,
        onFileLoading: (FilePickerStatus status) {
          if (status == FilePickerStatus.picking) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) => _buildUploadOverlay(context, isArabic: isArabic),
            );
          } else {
            Navigator.of(context).pop();
          }
        },
      );

      if (result != null) {
        final file = result.files.single;
        // Check file size (max 10MB)
        if (file.size > 10 * 1024 * 1024) {
          _showError(isArabic ? 'يجب أن يكون حجم الملف أقل من 10 ميجابايت' : 'File size must be less than 10MB');
          return;
        }

        // 💡 Upload document to server
        final documentUploadService = DocumentUploadService();
        final nationalId = _userData['national_id']?.toString() ?? '';
        
        if (nationalId.isEmpty) {
          _showError(isArabic ? 'لم يتم العثور على رقم الهوية' : 'National ID not found');
          return;
        }

        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => _buildUploadOverlay(context, isArabic: isArabic),
        );

        // Upload document
        final success = await documentUploadService.uploadDocument(
          nationalId: nationalId,
          documentType: field,
          filePath: file.path!,
          fileName: file.name,
          productType: 'card',
        );

        // Hide loading dialog
        Navigator.of(context).pop();

        if (success) {
          setState(() {
            _uploadedFiles[field] = file.name;
            print('File picked and uploaded successfully. Updated uploaded files: $_uploadedFiles');
            // Only reset salary changed flag for salary document
            if (field == 'salary') {
              _salaryChanged = false;
            }
          });
        } else {
          _showError(isArabic 
            ? 'فشل تحميل المستند. الرجاء المحاولة مرة أخرى'
            : 'Failed to upload document. Please try again');
        }
      } else {
        print('User canceled file picking');
      }
    } catch (e) {
      print('Error picking file: $e');
      _showError(isArabic 
        ? 'خطأ في اختيار الملف: ${e.toString()}'
        : 'Error picking file: ${e.toString()}');
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
    final surfaceColor = Color(themeProvider.isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    final textColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: _buildLoadingOverlay(),
      );
    }

    bool canProceed = _userData['national_id'] != null &&
                      _userData['email'] != null &&
                      _userData['salary'] != null &&
                      _uploadedFiles['national_id'] != null &&
                      _consentAccepted;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor.withOpacity(0.1),
                    backgroundColor,
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Back Button and Title Row
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              onPressed: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              },
                              icon: Icon(
                                isArabic ? Icons.arrow_back_ios : Icons.arrow_back_ios,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        // Title
                        Text(
                          isArabic ? 'تفاصيل الطلب' : 'Application Details',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Personal Information Section
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(themeProvider.isDarkMode 
                                        ? Constants.darkPrimaryShadowColor 
                                        : Constants.lightPrimaryShadowColor),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoField('Name', isArabic ? _userData['arabic_name']?.toString() ?? '' : _userData['name']?.toString() ?? ''),
                                  _buildInfoField('National ID', _userData['national_id']?.toString() ?? ''),
                                  _buildInfoField('Email', _userData['email']?.toString() ?? '', editable: true),
                                  _buildInfoField('Number of Dependents', _userData['dependents']?.toString() ?? '0', editable: false, fieldName: 'dependents'),
                                  _buildInfoField(
                                    'Salary', 
                                    double.parse(_userData['salary']?.toString() ?? '0').round().toString(), 
                                    editable: true
                                  ),
                                  _buildInfoField(
                                    'Name on Card',
                                    _userData['nameOnCard']?.toString() ?? '',
                                    editable: true,
                                    fieldName: 'nameOnCard',
                                    isRequired: true
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Expenses Section
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(themeProvider.isDarkMode 
                                        ? Constants.darkPrimaryShadowColor 
                                        : Constants.lightPrimaryShadowColor),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isArabic ? 'المصروفات الشهرية' : 'Monthly Expenses',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoField(
                                    'Food Expense', 
                                    double.parse(_userData['food_expense']?.toString() ?? '0').round().toString(), 
                                    editable: true
                                  ),
                                  _buildInfoField(
                                    'Transportation Expense', 
                                    double.parse(_userData['transportation_expense']?.toString() ?? '0').round().toString(), 
                                    editable: true
                                  ),
                                  _buildInfoField(
                                    'Other Liabilities', 
                                    _userData['other_liabilities']?.toString() ?? '',
                                    editable: true,
                                    fieldName: 'other_liabilities',
                                    isRequired: false
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Documents Section
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(themeProvider.isDarkMode 
                                        ? Constants.darkPrimaryShadowColor 
                                        : Constants.lightPrimaryShadowColor),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: _buildDocumentsSection(),
                            ),
                            const SizedBox(height: 32),

                            // Consent Section
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(themeProvider.isDarkMode 
                                        ? Constants.darkPrimaryShadowColor 
                                        : Constants.lightPrimaryShadowColor),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _consentAccepted,
                                          onChanged: (value) {
                                            setState(() {
                                              _consentAccepted = value ?? false;
                                            });
                                          },
                                          activeColor: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          isArabic
                                              ? 'أقر بأن جميع المعلومات المقدمة صحيحة وكاملة'
                                              : 'I declare that all provided information is true and complete',
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Next Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: CustomButton(
                                onPressed: (_isLoading || !canProceed) ? null : _handleNextButtonClick,
                                text: isArabic ? 'التالي' : 'Next',
                                backgroundColor: primaryColor,
                                textColor: Colors.white,
                                width: double.infinity,
                              ),
                            ),
                          ],
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
    );
  }

  Future<void> _handleNextButtonClick() async {
    try {
      // 💡 Validate name on card first
      if (_userData['nameOnCard']?.toString().trim().isEmpty ?? true) {
        _showError(isArabic 
          ? 'الاسم على البطاقة مطلوب'
          : 'Name on card is required');
        return;
      }

      if (!RegExp(r'^[A-Z\s]+$').hasMatch(_userData['nameOnCard'])) {
        _showError(isArabic 
          ? 'يجب أن يحتوي الاسم على أحرف إنجليزية كبيرة فقط'
          : 'Name must contain only capital English letters');
        return;
      }

      if (_userData['nameOnCard'].length > 26) {
        _showError(isArabic
          ? 'يجب ألا يتجاوز الاسم 26 حرفاً'
          : 'Name cannot exceed 26 characters');
        return;
      }

      setState(() => _isLoading = true);

      print('\n=== CARD APPLICATION REQUEST START ===');
      print('Preparing request data...');
      
      // Log all user data being sent
      print('\nUser Data being sent:');
      print('- Name: ${_userData['name']}');
      print('- Arabic Name: ${_userData['arabic_name']}');
      print('- National ID: ${_userData['national_id']}');
      print('- Email: ${_userData['email']}');
      print('- Phone: ${_userData['phone']}');
      print('- Date of Birth: ${_userData['date_of_birth']}');
      print('- Salary: ${_userData['salary']}');
      print('- Food Expense: ${_userData['food_expense']}');
      print('- Transportation Expense: ${_userData['transportation_expense']}');
      print('- Other Liabilities: ${_userData['other_liabilities']}');
      print('- Dependents: ${_userData['dependents']}');
      print('- Name on Card: ${_userData['nameOnCard']}');
      
      print('\nUploaded Documents:');
      _uploadedFiles.forEach((key, value) {
        print('- $key: $value');
      });

      // Call the card service to create customer request
      print('\nCalling CardService.createCustomerCardRequest...');
      final response = await _cardService.createCustomerCardRequest(_userData, isArabic);
      
      print('\nAPI Response received:');
      print('Response Data: $response');

      if (!mounted) return;

      setState(() => _isLoading = false);

      // 💡 Handle null response
      if (response == null) {
        _showError(isArabic 
          ? 'حدث خطأ أثناء إنشاء طلب البطاقة'
          : 'Error creating card request: No response received');
        return;
      }

      // 💡 Handle error response
      if (response['status'] == 'error') {
        print('\nError in response:');
        print('Status: ${response['status']}');
        print('Message: ${response['message']}');
        print('=== CARD APPLICATION REQUEST END (WITH ERROR) ===\n');
        
        // If it's a server error or requires support contact, navigate to card offer screen with error details
        if (response['error_type'] == 'SERVER_ERROR' || 
            response['error_type'] == 'NOT_ELIGIBLE' || 
            response['should_contact_support'] == true) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CardOfferScreen(
                userData: {
                  ...response,
                  'national_id': _userData['national_id'],
                  'nameOnCard': _userData['nameOnCard'],
                },
                isArabic: isArabic,
                maxCreditLimit: 0,
                minCreditLimit: 0,
              ),
            ),
          );
          return;
        }
        
        // For other errors, show error message
        _showError(isArabic 
          ? (response['message_ar'] ?? response['message'] ?? 'حدث خطأ أثناء إنشاء طلب البطاقة')
          : (response['message'] ?? 'Error creating card request'));
        return;
      }

      print('\nSuccessful response:');
      print('Credit Limit: ${response['credit_limit']}');
      print('Application Number: ${response['application_number']}');
      print('=== CARD APPLICATION REQUEST END (SUCCESS) ===\n');

      // Navigate to offer screen
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CardOfferScreen(
            userData: {
              ...response, // Include all response data
              'national_id': _userData['national_id'],  // Add national_id
              'application_number': response['application_number'],
              'card_type': response['card_type'],
              'card_type_ar': response['card_type_ar'],
              'nameOnCard': _userData['nameOnCard'], // Pass name on card
            },
            isArabic: isArabic,
            maxCreditLimit: response['credit_limit']?.toInt() ?? 0,
            minCreditLimit: 0,
          ),
        ),
      );

    } catch (e) {
      print('\nException caught:');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');
      print('=== CARD APPLICATION REQUEST END (WITH EXCEPTION) ===\n');
      
      setState(() => _isLoading = false);
      _showError(isArabic 
        ? 'حدث خطأ أثناء إنشاء طلب البطاقة' 
        : 'Error creating card request: $e');
    }
  }
} 