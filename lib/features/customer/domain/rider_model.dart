import 'dart:convert';
import 'package:equatable/equatable.dart';

class RiderModel extends Equatable {
  final String id;
  final String name;
  final double rating;
  final int completedJobs;
  final String vehicleType; // 'EV Motor' | 'Fuel Moto'
  final String etaText;
  final String avatarUrl;
  final String distanceText;

  const RiderModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.completedJobs,
    required this.vehicleType,
    required this.etaText,
    this.avatarUrl = '',
    this.distanceText = '1.2 km',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'completedJobs': completedJobs,
      'vehicleType': vehicleType,
      'etaText': etaText,
      'avatarUrl': avatarUrl,
      'distanceText': distanceText,
    };
  }

  factory RiderModel.fromMap(Map<String, dynamic> map) {
    return RiderModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      rating: (map['rating'] ?? 4.9).toDouble(),
      completedJobs: map['completedJobs'] ?? 0,
      vehicleType: map['vehicleType'] ?? 'EV Motor',
      etaText: map['etaText'] ?? '3 min',
      avatarUrl: map['avatarUrl'] ?? '',
      distanceText: map['distanceText'] ?? '1.2 km',
    );
  }

  String toJson() => json.encode(toMap());

  factory RiderModel.fromJson(String source) =>
      RiderModel.fromMap(json.decode(source));

  @override
  List<Object?> get props => [
        id,
        name,
        rating,
        completedJobs,
        vehicleType,
        etaText,
        avatarUrl,
        distanceText,
      ];
}
