import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_service.dart';

final backendApiServiceProvider = Provider<BackendApiService>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return BackendApiService(db);
});

class ApiResponse<T> {
  final int statusCode;
  final T? data;
  final String message;
  final bool isSuccess;

  ApiResponse({
    required this.statusCode,
    this.data,
    this.message = '',
    required this.isSuccess,
  });

  factory ApiResponse.success(T data,
      {int statusCode = 200, String message = 'Success'}) {
    return ApiResponse(
      statusCode: statusCode,
      data: data,
      message: message,
      isSuccess: true,
    );
  }

  factory ApiResponse.error(String message, {int statusCode = 400}) {
    return ApiResponse(
      statusCode: statusCode,
      data: null,
      message: message,
      isSuccess: false,
    );
  }
}

class BackendApiService {
  final DatabaseService _db;

  BackendApiService(this._db);

  // Simulated REST Request Delay
  Future<void> _delay() async {
    await Future.delayed(const Duration(milliseconds: 250));
  }

  // --- AUTH ENDPOINTS ---

  Future<ApiResponse<Map<String, dynamic>>> loginWithEmail(
      String email, String password, {String role = 'customer'}) async {
    await _delay();
    if (email.isEmpty || password.isEmpty) {
      return ApiResponse.error('Email and password cannot be empty.',
          statusCode: 400);
    }

    final userMap = {
      'uid': 'usr-${email.hashCode}',
      'fullName': 'Jean-Paul N.',
      'email': email,
      'phoneNumber': '+250 788 000 000',
      'role': role,
      'avatarUrl': '',
      'rating': 4.9,
      'totalDeliveries': 24,
      'isOnline': true,
    };
    await _db.saveUser(userMap);
    return ApiResponse.success(userMap,
        statusCode: 200, message: 'Logged in successfully.');
  }

  Future<ApiResponse<Map<String, dynamic>>> signUpWithPhone(
      String phone, String name, String role) async {
    await _delay();
    if (phone.isEmpty) {
      return ApiResponse.error('Phone number is required.', statusCode: 400);
    }

    final userMap = {
      'uid': 'usr-${phone.hashCode}',
      'fullName': name.isNotEmpty ? name : 'New User',
      'email': '${phone.replaceAll(RegExp(r'\D'), '')}@gezayo.rw',
      'phoneNumber': phone,
      'role': role,
      'avatarUrl': '',
      'rating': 5.0,
      'totalDeliveries': 0,
      'isOnline': true,
    };
    await _db.saveUser(userMap);
    return ApiResponse.success(userMap,
        statusCode: 201, message: 'User registered via Phone OTP.');
  }

  Future<ApiResponse<Map<String, dynamic>>> signInWithGoogle() async {
    await _delay();
    final userMap = {
      'uid': 'usr-google-999',
      'fullName': 'Google User',
      'email': 'user@google.com',
      'phoneNumber': '+250 788 999 888',
      'role': 'customer',
      'avatarUrl': '',
      'rating': 4.9,
      'totalDeliveries': 10,
      'isOnline': true,
    };
    await _db.saveUser(userMap);
    return ApiResponse.success(userMap,
        statusCode: 200, message: 'Google sign-in successful.');
  }

  // --- DELIVERY ENDPOINTS ---

  Future<ApiResponse<Map<String, dynamic>>> createDeliveryRequest(
      Map<String, dynamic> deliveryData) async {
    await _delay();
    final newId =
        'GZ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final fullData = {
      ...deliveryData,
      'id': newId,
      'status': 'searching',
      'createdAt': DateTime.now().toIso8601String(),
    };

    await _db.saveDelivery(fullData);
    return ApiResponse.success(fullData,
        statusCode: 201, message: 'Delivery request created.');
  }

  Future<ApiResponse<Map<String, dynamic>?>> getActiveDelivery() async {
    await _delay();
    final deliveries = _db.getDeliveries();
    if (deliveries.isEmpty) {
      return ApiResponse.success(null, statusCode: 200);
    }
    return ApiResponse.success(deliveries.last, statusCode: 200);
  }

  Future<ApiResponse<Map<String, dynamic>>> updateDeliveryStatus(
      String deliveryId, Map<String, dynamic> updates) async {
    await _delay();
    final deliveries = _db.getDeliveries();
    final index = deliveries.indexWhere((d) => d['id'] == deliveryId);

    if (index >= 0) {
      final updated = {...deliveries[index], ...updates};
      await _db.saveDelivery(updated);
      return ApiResponse.success(updated,
          statusCode: 200, message: 'Delivery updated.');
    }
    return ApiResponse.error('Delivery not found.', statusCode: 404);
  }

  // --- RIDER ENDPOINTS ---

  Future<ApiResponse<List<Map<String, dynamic>>>> getNearbyRiders() async {
    await _delay();
    final riders = _db.getRiders();
    return ApiResponse.success(riders, statusCode: 200);
  }

  Future<ApiResponse<Map<String, dynamic>>> withdrawToMoMo(
      double amount, String userId) async {
    await _delay();
    if (amount <= 0) {
      return ApiResponse.error('Withdrawal amount must be greater than 0.',
          statusCode: 400);
    }

    final txMap = {
      'id':
          'tx-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'title': 'Withdrawal to MTN MoMo',
      'dateText': 'Just now',
      'amountRwf': amount,
      'type': 'withdrawal',
      'status': 'completed',
    };
    await _db.addTransaction(txMap);
    return ApiResponse.success(txMap,
        statusCode: 200, message: 'Withdrawal processed successfully.');
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getTransactions() async {
    await _delay();
    final txs = _db.getTransactions();
    return ApiResponse.success(txs, statusCode: 200);
  }
}
