class Loan {
  final String id;
  final double amount;
  final double monthlyPayment;
  final int tenureMonths;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final double interestRate;
  final double remainingAmount;
  final DateTime nextPaymentDate;

  Loan({
    required this.id,
    required this.amount,
    required this.monthlyPayment,
    required this.tenureMonths,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.interestRate,
    required this.remainingAmount,
    required this.nextPaymentDate,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      monthlyPayment: (json['monthly_payment'] as num).toDouble(),
      tenureMonths: json['tenure_months'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status: json['status'] as String,
      interestRate: (json['interest_rate'] as num).toDouble(),
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      nextPaymentDate: DateTime.parse(json['next_payment_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'monthly_payment': monthlyPayment,
      'tenure_months': tenureMonths,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'interest_rate': interestRate,
      'remaining_amount': remainingAmount,
      'next_payment_date': nextPaymentDate.toIso8601String(),
    };
  }
} 