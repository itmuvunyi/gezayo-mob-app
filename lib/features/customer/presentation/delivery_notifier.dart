import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../domain/delivery_model.dart';
import '../domain/rider_model.dart';
import '../data/delivery_repository.dart';

class DeliveryState {
  final DeliveryModel? activeDelivery;
  final List<RiderModel> availableRiders;
  final bool isAutoAssign;
  final bool isLoading;
  final String? errorMessage;

  const DeliveryState({
    this.activeDelivery,
    this.availableRiders = const [],
    this.isAutoAssign = true,
    this.isLoading = false,
    this.errorMessage,
  });

  DeliveryState copyWith({
    DeliveryModel? activeDelivery,
    List<RiderModel>? availableRiders,
    bool? isAutoAssign,
    bool? isLoading,
    String? errorMessage,
    bool clearActiveDelivery = false,
  }) {
    return DeliveryState(
      activeDelivery:
          clearActiveDelivery ? null : (activeDelivery ?? this.activeDelivery),
      availableRiders: availableRiders ?? this.availableRiders,
      isAutoAssign: isAutoAssign ?? this.isAutoAssign,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final deliveryNotifierProvider =
    StateNotifierProvider<DeliveryNotifier, DeliveryState>((ref) {
  final repo = ref.watch(deliveryRepositoryProvider);
  final firestore = ref.watch(firestoreServiceProvider);
  return DeliveryNotifier(repo, firestore);
});

class DeliveryNotifier extends StateNotifier<DeliveryState> {
  final DeliveryRepository _repository;
  final FirestoreService _firestoreService;
  StreamSubscription? _deliverySubscription;

  DeliveryNotifier(this._repository, this._firestoreService)
      : super(const DeliveryState()) {
    _initRiders();
  }

  @override
  void dispose() {
    _deliverySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initRiders() async {
    final riders = await _repository.fetchNearbyRiders();
    state = state.copyWith(availableRiders: riders);
  }

  Future<void> createDeliveryRequest({
    required String pickupAddress,
    required String dropoffAddress,
    required String packageType,
    required String weightClass,
    required String instructions,
    required double estimatedFare,
    String customerUid = '',
    String customerPhone = '',
  }) async {
    state = state.copyWith(isLoading: true);
    final delivery = await _repository.createDeliveryRequest(
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      packageType: packageType,
      weightClass: weightClass,
      instructions: instructions,
      estimatedFare: estimatedFare,
      customerUid: customerUid,
      customerPhone: customerPhone,
    );
    state = state.copyWith(activeDelivery: delivery, isLoading: false);

    // Listen to real-time updates for this delivery
    if (delivery != null) {
      listenToDelivery(delivery.id);
    }
  }

  void setActiveDelivery(DeliveryModel delivery) {
    state = state.copyWith(activeDelivery: delivery);
    listenToDelivery(delivery.id);
  }

  void listenToDelivery(String deliveryId) {
    _deliverySubscription?.cancel();
    _deliverySubscription =
        _firestoreService.getDeliveryStream(deliveryId).listen((delivery) {
      if (delivery != null && mounted) {
        state = state.copyWith(activeDelivery: delivery);
      }
    });
  }

  Future<void> selectRider(RiderModel rider) async {
    if (state.activeDelivery != null) {
      state = state.copyWith(isLoading: true);
      final updated =
          await _repository.assignRider(state.activeDelivery!, rider);
      state = state.copyWith(activeDelivery: updated, isLoading: false);
    }
  }

  void toggleAssignMode(bool isAuto) {
    state = state.copyWith(isAutoAssign: isAuto);
  }

  Future<void> addTip(double tipAmount) async {
    if (state.activeDelivery != null) {
      final updated =
          await _repository.addTip(state.activeDelivery!, tipAmount);
      state = state.copyWith(activeDelivery: updated);
    }
  }

  Future<void> setRating(int stars) async {
    if (state.activeDelivery != null) {
      final updated = await _repository.setRating(state.activeDelivery!, stars);
      state = state.copyWith(activeDelivery: updated);
    }
  }

  Future<void> loadActiveDeliveryForUser(String userId) async {
    _deliverySubscription?.cancel();
    if (userId.isEmpty) {
      state = state.copyWith(clearActiveDelivery: true);
      return;
    }
    final active = await _repository.getActiveDelivery(userId);
    if (active != null && mounted) {
      state = state.copyWith(activeDelivery: active);
      listenToDelivery(active.id);
    } else if (mounted) {
      state = state.copyWith(clearActiveDelivery: true);
    }
  }

  void resetState() {
    _deliverySubscription?.cancel();
    state = const DeliveryState();
  }

  Future<void> clearActiveDelivery([String? deliveryId]) async {
    final id = deliveryId ?? state.activeDelivery?.id;
    if (id != null && id.isNotEmpty) {
      await _repository.clearActiveDelivery(id);
    }
    _deliverySubscription?.cancel();
    state = state.copyWith(clearActiveDelivery: true);
  }

  Future<void> completeAndClearOrder() async {
    await clearActiveDelivery();
  }
}

