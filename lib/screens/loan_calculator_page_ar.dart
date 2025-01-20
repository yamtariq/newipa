import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class LoanCalculatorPageAr extends StatefulWidget {
  const LoanCalculatorPageAr({super.key});

  @override
  State<LoanCalculatorPageAr> createState() => _LoanCalculatorPageArState();
}

class _LoanCalculatorPageArState extends State<LoanCalculatorPageAr> {
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
      symbol: 'ريال ',
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
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode ? Colors.black : const Color(0xFF0077B6);

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: themeColor,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Center(
              child: Text(
                'حاسبة التمويل',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ),
          ),
          isDarkMode 
            ? ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
                child: SvgPicture.asset(
                  'assets/images/nayifat-logo.svg',
                  height: 40,
                ),
              )
            : SvgPicture.asset(
                'assets/images/nayifat-logo.svg',
                height: 40,
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode ? Colors.black : const Color(0xFF0077B6);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[100] : Colors.white,
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
                  color: isDarkMode ? Colors.grey[100] : Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: themeColor.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode ? Colors.grey[400]! : Colors.black.withOpacity(0.05),
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
                        alignment: Alignment.centerRight,
                        child: Text(
                          'تفاصيل التمويل',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: themeColor.withOpacity(0.2),
                          ),
                        ),
                        child: TextFormField(
                          controller: _amountController,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            labelText: 'مبلغ التمويل (ريال)',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            suffixIcon: Icon(Icons.attach_money, color: themeColor),
                            alignLabelWithHint: true,
                            floatingLabelStyle: TextStyle(
                              color: themeColor.withOpacity(0.7),
                            ),
                          ),
                          style: TextStyle(color: isDarkMode ? Colors.black87 : Colors.black87),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال مبلغ التمويل';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: themeColor.withOpacity(0.2),
                          ),
                        ),
                        child: TextFormField(
                          controller: _interestController,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            labelText: 'معدل الربح (%)',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            suffixIcon: Icon(Icons.percent, color: themeColor),
                            alignLabelWithHint: true,
                            floatingLabelStyle: TextStyle(
                              color: themeColor.withOpacity(0.7),
                            ),
                          ),
                          style: TextStyle(color: isDarkMode ? Colors.black87 : Colors.black87),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال معدل الربح';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: themeColor.withOpacity(0.2),
                          ),
                        ),
                        child: TextFormField(
                          controller: _tenureController,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            labelText: 'مدة التمويل (بالأشهر)',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            suffixIcon: Icon(Icons.calendar_today, color: themeColor),
                            alignLabelWithHint: true,
                            floatingLabelStyle: TextStyle(
                              color: themeColor.withOpacity(0.7),
                            ),
                          ),
                          style: TextStyle(color: isDarkMode ? Colors.black87 : Colors.black87),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال مدة التمويل';
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
                                backgroundColor: isDarkMode ? Colors.black.withOpacity(0.1) : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: themeColor.withOpacity(0.5),
                                  ),
                                ),
                              ),
                              child: Text(
                                'إلغاء',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: themeColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _calculateLoan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode ? Colors.black.withOpacity(0.1) : const Color(0xFF0077B6),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isDarkMode ? Colors.black : Colors.transparent,
                                  ),
                                ),
                              ),
                              child: Text(
                                'احسب',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.black : Colors.white,
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
                    color: isDarkMode ? Colors.grey[100] : Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: themeColor.withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode ? Colors.grey[400]! : Colors.black.withOpacity(0.05),
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
                        alignment: Alignment.centerRight,
                        child: Text(
                          'نتائج الحساب',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ResultTile(
                        title: 'القسط الشهري',
                        value: _formatCurrency(_emi),
                        color: themeColor,
                      ),
                      const Divider(),
                      _ResultTile(
                        title: 'إجمالي الربح',
                        value: _formatCurrency(_totalInterest),
                        color: themeColor,
                      ),
                      const Divider(),
                      _ResultTile(
                        title: 'إجمالي المبلغ المستحق',
                        value: _formatCurrency(_totalPayment),
                        color: themeColor,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 