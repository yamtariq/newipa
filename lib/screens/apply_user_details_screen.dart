import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_localizations.dart';

class UserDetailsScreen extends StatefulWidget {
  final bool isArabic;
  final Map<String, dynamic> formData;

  const UserDetailsScreen({
    Key? key,
    required this.isArabic,
    required this.formData,
  }) : super(key: key);

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _loanPurposeController = TextEditingController();
  final TextEditingController _expense1Controller = TextEditingController();
  final TextEditingController _expense2Controller = TextEditingController();
  final TextEditingController _otherLiabilitiesController =
      TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();

  // Document paths
  String? _idDocumentPath;
  String? _ibanDocumentPath;
  String? _salaryCertificatePath;

  // State variables
  bool _showSalaryCertificateUpload = false;
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  late String _nationalId;
  late String _dob;

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _nationalId = widget.formData['nationalId'] ?? '';
    _dob = widget.formData['dob'] ?? '';
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse('https://icreditdept.com/api/get_user.php?nationalId=$_nationalId'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': '7ca7427b418bdbd0b3b23d7debf69bf7',
          'Accept': 'application/json',
        },
      );
      
      print('API Response Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Decoded Data: $data');
        
        if (data['success']) {
          setState(() {
            _userData = data['data'];
            print('User Data: $_userData');
            // Check what fields are available in the user data
            _userData.forEach((key, value) {
              print('Field: $key, Value: $value');
            });
            _initializeFields();
            _isLoading = false;
          });
        } else {
          _showError(data['message'] ?? 'User not found.');
        }
      } else {
        _showError('Failed to fetch user data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      _showError('Error: $e');
    }
  }

  void _initializeFields() {
    // Safely parse income value from API response
    double income = 0.0;
    var rawIncome = _userData['income'];
    if (rawIncome != null) {
      if (rawIncome is int) {
        income = rawIncome.toDouble();
      } else if (rawIncome is String) {
        income = double.tryParse(rawIncome) ?? 0.0;
      } else if (rawIncome is double) {
        income = rawIncome;
      }
    }

    _incomeController.text = income.toStringAsFixed(2);
    _expense1Controller.text = (income * 0.10).toStringAsFixed(2); // 10%
    _expense2Controller.text = (income * 0.05).toStringAsFixed(2); // 5%
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.getText('Error', 'خطأ')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.getText('OK', 'موافق')),
          ),
        ],
      ),
    );
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.getText('User Details', 'تفاصيل المستخدم')),
          ),
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.getText('User Details', 'تفاصيل المستخدم')),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Full Name and National ID
                  Text(
                    '${AppLocalizations.getText('Full Name:', 'الاسم الكامل:')} ${_userData['fullName'] ?? _userData['name'] ?? AppLocalizations.getText('Not Available', 'غير متوفر')}',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppLocalizations.getText('National ID:', 'رقم الهوية:')} ${_nationalId}',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // ID Document Upload
                  _buildDocumentUploadField(
                    label: AppLocalizations.getText(
                        'Upload ID Document', 'تحميل بطاقة الهوية'),
                    onFilePicked: (path) => setState(() => _idDocumentPath = path),
                  ),
                  const SizedBox(height: 16),

                  // Loan Purpose
                  TextFormField(
                    controller: _loanPurposeController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.getText(
                          'Purpose of Loan', 'غرض التمويل'),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.getText(
                            'Please enter the loan purpose',
                            'يرجى إدخال غرض التمويل');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Expenses
                  _buildExpenseField(
                    label: AppLocalizations.getText(
                        'Living Expenses', 'نفقات المعيشة'),
                    controller: _expense1Controller,
                    minimumValue: double.parse(_expense1Controller.text),
                  ),
                  const SizedBox(height: 16),
                  _buildExpenseField(
                    label: AppLocalizations.getText('Utilities', 'الخدمات'),
                    controller: _expense2Controller,
                    minimumValue: double.parse(_expense2Controller.text),
                  ),
                  const SizedBox(height: 16),

                  // Other Liabilities
                  TextFormField(
                    controller: _otherLiabilitiesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.getText(
                          'Other Liabilities', 'الالتزامات الأخرى'),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // IBAN and IBAN Upload
                  TextFormField(
                    controller: _ibanController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.getText(
                          'IBAN Number', 'رقم الآيبان'),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.getText(
                            'Please enter IBAN', 'يرجى إدخال رقم الآيبان');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDocumentUploadField(
                    label: AppLocalizations.getText(
                        'Upload IBAN Document', 'تحميل مستند الآيبان'),
                    onFilePicked: (path) => setState(() => _ibanDocumentPath = path),
                  ),
                  const SizedBox(height: 16),

                  // Income Field and Salary Certificate
                  TextFormField(
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.getText('Income', 'الدخل'),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      double newIncome = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _showSalaryCertificateUpload =
                            newIncome != double.parse(_incomeController.text);
                      });
                    },
                  ),
                  if (_showSalaryCertificateUpload) ...[
                    const SizedBox(height: 16),
                    _buildDocumentUploadField(
                      label: AppLocalizations.getText(
                          'Upload Salary Certificate', 'تحميل شهادة الراتب'),
                      onFilePicked: (path) =>
                          setState(() => _salaryCertificatePath = path),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Submit and Cancel Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _submitForm();
                            }
                          },
                          child: Text(AppLocalizations.getText('Submit', 'إرسال')),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          child: Text(AppLocalizations.getText('Cancel', 'إلغاء')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentUploadField({
    required String label,
    required Function(String)

 onFilePicked,
  }) {
    return GestureDetector(
      onTap: () async {
        // TODO: Implement file picker logic
        String dummyFilePath = '/path/to/file.jpg'; // Replace with actual file picker implementation
        onFilePicked(dummyFilePath);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Icon(Icons.upload_file),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseField({
    required String label,
    required TextEditingController controller,
    required double minimumValue,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        double newValue = double.tryParse(value) ?? 0.0;
        if (newValue < minimumValue) {
          controller.text = minimumValue.toStringAsFixed(2);
        }
      },
    );
  }

  void _submitForm() {
    // Collect all data and navigate to the next screen
    Map<String, dynamic> formData = {
      'fullName': _userData['fullName'],
      'nationalId': _nationalId,
      'loanPurpose': _loanPurposeController.text,
      'expense1': _expense1Controller.text,
      'expense2': _expense2Controller.text,
      'otherLiabilities': _otherLiabilitiesController.text,
      'iban': _ibanController.text,
      'idDocument': _idDocumentPath,
      'ibanDocument': _ibanDocumentPath,
      'income': _incomeController.text,
      'salaryCertificate': _salaryCertificatePath,
    };

    Navigator.pushNamed(context, '/loanCalculation', arguments: formData);
  }
}
