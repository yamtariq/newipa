import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../../widgets/custom_button.dart';
import 'card_offer_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/constants.dart';
import 'dart:math' as math;

class CardApplicationDetailsScreen extends StatefulWidget {
  final bool isArabic;
  const CardApplicationDetailsScreen({Key? key, this.isArabic = false}) : super(key: key);

  @override
  State<CardApplicationDetailsScreen> createState() => _CardApplicationDetailsScreenState();
}

class _CardApplicationDetailsScreenState extends State<CardApplicationDetailsScreen> {
  final _secureStorage = const FlutterSecureStorage();
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  Map<String, String> _uploadedFiles = {};
  bool _salaryChanged = false;
  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userDataStr = await _secureStorage.read(key: 'user_data');
      if (userDataStr != null) {
        final userData = json.decode(userDataStr);
        setState(() {
          _userData = userData;
          // Set default values for required fields if they're null
          _userData['salary'] ??= '0';
          double salary = double.parse(_userData['salary'].toString());
          _userData['food_expense'] = (salary * 0.08).round().toString();
          _userData['transportation_expense'] = (salary * 0.05).round().toString();
          _userData['other_liabilities'] ??= '';  // Changed from '0' to empty string
          _isLoading = false;
        });
      } else {
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
    } catch (e) {
      print('Error loading user data: $e');
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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

  Future<void> _pickFile(String field) async {
    print('Picking file for field: $field');
    print('Current uploaded files before picking: $_uploadedFiles');
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _uploadedFiles[field] = result.files.single.name;
          print('File picked successfully. Updated uploaded files: $_uploadedFiles');
          // Only reset salary changed flag for salary document
          if (field == 'salary') {
            _salaryChanged = false;
          }
        });
      } else {
        print('No file was picked');
        // If no file was picked for salary, reset the salary to previous value
        if (field == 'salary' && _salaryChanged) {
          setState(() {
            _salaryChanged = false;
            // Reset salary to previous value if needed
          });
        }
      }
    } catch (e) {
      print('Error picking file: $e');
      _showError('Error picking file: $e');
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
          return AlertDialog(
            title: Text(
              isArabic ? _getArabicFieldTitle(field) : _getEnglishFieldTitle(field),
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: isArabic ? _getArabicInputLabel(field) : field.replaceAll('_', ' ').toUpperCase(),
                    errorText: validationError,
                    errorMaxLines: 3,
                    errorStyle: const TextStyle(
                      height: 1.2,
                    ),
                    border: const OutlineInputBorder(),
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
                if (requiresDocument && showDocumentUpload) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                      );
                      if (result != null) {
                        setDialogState(() {
                          fileName = result.files.single.name;
                          if (field == 'salary') {
                            validationError = null;
                          }
                        });
                        _uploadedFiles[field] = result.files.single.name;
                      }
                    },
                    child: Text(fileName ?? (field == 'salary' 
                      ? (isArabic ? 'تحميل خطاب الراتب (مطلوب للتحديث)' : 'Upload Salary Letter (Required for Update)')
                      : '')),
                  ),
                  if (fileName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        fileName ?? '',
                        style: const TextStyle(
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
                child: Text(isArabic ? 'تحديث' : 'Update'),
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
    // Get Arabic label based on field name
    String arabicLabel = _getArabicLabel(label);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${isArabic ? arabicLabel : label} ${isRequired ? '*' : ''}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (editable)
                IconButton(
                  icon: Icon(Icons.edit, color: Color(Constants.primaryColorValue)),
                  onPressed: () => _updateField(
                    fieldName ?? label.toLowerCase().replaceAll(' ', '_'), 
                    value ?? ''
                  ),
                ),
            ],
          ),
          const Divider(),
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
      default:
        return field;
    }
  }

  Widget _buildDocumentsSection() {
    print('Building documents section. Current uploaded files: $_uploadedFiles');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'المستندات المطلوبة' : 'Required Documents',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(Constants.primaryColorValue),
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
    // Get Arabic label for documents
    String arabicLabel = _getArabicDocumentLabel(label);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${isArabic ? arabicLabel : label} ${required ? '*' : ''}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: onTap == null ? Colors.grey[100] : null,
              ),
              child: Row(
                children: [
                  const Icon(Icons.upload_file),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName ?? placeholder ?? (isArabic ? 'اختر ملف' : 'Choose File'),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onTap == null ? Colors.grey[600] : null,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    const Icon(Icons.arrow_forward_ios, size: 16),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    bool canProceed = _userData['national_id'] != null &&
                      _userData['email'] != null &&
                      _userData['salary'] != null &&
                      _uploadedFiles['national_id'] != null;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1B3E6C).withOpacity(0.1),
                    Colors.white,
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
                                color: Color(Constants.primaryColorValue),
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
                            color: Color(Constants.primaryColorValue),
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
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
                                  _buildInfoField(
                                    'Salary', 
                                    double.parse(_userData['salary']?.toString() ?? '0').round().toString(), 
                                    editable: true
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Expenses Section
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
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
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(Constants.primaryColorValue),
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: _buildDocumentsSection(),
                            ),
                            const SizedBox(height: 32),

                            // Next Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: canProceed ? () {
                                  double salary = double.parse(_userData['salary']?.toString() ?? '0');
                                  // Calculate credit limits based on new formula
                                  double minCreditLimit = 2000;  // Fixed minimum
                                  double maxCreditLimit = math.min(50000, (salary * 0.15 * 20));  // Lower of 50k or (15% of salary * 20)

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CardOfferScreen(
                                        maxCreditLimit: maxCreditLimit,
                                        minCreditLimit: minCreditLimit,
                                        isArabic: isArabic,
                                        userData: _userData,
                                      ),
                                    ),
                                  );
                                } : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(Constants.primaryColorValue),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 5,
                                  shadowColor: Color(Constants.primaryColorValue).withOpacity(0.5),
                                ),
                                child: Text(
                                  isArabic ? 'التالي' : 'Next',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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