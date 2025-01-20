import 'package:flutter/material.dart';
import 'app_localizations.dart';

class LoanCalculationScreen extends StatefulWidget {
  final Map<String, dynamic> formData;
  final bool isArabic;

  const LoanCalculationScreen({
    Key? key, 
    required this.formData,
    required this.isArabic,
  }) : super(key: key);

  @override
  _LoanCalculationScreenState createState() => _LoanCalculationScreenState();
}

class _LoanCalculationScreenState extends State<LoanCalculationScreen> {
  double income = 0.0;
  double expenses = 0.0;
  double liabilities = 0.0;
  double financeAmount = 0.0;
  double emi = 0.0;
  int tenure = 12; // Default tenure in months

  static const double flatRate = 0.16; // 16% flat rate
  static const double maxApprovalThreshold = 10000.0;

  bool isApproved = false;

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    // Parse income from previous screen
    income = double.tryParse(widget.formData['income'] ?? '0.0') ?? 0.0;
    
    // Initialize other values
    expenses = 0.0;
    liabilities = 0.0;
    _calculateLoan();
  }

  void _calculateLoan() {
    // Simple loan calculation logic
    double monthlyDisposableIncome = income - expenses - liabilities;
    financeAmount = monthlyDisposableIncome * 12 * 0.5; // 50% of yearly disposable income
    
    // Calculate EMI using flat rate
    emi = (financeAmount + (financeAmount * flatRate * tenure / 12)) / tenure;
    
    // Determine approval based on threshold
    isApproved = financeAmount >= maxApprovalThreshold;
    
    setState(() {});
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(
            AppLocalizations.getText('Loan Calculation', 'حساب التمويل'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  color: Theme.of(context).primaryColor,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Icon(
                        Icons.calculate_outlined,
                        size: 60,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.getText(
                          'Loan Summary',
                          'ملخص التمويل'
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Loan Details Grid
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildInfoCard(
                            title: AppLocalizations.getText('Monthly Income', 'الدخل الشهري'),
                            value: '${income.toStringAsFixed(2)} SAR',
                            icon: Icons.account_balance_wallet,
                          ),
                          _buildInfoCard(
                            title: AppLocalizations.getText('Finance Amount', 'مبلغ التمويل'),
                            value: '${financeAmount.toStringAsFixed(2)} SAR',
                            icon: Icons.money,
                            valueColor: Theme.of(context).primaryColor,
                          ),
                          _buildInfoCard(
                            title: AppLocalizations.getText('Monthly EMI', 'القسط الشهري'),
                            value: '${emi.toStringAsFixed(2)} SAR',
                            icon: Icons.calendar_today,
                          ),
                          _buildInfoCard(
                            title: AppLocalizations.getText('Status', 'الحالة'),
                            value: isApproved ? 
                              AppLocalizations.getText('Pre-Approved', 'موافقة مبدئية') : 
                              AppLocalizations.getText('Not Eligible', 'غير مؤهل'),
                            icon: Icons.check_circle,
                            valueColor: isApproved ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Tenure Slider Section
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.getText('Loan Tenure', 'مدة التمويل'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '12 ${AppLocalizations.getText('Months', 'شهر')}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    '60 ${AppLocalizations.getText('Months', 'شهر')}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Theme.of(context).primaryColor,
                                  inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                  thumbColor: Theme.of(context).primaryColor,
                                  overlayColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                  valueIndicatorColor: Theme.of(context).primaryColor,
                                ),
                                child: Slider(
                                  value: tenure.toDouble(),
                                  min: 12,
                                  max: 60,
                                  divisions: 48,
                                  label: '${tenure.toString()} ${AppLocalizations.getText('Months', 'شهر')}',
                                  onChanged: (value) {
                                    setState(() {
                                      tenure = value.round();
                                      _calculateLoan();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            // Add loan application data
                            final Map<String, dynamic> applicationData = {
                              ...widget.formData,
                              'financeAmount': financeAmount,
                              'emi': emi,
                              'tenure': tenure,
                              'isApproved': isApproved,
                            };

                            Navigator.pushNamed(
                              context,
                              '/loanResult',
                              arguments: applicationData,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            AppLocalizations.getText('Submit Application', 'تقديم الطلب'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
