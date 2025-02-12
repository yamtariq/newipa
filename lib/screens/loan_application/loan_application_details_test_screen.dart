import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../../widgets/custom_button.dart';
import 'loan_offer_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/constants.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/document_upload_service.dart';
import '../../services/loan_service.dart';
import 'package:lottie/lottie.dart';
import 'loan_application_status_screen.dart';

class LoanApplicationDetailsTestScreen extends StatefulWidget {
  final bool isArabic;
  const LoanApplicationDetailsTestScreen({Key? key, this.isArabic = false}) : super(key: key);

  @override
  State<LoanApplicationDetailsTestScreen> createState() => _LoanApplicationDetailsTestScreenState();
}

class _LoanApplicationDetailsTestScreenState extends State<LoanApplicationDetailsTestScreen> with SingleTickerProviderStateMixin {
  final _secureStorage = const FlutterSecureStorage();
  bool _isLoading = false;
  Map<String, dynamic> _userData = {};
  Map<String, String> _uploadedFiles = {};
  bool _salaryChanged = false;
  bool _consentAccepted = false;
  bool get isArabic => widget.isArabic;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // Initialize with empty data
    _userData = {
      'name': '',
      'arabic_name': '',
      'national_id': '',
      'email': '',
      'salary': '0',
      'employer': '',
      'loan_purpose': isArabic ? 'أسهم' : 'Stocks',
      'food_expense': '0',
      'transportation_expense': '0',
      'other_liabilities': '',
      'dependents': '0',
      'ibanNo': '',
    };
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
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
    String? newValue = await showDialog<String>(
      context: context,
      builder: (context) => _buildUpdateDialog(field, currentValue),
    );

    if (newValue != null && newValue != currentValue) {
      setState(() {
        if (field == 'ibanNo') {
          String formattedIban = newValue.startsWith('SA') ? newValue : 'SA$newValue';
          _userData['ibanNo'] = formattedIban;
        } else if (field == 'salary') {
          double salaryValue = double.parse(newValue);
          _userData['food_expense'] = (salaryValue * 0.08).round().toString();
          _userData['transportation_expense'] = (salaryValue * 0.05).round().toString();
          _userData[field] = newValue;
          _salaryChanged = true;
        } else {
          _userData[field] = newValue;
        }
      });
    }
  }

  Future<void> _pickFile(String field) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _uploadedFiles[field] = result.files.first.name;
          if (field == 'salary') {
            _salaryChanged = false;
          }
        });
      }
    } catch (e) {
      _showError('Error picking file: ${e.toString()}');
    }
  }

  Widget _buildUpdateDialog(String field, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    final bool requiresDocument = field == 'salary' || field == 'ibanNo';
    String? fileName = _uploadedFiles[field];
    bool showDocumentUpload = field != 'salary';
    String? validationError;

    return AlertDialog(
      title: Text(isArabic ? _getArabicFieldTitle(field) : _getEnglishFieldTitle(field)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: field.replaceAll('_', ' ').toUpperCase(),
            ),
            keyboardType: _getKeyboardType(field),
          ),
          if (requiresDocument && showDocumentUpload) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _pickFile(field),
              child: Text(fileName ?? 'Upload Document'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        TextButton(
          onPressed: validationError != null
              ? null
              : () => Navigator.pop(context, controller.text),
          child: Text(isArabic ? 'تحديث' : 'Update'),
        ),
      ],
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
      case 'email':
        return TextInputType.emailAddress;
      default:
        return TextInputType.text;
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
                                  _buildInfoField('Name', isArabic ? _userData['arabic_name']?.toString() ?? '' : _userData['name']?.toString() ?? '', editable: true),
                                  _buildInfoField('National ID', _userData['national_id']?.toString() ?? '', editable: true),
                                  _buildInfoField('Loan Purpose', _userData['loan_purpose']?.toString() ?? (isArabic ? 'أسهم' : 'Stocks'), editable: true, fieldName: 'loan_purpose'),
                                  _buildInfoField('Email', _userData['email']?.toString() ?? '', editable: true),
                                  _buildInfoField('Number of Dependents', _userData['dependents']?.toString() ?? '0', editable: true, fieldName: 'dependents'),
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
                                onPressed: canProceed ? () {
                                  // Show success dialog for test
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(isArabic ? 'نجاح' : 'Success'),
                                      content: Text(
                                        isArabic 
                                            ? 'تم إرسال الطلب بنجاح'
                                            : 'Application submitted successfully',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.pop(context);
                                          },
                                          child: Text(isArabic ? 'حسناً' : 'OK'),
                                        ),
                                      ],
                                    ),
                                  );
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

  Widget _buildInfoField(String label, String value, {bool editable = false, String? fieldName, bool isRequired = true}) {
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value,
        enabled: editable,
        onChanged: (newValue) {
          setState(() {
            if (fieldName == 'salary') {
              _userData[fieldName ?? label.toLowerCase().replaceAll(' ', '_')] = newValue;
              double salaryValue = double.tryParse(newValue) ?? 0;
              _userData['food_expense'] = (salaryValue * 0.08).round().toString();
              _userData['transportation_expense'] = (salaryValue * 0.05).round().toString();
              _salaryChanged = true;
            } else if (fieldName == 'ibanNo') {
              String formattedIban = newValue.startsWith('SA') ? newValue : 'SA$newValue';
              _userData[fieldName ?? label.toLowerCase().replaceAll(' ', '_')] = formattedIban;
            } else {
              _userData[fieldName ?? label.toLowerCase().replaceAll(' ', '_')] = newValue;
            }
          });
        },
        style: TextStyle(
          fontSize: 16,
          color: textColor,
        ),
        decoration: InputDecoration(
          labelText: '${isArabic ? _getArabicLabel(label) : label}${isRequired ? ' *' : ''}',
          labelStyle: TextStyle(
            color: hintColor,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        keyboardType: _getKeyboardType(fieldName ?? label.toLowerCase().replaceAll(' ', '_')),
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDocumentUpload('National ID', 'national_id'),
        _buildDocumentUpload('IBAN Certificate', 'ibanNo'),
        if (_salaryChanged)
          _buildDocumentUpload('Salary Certificate', 'salary'),
      ],
    );
  }

  Widget _buildDocumentUpload(String label, String field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? _getArabicLabel(label) : label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  _uploadedFiles[field] ?? (isArabic ? 'لم يتم التحميل' : 'Not uploaded'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _uploadedFiles[field] != null ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _pickFile(field),
          ),
        ],
      ),
    );
  }

  String _getArabicLabel(String englishLabel) {
    switch (englishLabel) {
      case 'Name':
        return 'الاسم';
      case 'Arabic Name':
        return 'الاسم بالعربي';
      case 'National ID':
        return 'رقم الهوية';
      case 'Email':
        return 'البريد الإلكتروني';
      case 'Phone':
        return 'رقم الجوال';
      case 'Date of Birth':
        return 'تاريخ الميلاد';
      case 'Number of Dependents':
        return 'عدد المعالين';
      case 'Salary':
        return 'الراتب';
      case 'Employer':
        return 'جهة العمل';
      case 'IBAN':
        return 'رقم الآيبان';
      case 'Loan Purpose':
        return 'الغرض من التمويل';
      case 'Food Expense':
        return 'مصاريف الطعام';
      case 'Transportation Expense':
        return 'مصاريف المواصلات';
      case 'Other Liabilities':
        return 'إلتزامات أخرى';
      case 'National ID Document':
        return 'وثيقة الهوية';
      case 'IBAN Certificate':
        return 'شهادة الآيبان';
      case 'Salary Certificate':
        return 'شهادة الراتب';
      default:
        return englishLabel;
    }
  }
} 