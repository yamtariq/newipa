import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../utils/constants.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'loan_application_details_screen.dart';
import '../card_application/card_application_details_screen.dart';

class LoanApplicationSalarySelectionScreen extends StatefulWidget {
  final bool isArabic;
  final List<Map<String, dynamic>> salaries;
  final String nationalId;
  final bool isCardApplication;

  const LoanApplicationSalarySelectionScreen({
    Key? key,
    required this.salaries,
    required this.isArabic,
    required this.nationalId,
    this.isCardApplication = false,
  }) : super(key: key);

  @override
  State<LoanApplicationSalarySelectionScreen> createState() => _LoanApplicationSalarySelectionScreenState();
}

class _LoanApplicationSalarySelectionScreenState extends State<LoanApplicationSalarySelectionScreen> {
  final _secureStorage = const FlutterSecureStorage();
  int? _selectedSalaryIndex;

  bool get isArabic => widget.isArabic;
  bool get isCardApplication => widget.isCardApplication;

  Future<void> _proceedWithSelectedSalary() async {
    if (_selectedSalaryIndex == null) return;

    final selectedSalary = widget.salaries[_selectedSalaryIndex!];
    
    // Save the selected salary data
    await _secureStorage.write(
      key: 'selected_salary_data',
      value: json.encode(selectedSalary),
    );

    if (!mounted) return;

    // Navigate to appropriate details screen based on application type
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => isCardApplication
            ? CardApplicationDetailsScreen(isArabic: isArabic)
            : LoanApplicationDetailsScreen(isArabic: isArabic),
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
    final surfaceColor = Color(themeProvider.isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    final textColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isArabic ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
              color: primaryColor,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            isArabic ? 'اختيار الراتب' : 'Select Salary',
            style: TextStyle(
              color: primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.salaries.length,
                itemBuilder: (context, index) {
                  final salary = widget.salaries[index];
                  final amount = salary['amount']?.toString() ?? '0';
                  final employer = salary['employer']?.toString() ?? '';
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedSalaryIndex == index 
                            ? primaryColor 
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: RadioListTile<int>(
                      value: index,
                      groupValue: _selectedSalaryIndex,
                      onChanged: (value) {
                        setState(() => _selectedSalaryIndex = value);
                      },
                      title: Text(
                        employer,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${isArabic ? 'الراتب: ' : 'Salary: '} $amount ${isArabic ? 'ريال' : 'SAR'}',
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      activeColor: primaryColor,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedSalaryIndex != null 
                      ? _proceedWithSelectedSalary 
                      : null,
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
                    isArabic ? 'متابعة' : 'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: surfaceColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 