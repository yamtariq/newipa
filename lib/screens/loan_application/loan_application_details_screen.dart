import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../../widgets/custom_button.dart';
import 'loan_offer_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/constants.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/document_upload_service.dart';
import '../../services/loan_service.dart';
import 'package:lottie/lottie.dart';
import 'loan_application_status_screen.dart';

class LoanApplicationDetailsScreen extends StatefulWidget {
  final bool isArabic;
  const LoanApplicationDetailsScreen({Key? key, this.isArabic = false}) : super(key: key);

  @override
  State<LoanApplicationDetailsScreen> createState() => _LoanApplicationDetailsScreenState();
}

class _LoanApplicationDetailsScreenState extends State<LoanApplicationDetailsScreen> with SingleTickerProviderStateMixin {
  final _secureStorage = const FlutterSecureStorage();
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
      print('\n=== LOAN APPLICATION DETAILS - DATA FETCH START ===');
      
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

      // 4.5 Handle Salary Data
      if (selectedSalaryStr != null) {
        final selectedSalary = json.decode(selectedSalaryStr);
        mergedData['salary'] = selectedSalary['amount']?.toString() ?? '0';
        mergedData['employer'] = selectedSalary['employer'];
        _uploadedFiles['salary'] = 'Verified Digitally';
        dataSource['salary'] = 'selected_salary_data';
      } else if (dakhliSalaryStr != null) {
        final dakhliData = json.decode(dakhliSalaryStr);
        final salaries = List<Map<String, dynamic>>.from(dakhliData['salaries'] ?? []);
        if (salaries.isNotEmpty) {
          final highestSalary = salaries.reduce((a, b) => 
            double.parse(a['amount'].toString()) > double.parse(b['amount'].toString()) ? a : b);
          mergedData['salary'] = highestSalary['amount']?.toString() ?? '0';
          mergedData['employer'] = highestSalary['employer'];
          _uploadedFiles['salary'] = 'Verified Digitally';
          dataSource['salary'] = 'dakhli_salary_data';
        }
      }

      // 4.6 Set default values for missing fields
      mergedData['salary'] ??= '0';
      mergedData['loan_purpose'] ??= isArabic ? 'أسهم' : 'Stocks';
      
      // Calculate expenses based on salary
      double salary = double.parse(mergedData['salary']);
      mergedData['food_expense'] = (salary * 0.08).round().toString();
      mergedData['transportation_expense'] = (salary * 0.05).round().toString();
      mergedData['other_liabilities'] ??= '';

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
      print('\n=== LOAN APPLICATION DETAILS - DATA FETCH END ===\n');

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
    final surfaceColor = Color(themeProvider.isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    final textColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: surfaceColor),
        ),
        backgroundColor: textColor,
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
          _showError('File size must be less than 10MB');
          return;
        }

        // 💡 Upload document to server
        final documentUploadService = DocumentUploadService();
        final nationalId = _userData['national_id']?.toString() ?? '';
        
        if (nationalId.isEmpty) {
          _showError('National ID not found');
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
          productType: 'loan',
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
      _showError('Error picking file: ${e.toString()}');
    }
  }

  Widget _buildUpdateDialog(String field, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    final bool requiresDocument = field == 'salary' || field == 'ibanNo';
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
          final surfaceColor = Color(themeProvider.isDarkMode 
              ? Constants.darkSurfaceColor 
              : Constants.lightSurfaceColor);
          final textColor = Color(themeProvider.isDarkMode 
              ? Constants.darkLabelTextColor 
              : Constants.lightLabelTextColor);
          final hintColor = Color(themeProvider.isDarkMode 
              ? Constants.darkHintTextColor 
              : Constants.lightHintTextColor);
          final borderColor = Color(themeProvider.isDarkMode 
              ? Constants.darkFormBorderColor 
              : Constants.lightFormBorderColor);
          final errorColor = Color(themeProvider.isDarkMode 
              ? Constants.darkErrorColor 
              : Constants.lightErrorColor);
          final disabledColor = Color(themeProvider.isDarkMode 
              ? Constants.darkFormBackgroundColor 
              : Constants.lightFormBackgroundColor);

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
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (field == 'ibanNo')
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      textDirection: TextDirection.ltr,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: disabledColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                          child: Text(
                            'SA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            textAlign: TextAlign.left,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: isArabic ? 'أدخل ٢٢ رقم' : 'Enter 22 digits',
                              hintStyle: TextStyle(color: hintColor),
                              errorText: validationError,
                              errorStyle: TextStyle(
                                color: errorColor,
                                height: 1.2,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              String cleanValue = value.replaceAll(RegExp(r'\D'), '');
                              if (cleanValue != value) {
                                controller.text = cleanValue;
                                controller.selection = TextSelection.fromPosition(
                                  TextPosition(offset: cleanValue.length)
                                );
                              }
                              
                              setDialogState(() {
                                if (cleanValue.isEmpty) {
                                  validationError = isArabic ? 'رقم الآيبان مطلوب' : 'IBAN is required';
                                } else if (cleanValue.length != 22) {
                                  validationError = isArabic 
                                    ? 'يجب أن يكون ٢٢ رقم (${cleanValue.length}/22)'
                                    : 'Must be 22 digits (${cleanValue.length}/22)';
                                } else {
                                  validationError = null;
                                }
                              });
                            },
                            maxLength: 22,
                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  TextField(
                    controller: controller,
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: isArabic ? _getArabicInputLabel(field) : field.replaceAll('_', ' ').toUpperCase(),
                      labelStyle: TextStyle(color: hintColor),
                      errorText: validationError,
                      errorStyle: TextStyle(
                        color: errorColor,
                        height: 1.2,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: errorColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: errorColor),
                        borderRadius: BorderRadius.circular(4),
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
                if (requiresDocument && (showDocumentUpload || field == 'ibanNo')) ...[
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
                            builder: (BuildContext context) => _buildUploadOverlay(context, isArabic: isArabic),
                          );

                          // Upload document
                          final success = await documentUploadService.uploadDocument(
                            nationalId: nationalId,
                            documentType: field,
                            filePath: file.path!,
                            fileName: file.name,
                            productType: 'loan',
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
                      foregroundColor: surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text(fileName ?? (field == 'salary' 
                      ? (isArabic ? 'تحميل خطاب الراتب (مطلوب للتحديث)' : 'Upload Salary Letter (Required for Update)')
                      : (isArabic ? 'تحميل شهادة الآيبان (مطلوب)' : 'Upload IBAN Certificate (Required)'))),
                  ),
                  if (fileName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        fileName ?? '',
                        style: TextStyle(
                          color: primaryColor,
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
                onPressed: () {
                  if (field == 'ibanNo' && fileName != null && fileName != _uploadedFiles['ibanNo']) {
                    setState(() {
                      _uploadedFiles.remove('ibanNo');
                    });
                  }
                  Navigator.pop(context);
                },
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
                        if (field == 'ibanNo') {
                          finalValue = 'SA$finalValue';
                          if (fileName != null) {
                            setState(() {
                              _uploadedFiles['ibanNo'] = fileName!;
                            });
                          }
                        } else if (field == 'salary' && finalValue != currentValue) {
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
      case 'loan_purpose':
        return 'Update Loan Purpose';
      case 'ibanNo':
        return 'Update IBAN';
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
      case 'loan_purpose':
        return 'تحديث الغرض من التمويل';
      case 'ibanNo':
        return 'تحديث رقم الآيبان';
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
      case 'ibanNo':
      case 'food_expense':
      case 'transportation_expense':
      case 'other_liabilities':
        return TextInputType.number;
      case 'loan_purpose':
        return TextInputType.text;
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

    // Get Arabic label based on field name
    String arabicLabel = _getArabicLabel(label);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${isArabic ? arabicLabel : label}${isRequired ? ' *' : ''}',
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
      case 'Loan Purpose':
        return 'الغرض من التمويل';
      case 'Email':
        return 'البريد الإلكتروني';
      case 'Salary':
        return 'الراتب';
      case 'IBAN':
        return 'رقم الآيبان';
      case 'Food Expense':
        return 'مصاريف الطعام';
      case 'Transportation Expense':
        return 'مصاريف المواصلات';
      case 'Other Liabilities':
        return 'إلتزامات أخرى';
      case 'Number of Dependents':
        return 'عدد المعالين';
      default:
        return englishLabel;
    }
  }

  String _getArabicInputLabel(String field) {
    switch (field) {
      case 'salary':
        return 'الراتب';
      case 'ibanNo':
        return 'رقم الآيبان';
      case 'food_expense':
        return 'مصاريف الطعام';
      case 'transportation_expense':
        return 'مصاريف المواصلات';
      case 'other_liabilities':
        return 'إلتزامات أخرى';
      case 'email':
        return 'البريد الإلكتروني';
      case 'loan_purpose':
        return 'الغرض من التمويل';
      case 'dependents':
        return 'عدد المعالين';
      default:
        return field;
    }
  }

  Widget _buildDocumentsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);

    print('Building documents section. Current uploaded files: $_uploadedFiles');
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
        // National ID
        _buildDocumentUpload(
          'National ID',
          _uploadedFiles['national_id'],
          () {
            print('National ID upload clicked');
            _pickFile('national_id');
          },
          required: true,
        ),
        // IBAN Certificate
        _buildDocumentUpload(
          'IBAN Certificate',
          _uploadedFiles['ibanNo'],
          () {
            print('IBAN upload clicked');
            _pickFile('ibanNo');
          },
          required: true,
        ),
        // Salary Document (only if salary was changed)
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
    final hintColor = Color(themeProvider.isDarkMode 
        ? Constants.darkHintTextColor 
        : Constants.lightHintTextColor);
    final borderColor = Color(themeProvider.isDarkMode 
        ? Constants.darkFormBorderColor 
        : Constants.lightFormBorderColor);
    final disabledColor = Color(themeProvider.isDarkMode 
        ? Constants.darkFormBackgroundColor 
        : Constants.lightFormBackgroundColor);

    // Get Arabic label for documents
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
                color: onTap == null ? disabledColor : null,
              ),
              child: Row(
                children: [
                  Icon(Icons.upload_file, color: onTap == null ? hintColor : primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName ?? placeholder ?? (isArabic ? 'اختر ملف' : 'Choose File'),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onTap == null ? hintColor : textColor,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios, size: 16, color: primaryColor),
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
      case 'IBAN Certificate':
        return 'شهادة الآيبان';
      case 'Salary Letter':
        return 'خطاب الراتب';
      default:
        return englishLabel;
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
                    ? 'يرجى الانتظار بينما نقوم بتجهيز عرض التمويل الخاص بك'
                    : 'Please wait while we prepare your finance offer',
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
                      _userData['ibanNo'] != null &&
                      _uploadedFiles['national_id'] != null &&
                      _uploadedFiles['ibanNo'] != null &&
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
                                    color: primaryColor.withOpacity(0.05),
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
                                  _buildInfoField('Loan Purpose', _userData['loan_purpose']?.toString() ?? (isArabic ? 'أسهم' : 'Stocks'), editable: true, fieldName: 'loan_purpose'),
                                  _buildInfoField('Email', _userData['email']?.toString() ?? '', editable: true),
                                  _buildInfoField('Number of Dependents', _userData['dependents']?.toString() ?? '0', editable: false, fieldName: 'dependents'),
                                  _buildInfoField(
                                    'Salary', 
                                    double.parse(_userData['salary']?.toString() ?? '0').round().toString(), 
                                    editable: true
                                  ),
                                  _buildInfoField(
                                    'IBAN', 
                                    _userData['ibanNo']?.toString() ?? '', 
                                    editable: true,
                                    fieldName: 'ibanNo'
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
                                    color: primaryColor.withOpacity(0.05),
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
                                    color: primaryColor.withOpacity(0.05),
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
                                    color: primaryColor.withOpacity(0.05),
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
                              child: ElevatedButton(
                                onPressed: canProceed ? () async {
                                  try {
                                    setState(() => _isLoading = true);
                                    
                                    print('\n=== LOAN APPLICATION NEXT BUTTON CLICKED ===');
                                    print('Timestamp: ${DateTime.now()}');
                                    
                                    // Call the loan service to create request
                                    final loanService = LoanService();
                                    final response = await loanService.createCustomerLoanRequest(
                                      _userData,
                                      isArabic
                                    );
                                    
                                    if (!mounted) return;

                                    // 💡 Handle different response types
                                    if (response['status'] == 'error') {
                                      // Check if it's a rejection (2-203) or other error
                                      final errorCode = response['errorCode'] as String?;
                                      final isRejection = errorCode == '2-203';

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LoanApplicationStatusScreen(
                                            isArabic: isArabic,
                                            isRejected: isRejection,
                                            errorCode: errorCode,
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    
                                    // If we reach here, it's an approval - navigate to offer screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LoanOfferScreen(
                                          userData: response,
                                          isArabic: isArabic,
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    print('Error creating loan request: $e');
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isArabic 
                                              ? 'حدث خطأ أثناء إنشاء طلب التمويل'
                                              : 'Error creating loan request',
                                            textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                } : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  disabledBackgroundColor: primaryColor.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 5,
                                  shadowColor: primaryColor.withOpacity(0.5),
                                ),
                                child: Text(
                                  isArabic ? 'التالي' : 'Next',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: surfaceColor,
                                  ),
                                ),
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
} 