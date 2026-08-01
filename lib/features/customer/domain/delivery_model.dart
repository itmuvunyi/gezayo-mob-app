import 'dart:convert';
import 'package:equatable/equatable.dart';

enum DeliveryStatus {
  searching,
  assigned,
  pickedUp,
  onTheWay,
  delivered,
  completed,
  cancelled,
}

class DeliveryModel extends Equatable {
  final String id;
  final String customerUid;
  final String? customerPhone;
  final String pickupAddress;
  final String dropoffAddress;
  final String packageType; // 'Food', 'Parcel', 'Grocery', 'Other'
  final String
      weightClass; // 'Light (<5kg)', 'Medium (5-15kg)', 'Heavy (>15kg)'
  final String instructions;
  final double estimatedFareRwf;
  final DeliveryStatus status;
  final String? assignedRiderUid;
  final String? assignedRiderName;
  final String? assignedRiderPhone;
  final double assignedRiderRating;
  final int estimatedArrivalMins;
  final double tipAmount;
  final int ratingGiven;
  final String createdAt;

  const DeliveryModel({
    required this.id,
    this.customerUid = '',
    this.customerPhone,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.packageType,
    required this.weightClass,
    this.instructions = '',
    required this.estimatedFareRwf,
    this.status = DeliveryStatus.searching,
    this.assignedRiderUid,
    this.assignedRiderName,
    this.assignedRiderPhone,
    this.assignedRiderRating = 0.0,
    this.estimatedArrivalMins = 0,
    this.tipAmount = 0.0,
    this.ratingGiven = 0,
    this.createdAt = '',
  });

  double get totalPaid => estimatedFareRwf + tipAmount;

  DeliveryModel copyWith({
    String? id,
    String? customerUid,
    String? customerPhone,
    String? pickupAddress,
    String? dropoffAddress,
    String? packageType,
    String? weightClass,
    String? instructions,
    double? estimatedFareRwf,
    DeliveryStatus? status,
    String? assignedRiderUid,
    String? assignedRiderName,
    String? assignedRiderPhone,
    double? assignedRiderRating,
    int? estimatedArrivalMins,
    double? tipAmount,
    int? ratingGiven,
    String? createdAt,
  }) {
    return DeliveryModel(
      id: id ?? this.id,
      customerUid: customerUid ?? this.customerUid,
      customerPhone: customerPhone ?? this.customerPhone,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      packageType: packageType ?? this.packageType,
      weightClass: weightClass ?? this.weightClass,
      instructions: instructions ?? this.instructions,
      estimatedFareRwf: estimatedFareRwf ?? this.estimatedFareRwf,
      status: status ?? this.status,
      assignedRiderUid: assignedRiderUid ?? this.assignedRiderUid,
      assignedRiderName: assignedRiderName ?? this.assignedRiderName,
      assignedRiderPhone: assignedRiderPhone ?? this.assignedRiderPhone,
      assignedRiderRating: assignedRiderRating ?? this.assignedRiderRating,
      estimatedArrivalMins: estimatedArrivalMins ?? this.estimatedArrivalMins,
      tipAmount: tipAmount ?? this.tipAmount,
      ratingGiven: ratingGiven ?? this.ratingGiven,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerUid': customerUid,
      'customerPhone': customerPhone,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'packageType': packageType,
      'weightClass': weightClass,
      'instructions': instructions,
      'estimatedFareRwf': estimatedFareRwf,
      'status': status.name,
      'assignedRiderUid': assignedRiderUid,
      'assignedRiderName': assignedRiderName,
      'assignedRiderPhone': assignedRiderPhone,
      'assignedRiderRating': assignedRiderRating,
      'estimatedArrivalMins': estimatedArrivalMins,
      'tipAmount': tipAmount,
      'ratingGiven': ratingGiven,
      'createdAt': createdAt,
    };
  }

  factory DeliveryModel.fromMap(Map<String, dynamic> map) {
    return DeliveryModel(
      id: map['id'] ?? '',
      customerUid: map['customerUid'] ?? '',
      customerPhone: map['customerPhone'],
      pickupAddress: map['pickupAddress'] ?? '',
      dropoffAddress: map['dropoffAddress'] ?? '',
      packageType: map['packageType'] ?? 'Parcel',
      weightClass: map['weightClass'] ?? 'Light (<5kg)',
      instructions: map['instructions'] ?? '',
      estimatedFareRwf: (map['estimatedFareRwf'] ?? 0.0).toDouble(),
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DeliveryStatus.searching,
      ),
      assignedRiderUid: map['assignedRiderUid'],
      assignedRiderName: map['assignedRiderName'],
      assignedRiderPhone: map['assignedRiderPhone'],
      assignedRiderRating: (map['assignedRiderRating'] ?? 0.0).toDouble(),
      estimatedArrivalMins: map['estimatedArrivalMins'] ?? 0,
      tipAmount: (map['tipAmount'] ?? 0.0).toDouble(),
      ratingGiven: map['ratingGiven'] ?? 0,
      createdAt: map['createdAt'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory DeliveryModel.fromJson(String source) =>
      DeliveryModel.fromMap(json.decode(source));

  @override
  List<Object?> get props => [
        id,
        customerUid,
        customerPhone,
        pickupAddress,
        dropoffAddress,
        packageType,
        weightClass,
        instructions,
        estimatedFareRwf,
        status,
        assignedRiderUid,
        assignedRiderName,
        assignedRiderPhone,
        assignedRiderRating,
        estimatedArrivalMins,
        tipAmount,
        ratingGiven,
        createdAt,
      ];
}
