import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../../widgets/custom_button.dart';
import 'loan_offer_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/constants.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class LoanApplicationDetailsScreen extends StatefulWidget {
  final bool isArabic;
  const LoanApplicationDetailsScreen({Key? key, this.isArabic = false}) : super(key: key);

  @override
  State<LoanApplicationDetailsScreen> createState() => _LoanApplicationDetailsScreenState();
}

class _LoanApplicationDetailsScreenState extends State<LoanApplicationDetailsScreen> {
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
          _userData['loan_purpose'] ??= isArabic ? 'أسهم' : 'Stocks';  // Add Arabic translation for Stocks
          double salary = double.parse(_userData['salary'].toString());
          _userData['food_expense'] = (salary * 0.08).round().toString();
          _userData['transportation_expense'] = (salary * 0.05).round().toString();
          _userData['other_liabilities'] ??= '';
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
        return 'تحديث الغرض من القرض';
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
        return 'الغرض من القرض';
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
        return 'الغرض من القرض';
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
                      _userData['ibanNo'] != null &&
                      _uploadedFiles['national_id'] != null &&
                      _uploadedFiles['ibanNo'] != null;

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

                            // Next Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: canProceed ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoanOfferScreen(
                                        userData: _userData,
                                        isArabic: isArabic,
                                      ),
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
} 