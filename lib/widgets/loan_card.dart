import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;

  const LoanCard({
    Key? key,
    required this.loan,
  }) : super(key: key);

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: 'SAR ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  Color _getStatusColor(String status, bool isDarkMode) {
    final Color activeColor = Color(isDarkMode ? 0xFF00A650 : 0xFF008040);
    final Color pendingColor = Color(isDarkMode ? 0xFFFFA726 : 0xFFF57C00);
    final Color completedColor = Color(isDarkMode ? 0xFF42A5F5 : 0xFF1976D2);
    final Color overdueColor = Color(isDarkMode ? 0xFFEF5350 : 0xFFD32F2F);
    final Color defaultColor = Color(isDarkMode ? 0xFF9E9E9E : 0xFF757575);

    switch (status.toLowerCase()) {
      case 'active':
        return activeColor;
      case 'pending':
        return pendingColor;
      case 'completed':
        return completedColor;
      case 'overdue':
        return overdueColor;
      default:
        return defaultColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final surfaceColor = Color(themeProvider.isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    final borderColor = Color(themeProvider.isDarkMode 
        ? Constants.darkFormBorderColor 
        : Constants.lightFormBorderColor);
    final shadowColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryShadowColor 
        : Constants.lightPrimaryShadowColor);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 5,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatCurrency(loan.amount),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(loan.status, themeProvider.isDarkMode).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                    border: Border.all(
                      color: _getStatusColor(loan.status, themeProvider.isDarkMode),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    loan.status,
                    style: TextStyle(
                      color: _getStatusColor(loan.status, themeProvider.isDarkMode),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Payment',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(themeProvider.isDarkMode 
                            ? Constants.darkLabelTextColor 
                            : Constants.lightLabelTextColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(loan.monthlyPayment),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Next Payment',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(themeProvider.isDarkMode 
                            ? Constants.darkLabelTextColor 
                            : Constants.lightLabelTextColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(loan.nextPaymentDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remaining',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(themeProvider.isDarkMode 
                            ? Constants.darkLabelTextColor 
                            : Constants.lightLabelTextColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(loan.remainingAmount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'End Date',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(themeProvider.isDarkMode 
                            ? Constants.darkLabelTextColor 
                            : Constants.lightLabelTextColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(loan.endDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 