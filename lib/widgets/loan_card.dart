import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

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
    if (isDarkMode) {
      return Colors.black;
    }
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode ? Colors.black : const Color(0xFF0077B6);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      color: isDarkMode ? Colors.grey[100] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: themeColor.withOpacity(0.2),
          width: 1,
        ),
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
                    color: themeColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black.withOpacity(0.1) : _getStatusColor(loan.status, isDarkMode).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(loan.status, isDarkMode),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    loan.status,
                    style: TextStyle(
                      color: _getStatusColor(loan.status, isDarkMode),
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
                _buildInfoColumn(
                  'Monthly Payment',
                  _formatCurrency(loan.monthlyPayment),
                  isDarkMode,
                ),
                _buildInfoColumn(
                  'Remaining Amount',
                  _formatCurrency(loan.remainingAmount),
                  isDarkMode,
                ),
                _buildInfoColumn(
                  'Interest Rate',
                  '${loan.interestRate}%',
                  isDarkMode,
                ),
              ],
            ),
            Divider(
              height: 24,
              color: themeColor.withOpacity(0.2),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn(
                  'Start Date',
                  _formatDate(loan.startDate),
                  isDarkMode,
                ),
                _buildInfoColumn(
                  'End Date',
                  _formatDate(loan.endDate),
                  isDarkMode,
                ),
                _buildInfoColumn(
                  'Next Payment',
                  _formatDate(loan.nextPaymentDate),
                  isDarkMode,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.black54 : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.black87 : Colors.black87,
          ),
        ),
      ],
    );
  }
} 