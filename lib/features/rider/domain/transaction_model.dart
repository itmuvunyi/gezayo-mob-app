import 'dart:convert';
import 'package:equatable/equatable.dart';

enum TransactionType { jobEarning, withdrawal, bonus, deposit }


enum TransactionStatus { completed, processed, pending }

class TransactionModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String dateText;
  final double amountRwf;
  final TransactionType type;
  final TransactionStatus status;

  const TransactionModel({
    required this.id,
    this.userId = '',
    required this.title,
    required this.dateText,
    required this.amountRwf,
    required this.type,
    required this.status,
  });

  bool get isPositive => type != TransactionType.withdrawal;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'dateText': dateText,
      'amountRwf': amountRwf,
      'type': type.name,
      'status': status.name,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      dateText: map['dateText'] ?? '',
      amountRwf: (map['amountRwf'] ?? 0.0).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.jobEarning,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TransactionStatus.completed,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory TransactionModel.fromJson(String source) =>
      TransactionModel.fromMap(json.decode(source));

  @override
  List<Object?> get props => [id, userId, title, dateText, amountRwf, type, status];
}
