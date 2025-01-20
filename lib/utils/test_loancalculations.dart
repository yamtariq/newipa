import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(LoanApp());
}

class LoanApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loan Calculator',
      home: LoanCalculatorPage(),
    );
  }
}

class LoanCalculatorPage extends StatefulWidget {
  @override
  _LoanCalculatorPageState createState() => _LoanCalculatorPageState();
}

class _LoanCalculatorPageState extends State<LoanCalculatorPage> {
  // Initial values from API
  double principal = 100000; // Default principal amount
  int tenure = 60; // Default tenure in months
  double rate = 16; // Fixed annual interest rate

  // Calculated values
  double emi = 0;
  double totalRepayment = 0;
  double totalInterest = 0;

  @override
  void initState() {
    super.initState();
    calculateForTenureChange(); // Initial calculation
  }

  // Recalculate when tenure changes
  void calculateForTenureChange() {
    final results = LoanCalculator.recalculateForTenureChange(
      principal: principal,
      rate: rate,
      newTenure: tenure,
    );
    setState(() {
      emi = results["emi"];
      totalRepayment = results["totalRepayment"];
      totalInterest = results["totalInterest"];
    });
  }

  // Recalculate when principal changes
  void calculateForPrincipalChange(double newPrincipal) {
    final results = LoanCalculator.recalculateForPrincipalChange(
      newPrincipal: newPrincipal,
      rate: rate,
      tenure: tenure,
    );
    setState(() {
      emi = results["emi"];
      totalRepayment = results["totalRepayment"];
      totalInterest = results["totalInterest"];
      principal = newPrincipal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loan Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Principal: ${principal.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18),
            ),
            Slider(
              value: principal,
              min: 50000,
              max: 300000,
              divisions: 25,
              label: principal.toStringAsFixed(0),
              onChanged: (value) {
                calculateForPrincipalChange(value);
              },
            ),
            Text(
              'Tenure (months): $tenure',
              style: TextStyle(fontSize: 18),
            ),
            Slider(
              value: tenure.toDouble(),
              min: 12,
              max: 60,
              divisions: 48,
              label: tenure.toString(),
              onChanged: (value) {
                setState(() {
                  tenure = value.toInt();
                });
                calculateForTenureChange();
              },
            ),
            SizedBox(height: 20),
            Text(
              'Results:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'EMI: ${emi.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Total Repayment: ${totalRepayment.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Total Interest: ${totalInterest.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// Loan calculation logic
class LoanCalculator {
  // Recalculate when the user changes the tenure
  static Map<String, dynamic> recalculateForTenureChange({
    required double principal,
    required double rate, // Annual interest rate (e.g., 16%)
    required int newTenure, // New tenure in months
  }) {
    final monthlyRate = rate / 100 / 12; // Convert annual % rate to monthly decimal

    double computeEmi(double principal, double r, int months) {
      if (r == 0) return principal / months; // Edge case for 0% interest
      final numerator = principal * r * pow(1 + r, months);
      final denominator = pow(1 + r, months) - 1;
      return numerator / denominator;
    }

    final emi = computeEmi(principal, monthlyRate, newTenure);
    final totalRepayment = emi * newTenure;
    final totalInterest = totalRepayment - principal;

    return {
      "emi": emi.roundToDouble(),
      "totalRepayment": totalRepayment.roundToDouble(),
      "totalInterest": totalInterest.roundToDouble(),
      "tenure": newTenure,
    };
  }

  // Recalculate when the user changes the principal
  static Map<String, dynamic> recalculateForPrincipalChange({
    required double newPrincipal,
    required double rate, // Annual interest rate (e.g., 16%)
    required int tenure, // Fixed tenure in months
  }) {
    final monthlyRate = rate / 100 / 12; // Convert annual % rate to monthly decimal

    double computeEmi(double principal, double r, int months) {
      if (r == 0) return principal / months; // Edge case for 0% interest
      final numerator = principal * r * pow(1 + r, months);
      final denominator = pow(1 + r, months) - 1;
      return numerator / denominator;
    }

    final emi = computeEmi(newPrincipal, monthlyRate, tenure);
    final totalRepayment = emi * tenure;
    final totalInterest = totalRepayment - newPrincipal;

    return {
      "emi": emi.roundToDouble(),
      "totalRepayment": totalRepayment.roundToDouble(),
      "totalInterest": totalInterest.roundToDouble(),
      "principal": newPrincipal,
    };
  }
}
