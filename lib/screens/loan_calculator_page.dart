import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';

class LoanCalculatorPage extends StatefulWidget {
  const LoanCalculatorPage({super.key});

  @override
  State<LoanCalculatorPage> createState() => _LoanCalculatorPageState();
}

class _LoanCalculatorPageState extends State<LoanCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _interestController = TextEditingController();
  final _tenureController = TextEditingController();

  double _loanAmount = 0;
  double _interestRate = 0;
  int _tenureInMonths = 0;
  double _emi = 0;
  double _totalPayment = 0;
  double _totalInterest = 0;

  void _calculateLoan() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _loanAmount = double.parse(_amountController.text);
        _interestRate = double.parse(_interestController.text);
        _tenureInMonths = int.parse(_tenureController.text);

        double monthlyRate = (_interestRate / 12) / 100;

        _emi = (_loanAmount *
                monthlyRate *
                pow(1 + monthlyRate, _tenureInMonths)) /
            (pow(1 + monthlyRate, _tenureInMonths) - 1);

        _totalPayment = _emi * _tenureInMonths;
        _totalInterest = _totalPayment - _loanAmount;
      });
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: 'SAR ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _interestController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Image.asset(
            'assets/images/nayifat-logo-no-bg.png',
            height: MediaQuery.of(context).size.height * 0.06,
          ),
          Expanded(
            child: Center(
              child: Text(
                'Loan Calculator',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward,
              color: textColor,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);
    final backgroundColor = Color(themeProvider.isDarkMode 
        ? Constants.darkBackgroundColor 
        : Constants.lightBackgroundColor);
    final surfaceColor = Color(themeProvider.isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    final borderColor = Color(themeProvider.isDarkMode 
        ? Constants.darkFormBorderColor 
        : Constants.lightFormBorderColor);
    final primaryColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
                  border: Border.all(
                    color: borderColor,
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Loan Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                          border: Border.all(
                            color: borderColor,
                          ),
                        ),
                        child: TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: 'Loan Amount (SAR)',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                            prefixIcon: Icon(Icons.attach_money, color: primaryColor),
                            labelStyle: TextStyle(color: Color(themeProvider.isDarkMode 
                                ? Constants.darkHintTextColor 
                                : Constants.lightHintTextColor)),
                          ),
                          style: TextStyle(color: textColor),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter loan amount';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                          border: Border.all(
                            color: borderColor,
                          ),
                        ),
                        child: TextFormField(
                          controller: _interestController,
                          decoration: InputDecoration(
                            labelText: 'Interest Rate (%)',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                            prefixIcon: Icon(Icons.percent, color: primaryColor),
                            labelStyle: TextStyle(color: Color(themeProvider.isDarkMode 
                                ? Constants.darkHintTextColor 
                                : Constants.lightHintTextColor)),
                          ),
                          style: TextStyle(color: textColor),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter interest rate';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                          border: Border.all(
                            color: borderColor,
                          ),
                        ),
                        child: TextFormField(
                          controller: _tenureController,
                          decoration: InputDecoration(
                            labelText: 'Loan Tenure (months)',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                            prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
                            labelStyle: TextStyle(color: Color(themeProvider.isDarkMode 
                                ? Constants.darkHintTextColor 
                                : Constants.lightHintTextColor)),
                          ),
                          style: TextStyle(color: textColor),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter loan tenure';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: surfaceColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
                                  side: BorderSide(
                                    color: borderColor,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _calculateLoan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
                                ),
                              ),
                              child: Text(
                                'Calculate',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: themeProvider.isDarkMode ? backgroundColor : surfaceColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_emi > 0)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
                    border: Border.all(
                      color: borderColor,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Calculation Results',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ResultTile(
                        title: 'Monthly EMI',
                        value: _formatCurrency(_emi),
                        color: primaryColor,
                      ),
                      const Divider(),
                      _ResultTile(
                        title: 'Total Interest',
                        value: _formatCurrency(_totalInterest),
                        color: primaryColor,
                      ),
                      const Divider(),
                      _ResultTile(
                        title: 'Total Payment',
                        value: _formatCurrency(_totalPayment),
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _ResultTile({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
