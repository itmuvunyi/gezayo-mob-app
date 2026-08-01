import 'dart:convert';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role; // 'customer' or 'rider'
  final String avatarUrl;
  final double rating;
  final int totalDeliveries;
  final bool isOnline;
  final double latitude;
  final double longitude;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.avatarUrl = '',
    this.rating = 0.0,
    this.totalDeliveries = 0,
    this.isOnline = false,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  bool get isRider => role == 'rider';
  bool get isCustomer => role == 'customer';

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? role,
    String? avatarUrl,
    double? rating,
    int? totalDeliveries,
    bool? isOnline,
    double? latitude,
    double? longitude,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      isOnline: isOnline ?? this.isOnline,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'avatarUrl': avatarUrl,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'isOnline': isOnline,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      role: map['role'] ?? 'customer',
      avatarUrl: map['avatarUrl'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalDeliveries: map['totalDeliveries'] ?? 0,
      isOnline: map['isOnline'] ?? false,
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));

  @override
  List<Object?> get props => [
        uid,
        fullName,
        email,
        phoneNumber,
        role,
        avatarUrl,
        rating,
        totalDeliveries,
        isOnline,
        latitude,
        longitude,
      ];
}