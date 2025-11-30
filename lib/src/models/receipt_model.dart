import 'package:flutter/material.dart';

class Receipt {
  final String id;
  final String transactionId;
  final double amount;
  final DateTime dateTime;
  final String paymentMethod;
  final String status; // Paid, Refunded, Failed
  final String referenceId;
  final String studentName;
  final String hostelBlock;
  final String roomNumber;
  final String messType;

  Receipt({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.dateTime,
    required this.paymentMethod,
    required this.status,
    required this.referenceId,
    required this.studentName,
    required this.hostelBlock,
    required this.roomNumber,
    required this.messType,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as String,
      transactionId: json['transactionId'] as String,
      amount: (json['amount'] as num).toDouble(),
      dateTime: DateTime.parse(json['dateTime'] as String),
      paymentMethod: json['paymentMethod'] as String,
      status: json['status'] as String,
      referenceId: json['referenceId'] as String,
      studentName: json['studentName'] as String,
      hostelBlock: json['hostelBlock'] as String,
      roomNumber: json['roomNumber'] as String,
      messType: json['messType'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'amount': amount,
      'dateTime': dateTime.toIso8601String(),
      'paymentMethod': paymentMethod,
      'status': status,
      'referenceId': referenceId,
      'studentName': studentName,
      'hostelBlock': hostelBlock,
      'roomNumber': roomNumber,
      'messType': messType,
    };
  }

  IconData get getPaymentIcon {
    switch (paymentMethod.toLowerCase()) {
      case 'upi':
        return Icons.flash_on_outlined;
      case 'card':
        return Icons.credit_card_outlined;
      case 'cash':
        return Icons.money_outlined;
      default:
        return Icons.payment_outlined;
    }
  }

  Color getStatusColor(BuildContext context) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF4CAF50); // Green
      case 'refunded':
        return const Color(0xFFFF9800); // Orange
      case 'failed':
        return const Color(0xFFF44336); // Red
      default:
        return Theme.of(context).primaryColor;
    }
  }
}
