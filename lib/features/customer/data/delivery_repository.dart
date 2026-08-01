import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/backend_api_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../rider/domain/transaction_model.dart';
import '../domain/delivery_model.dart';
import '../domain/rider_model.dart';


final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  final api = ref.watch(backendApiServiceProvider);
  final firestore = ref.watch(firestoreServiceProvider);
  return DeliveryRepositoryImpl(api, firestore);
});

abstract class DeliveryRepository {
  Future<DeliveryModel?> createDeliveryRequest({
    required String pickupAddress,
    required String dropoffAddress,
    required String packageType,
    required String weightClass,
    required String instructions,
    required double estimatedFare,
    String customerUid = '',
    String customerPhone = '',
  });

  Future<DeliveryModel?> getActiveDelivery([String userId = '']);
  Future<List<RiderModel>> fetchNearbyRiders();
  Future<DeliveryModel?> assignRider(DeliveryModel current, RiderModel rider);
  Future<DeliveryModel?> addTip(DeliveryModel current, double tipRwf);
  Future<DeliveryModel?> setRating(DeliveryModel current, int stars);
  Future<void> clearActiveDelivery(String deliveryId);
}

class DeliveryRepositoryImpl implements DeliveryRepository {
  final BackendApiService _apiService;
  final FirestoreService _firestoreService;

  DeliveryRepositoryImpl(this._apiService, this._firestoreService);

  @override
  Future<DeliveryModel?> createDeliveryRequest({
    required String pickupAddress,
    required String dropoffAddress,
    required String packageType,
    required String weightClass,
    required String instructions,
    required double estimatedFare,
    String customerUid = '',
    String customerPhone = '',
  }) async {
    final payload = {
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'packageType': packageType,
      'weightClass': weightClass,
      'instructions': instructions,
      'estimatedFareRwf': estimatedFare,
      'customerUid': customerUid,
      'customerPhone': customerPhone,
      'status': 'searching',
      'createdAt': DateTime.now().toIso8601String(),
    };

    final response = await _apiService.createDeliveryRequest(payload);
    if (response.isSuccess && response.data != null) {
      final model = DeliveryModel.fromMap(response.data!);
      await _firestoreService.createDelivery(model);
      return model;
    }
    return null;
  }

  @override
  Future<DeliveryModel?> getActiveDelivery([String userId = '']) async {
    if (userId.isEmpty) return null;
    return await _firestoreService.getActiveDelivery(userId);
  }

  @override
  Future<List<RiderModel>> fetchNearbyRiders() async {
    return await _firestoreService.getNearbyRiders();
  }

  @override
  Future<DeliveryModel?> assignRider(
      DeliveryModel current, RiderModel rider) async {
    final updates = {
      'status': 'assigned',
      'assignedRiderName': rider.name,
      'assignedRiderRating': rider.rating,
    };
    await _firestoreService.updateDelivery(current.id, updates);
    final response =
        await _apiService.updateDeliveryStatus(current.id, updates);
    if (response.isSuccess && response.data != null) {
      return DeliveryModel.fromMap(response.data!);
    }
    return current.copyWith(
      status: DeliveryStatus.assigned,
      assignedRiderName: rider.name,
      assignedRiderRating: rider.rating,
    );
  }

  @override
  Future<DeliveryModel?> addTip(DeliveryModel current, double tipRwf) async {
    final newTip = current.tipAmount + tipRwf;
    final updates = {'tipAmount': newTip};
    await _firestoreService.updateDelivery(current.id, updates);

    // 1. Debit Customer Wallet Balance for Tip
    final customerUid = current.customerUid;
    if (customerUid.isNotEmpty && tipRwf > 0) {
      final custTx = TransactionModel(
        id: 'tx-tip-cust-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        userId: customerUid,
        title: 'Rider Tip #${current.id.substring(0, current.id.length > 8 ? 8 : current.id.length)}',
        dateText: 'Just now',
        amountRwf: tipRwf,
        type: TransactionType.withdrawal,
        status: TransactionStatus.completed,
      );
      await _firestoreService.addTransaction(custTx);
    }

    // 2. Credit Rider Bonus Balance for Tip
    final riderUid = current.assignedRiderUid ?? '';
    if (riderUid.isNotEmpty && tipRwf > 0) {
      final riderTx = TransactionModel(
        id: 'tx-tip-rider-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        userId: riderUid,
        title: 'Tip Bonus #${current.id.substring(0, current.id.length > 8 ? 8 : current.id.length)}',
        dateText: 'Just now',
        amountRwf: tipRwf,
        type: TransactionType.bonus,
        status: TransactionStatus.completed,
      );
      await _firestoreService.addTransaction(riderTx);
    }

    final response =
        await _apiService.updateDeliveryStatus(current.id, updates);
    if (response.isSuccess && response.data != null) {
      return DeliveryModel.fromMap(response.data!);
    }
    return current.copyWith(tipAmount: newTip);
  }


  @override
  Future<DeliveryModel?> setRating(DeliveryModel current, int stars) async {
    final updates = {'ratingGiven': stars};
    await _firestoreService.updateDelivery(current.id, updates);
    final response =
        await _apiService.updateDeliveryStatus(current.id, updates);
    if (response.isSuccess && response.data != null) {
      return DeliveryModel.fromMap(response.data!);
    }
    return current.copyWith(ratingGiven: stars);
  }

  @override
  Future<void> clearActiveDelivery(String deliveryId) async {
    await _firestoreService.confirmDeliveryByCustomer(deliveryId);
    await _apiService.updateDeliveryStatus(deliveryId, {'status': 'completed'});
  }
}
