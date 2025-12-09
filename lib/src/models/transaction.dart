class Transaction {
  final String id;
  final double amount;
  final DateTime date;
  final String paymentMethod;
  final String status;
  final String? upiId;

  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    required this.status,
    this.upiId,
  });
}
