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

class CardApplicationDetailsScreen extends StatefulWidget {
  final bool isArabic;
  const CardApplicationDetailsScreen({Key? key, this.isArabic = false}) : super(key: key);

  @override
  State<CardApplicationDetailsScreen> createState() => _CardApplicationDetailsScreenState();
}

class _CardApplicationDetailsScreenState extends State<CardApplicationDetailsScreen> {
  final _secureStorage = const FlutterSecureStorage();
  final _cardService = CardService();
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  Map<String, String> _uploadedFiles = {};
  bool _salaryChanged = false;
  bool _consentAccepted = false;
  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      print('\n=== CARD APPLICATION DETAILS - DATA FETCH START ===');
      
      // 💡 First try secure storage for user data
      final userDataStr = await _secureStorage.read(key: 'user_data');
      print('1. Secure Storage - user_data: $userDataStr');
      
      // 💡 Get salary data from secure storage
      String? selectedSalaryStr = await _secureStorage.read(key: 'selected_salary_data');
      print('2. Secure Storage - selected_salary_data: $selectedSalaryStr');
      
      String? dakhliSalaryStr = await _secureStorage.read(key: 'dakhli_salary_data');
      print('3. Secure Storage - dakhli_salary_data: $dakhliSalaryStr');
      
      // 💡 Get registration data from SharedPreferences with correct key
      final prefs = await SharedPreferences.getInstance();
      final registrationDataStr = prefs.getString('registration_data');
      int? dependentsCount;
      
      if (registrationDataStr != null) {
        try {
          final registrationData = json.decode(registrationDataStr);
          print('4. Registration data found: ${registrationData['userData']}');
          if (registrationData['userData'] != null) {
            dependentsCount = registrationData['userData']['totalNumberOfCurrentDependents'] as int?;
            print('5. Found dependents count: $dependentsCount');
          }
        } catch (e) {
          print('Error parsing registration data: $e');
        }
      }
      
      Map<String, dynamic>? userData;
      
      // Try to get user data from secure storage first
      if (userDataStr != null) {
        final parsedData = json.decode(userDataStr);
        print('6. Parsed Secure Storage user data: $parsedData');
        
        // 💡 Map the fields correctly and include dependents
        userData = {
          'name': parsedData['fullName'] ?? parsedData['full_name'] ?? '${parsedData['firstName'] ?? ''} ${parsedData['lastName'] ?? ''}'.trim(),
          'arabic_name': parsedData['arabicName'] ?? parsedData['arabic_name'] ?? parsedData['fullName'] ?? '',
          'national_id': parsedData['nationalId'] ?? parsedData['national_id'],
          'email': parsedData['email'],
          'dependents': dependentsCount?.toString() ?? '0',
        };
      }
      
      // If not found in secure storage, try SharedPreferences
      if (userData == null || userData['name']?.toString().trim().isEmpty == true) {
        print('\n7. No valid data in secure storage, checking SharedPreferences...');
        final prefsUserDataStr = prefs.getString('user_data');
        print('8. SharedPreferences - user_data: $prefsUserDataStr');
        
        if (prefsUserDataStr != null) {
          final prefsData = json.decode(prefsUserDataStr);
          print('9. Parsed SharedPreferences user data: $prefsData');
          
          // 💡 Map the fields correctly from SharedPreferences
          userData = {
            'name': '${prefsData['first_name_en'] ?? ''} ${prefsData['family_name_en'] ?? ''}'.trim(),
            'arabic_name': '${prefsData['first_name_ar'] ?? ''} ${prefsData['family_name_ar'] ?? ''}'.trim(),
            'national_id': prefsData['national_id'],
            'email': prefsData['email'],
            'phone': prefsData['phone'],
            'date_of_birth': prefsData['date_of_birth'],
            'dependents': prefsData['dependents'] ?? dependentsCount?.toString() ?? '0',
          };
          print('10. Mapped SharedPreferences user data: $userData');
        }
      }

      // 💡 Handle salary data (preserving existing salary logic)
      print('\n11. Processing salary data...');
      if (selectedSalaryStr != null) {
        final selectedSalary = json.decode(selectedSalaryStr);
        print('12. Selected salary data: $selectedSalary');
        userData = userData ?? {};
        userData['salary'] = selectedSalary['amount']?.toString() ?? userData['salary'];
        userData['employer'] = selectedSalary['employer'];
        // Only update name if it's empty
        if (userData['name']?.toString().trim().isEmpty == true) {
          userData['name'] = selectedSalary['fullName'];
          // Try to set Arabic name if it's empty
          if (userData['arabic_name']?.toString().trim().isEmpty == true) {
            userData['arabic_name'] = selectedSalary['fullName'];
          }
        }
        _uploadedFiles['salary'] = 'Verified through Dakhli';
        print('13. Updated user data with selected salary: $userData');
      } else if (dakhliSalaryStr != null) {
        final dakhliData = json.decode(dakhliSalaryStr);
        print('14. Dakhli salary data: $dakhliData');
        final salaries = List<Map<String, dynamic>>.from(dakhliData['salaries'] ?? []);
        if (salaries.isNotEmpty) {
          userData = userData ?? {};
          // Get the highest salary
          final highestSalary = salaries.reduce((a, b) => 
            double.parse(a['amount'].toString()) > double.parse(b['amount'].toString()) ? a : b);
          userData['salary'] = highestSalary['amount']?.toString() ?? userData['salary'];
          userData['employer'] = highestSalary['employer'];
          // Only update name if it's empty
          if (userData['name']?.toString().trim().isEmpty == true) {
            userData['name'] = highestSalary['fullName'];
            // Try to set Arabic name if it's empty
            if (userData['arabic_name']?.toString().trim().isEmpty == true) {
              userData['arabic_name'] = highestSalary['fullName'];
            }
          }
          _uploadedFiles['salary'] = 'Verified through Dakhli';
          print('15. Updated user data with Dakhli salary: $userData');
        }
      }

      print('\n16. Final user data before setState: $userData');
      if (userData != null) {
        setState(() {
          _userData = userData!;
          _userData['salary'] ??= '0';
          double salary = double.parse(_userData['salary'].toString());
          _userData['food_expense'] = (salary * 0.08).round().toString();
          _userData['transportation_expense'] = (salary * 0.05).round().toString();
          _userData['other_liabilities'] ??= '';

          // 💡 Prefill nameOnCard with English first and family names in capital letters
          if (_userData['nameOnCard'] == null || _userData['nameOnCard'].toString().isEmpty) {
            String nameOnCard = '';
            // Get the English name from userData first
            if (_userData['name']?.toString().trim().isNotEmpty == true) {
              nameOnCard = _userData['name'].toString().trim().toUpperCase();
            }
            _userData['nameOnCard'] = nameOnCard;
          }

          _isLoading = false;
          print('\n17. Final _userData after setState:');
          print('- Name: ${_userData['name']}');
          print('- Arabic Name: ${_userData['arabic_name']}');
          print('- National ID: ${_userData['national_id']}');
          print('- Email: ${_userData['email']}');
          print('- Salary: ${_userData['salary']}');
          print('- Dependents: ${_userData['dependents']}');
          print('- Name on Card: ${_userData['nameOnCard']}');
        });
      } else {
        print('\nERROR: No user data found in any storage location');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArabic 
                ? 'لم يتم العثور على بيانات المستخدم' 
                : 'User data not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      // Ensure ID expiry date is available
      if (userData != null && userData['id_expiry_date'] == null) {
        print('ID expiry date not found in user_data, checking registration data');
        final prefs = await SharedPreferences.getInstance();
        final registrationDataStr = prefs.getString('registration_data');
        if (registrationDataStr != null) {
          final registrationData = json.decode(registrationDataStr);
          if (registrationData['userData'] != null) {
            userData['id_expiry_date'] = registrationData['userData']['idExpiryDate'] ??
                                       registrationData['userData']['IdExpiryDate'] ??
                                       registrationData['userData']['id_expiry_date'] ??
                                       registrationData['userData']['id_expiry_date_hijri'];
            // Update stored user data with ID expiry date
            await _secureStorage.write(key: 'user_data', value: json.encode(userData));
          }
        }
      }
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
      print('\n=== CARD APPLICATION DETAILS - DATA FETCH END ===\n');
    }
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

      if (response['status'] == 'error') {
        print('\nError in response:');
        print('Status: ${response['status']}');
        print('Message: ${response['message']}');
        print('=== CARD APPLICATION REQUEST END (WITH ERROR) ===\n');
        
        _showError(isArabic 
          ? 'حدث خطأ أثناء إنشاء طلب البطاقة' 
          : response['message'] ?? 'Error creating card request');
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
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
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
} 