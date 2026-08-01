import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/firestore_service.dart';
import '../domain/transaction_model.dart';
import '../data/rider_repository.dart';

class RiderState {
  final bool isOnline;
  final double totalBalanceRwf;
  final double earnedTodayRwf;
  final int jobsDoneToday;
  final String? activeJobId;
  final List<TransactionModel> transactions;
  final bool isLoading;
  final double? currentLat;
  final double? currentLng;

  const RiderState({
    this.isOnline = false,
    this.totalBalanceRwf = 0.0,
    this.earnedTodayRwf = 0.0,
    this.jobsDoneToday = 0,
    this.activeJobId,
    this.transactions = const [],
    this.isLoading = false,
    this.currentLat,
    this.currentLng,
  });

  // Convenience Aliases for UI & Tests
  double get todayEarningsRwf => earnedTodayRwf;
  int get jobsCompletedCount => jobsDoneToday;

  RiderState copyWith({
    bool? isOnline,
    double? totalBalanceRwf,
    double? earnedTodayRwf,
    int? jobsDoneToday,
    String? activeJobId,
    List<TransactionModel>? transactions,
    bool? isLoading,
    double? currentLat,
    double? currentLng,
    bool clearActiveJob = false,
  }) {
    return RiderState(
      isOnline: isOnline ?? this.isOnline,
      totalBalanceRwf: totalBalanceRwf ?? this.totalBalanceRwf,
      earnedTodayRwf: earnedTodayRwf ?? this.earnedTodayRwf,
      jobsDoneToday: jobsDoneToday ?? this.jobsDoneToday,
      activeJobId: clearActiveJob ? null : (activeJobId ?? this.activeJobId),
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
    );
  }
}

class RiderNotifier extends StateNotifier<RiderState> {
  final RiderRepository _repository;
  final FirestoreService _firestoreService;
  StreamSubscription? _activeJobSubscription;
  StreamSubscription? _txSubscription;

  RiderNotifier({
    required RiderRepository repository,
    required FirestoreService firestoreService,
  })  : _repository = repository,
        _firestoreService = firestoreService,
        super(const RiderState()) {
    _loadInitialState();
  }

  @override
  void dispose() {
    _activeJobSubscription?.cancel();
    _txSubscription?.cancel();
    super.dispose();
  }

  void syncRiderTransactions(String riderUid) {
    _txSubscription?.cancel();
    _txSubscription =
        _firestoreService.getTransactionsStream(riderUid).listen((txs) {
      _updateRiderEarningsAndState(riderUid, txs);
    });

    _firestoreService.getRiderCompletedJobsStream(riderUid).listen((completedJobs) {
      final currentTxs = List<TransactionModel>.from(state.transactions);
      for (final job in completedJobs) {
        final exists = currentTxs.any((t) => t.id.contains(job.id));
        if (!exists) {
          currentTxs.add(
            TransactionModel(
              id: 'tx-job-${job.id}',
              userId: riderUid,
              title: 'Delivery #${job.id.length > 8 ? job.id.substring(0, 8) : job.id}',
              dateText: 'Completed',
              amountRwf: job.estimatedFareRwf,
              type: TransactionType.jobEarning,
              status: TransactionStatus.completed,
            ),
          );
        }
      }
      _updateRiderEarningsAndState(riderUid, currentTxs);
    });
  }

  void _updateRiderEarningsAndState(String riderUid, List<TransactionModel> txs) {
    double balance = 0.0;
    double todayEarned = 0.0;
    int jobsDoneCount = 0;
    for (final tx in txs) {
      if (tx.type == TransactionType.jobEarning ||
          tx.type == TransactionType.bonus) {
        balance += tx.amountRwf;
        todayEarned += tx.amountRwf;
        if (tx.type == TransactionType.jobEarning) {
          jobsDoneCount += 1;
        }
      } else if (tx.type == TransactionType.deposit) {
        balance += tx.amountRwf;
      } else if (tx.type == TransactionType.withdrawal) {
        balance -= tx.amountRwf;
      }
    }
    state = state.copyWith(
      totalBalanceRwf: balance < 0 ? 0.0 : balance,
      earnedTodayRwf: todayEarned,
      jobsDoneToday: jobsDoneCount,
      transactions: txs,
      isLoading: false,
    );
  }


  void syncActiveRiderJob(String riderUid) {
    _activeJobSubscription?.cancel();
    _activeJobSubscription =
        _firestoreService.getActiveRiderJobStream(riderUid).listen((activeJob) {
      if (activeJob != null) {
        state = state.copyWith(activeJobId: activeJob.id);
      }
    });
  }

  Future<void> _loadInitialState() async {
    state = state.copyWith(isLoading: true);
    final isOnline = await _repository.getOnlineStatus();

    syncRiderTransactions('');
    syncActiveRiderJob('');

    state = state.copyWith(
      isOnline: isOnline,
      isLoading: false,
    );
  }

  Future<void> autoSetOnline(String riderUid) async {
    state = state.copyWith(isOnline: true);
    await _repository.setOnlineStatus(true);
    await updateCurrentLocation(riderUid);
    if (riderUid.isNotEmpty) {
      await _firestoreService.updateRiderOnlineStatus(riderUid, true);
    }
  }

  Future<void> toggleOnlineStatus(

      [bool? newStatus, String riderUid = 'rider-1']) async {
    final nextStatus = newStatus ?? !state.isOnline;
    final success = await _repository.setOnlineStatus(nextStatus);

    if (success) {
      state = state.copyWith(isOnline: nextStatus);
      if (nextStatus) {
        await updateCurrentLocation(riderUid);
      }
      await _firestoreService.updateRiderOnlineStatus(riderUid, nextStatus);
    }
  }

  /// Update current GPS location and push to Firestore rider location
  Future<void> updateCurrentLocation([String riderUid = 'rider-1']) async {
    try {
      if (kIsWeb) {
        // Fallback coordinates for Kigali, Rwanda on web
        const lat = -1.9441;
        const lng = 30.0619;
        state = state.copyWith(currentLat: lat, currentLng: lng);
        await _firestoreService.updateRiderLocation(
          riderUid,
          lat,
          lng,
          state.isOnline,
        );
        return;
      }

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        final req = await Geolocator.requestPermission();
        if (req != LocationPermission.whileInUse &&
            req != LocationPermission.always) {
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      state =
          state.copyWith(currentLat: pos.latitude, currentLng: pos.longitude);

      await _firestoreService.updateRiderLocation(
        riderUid,
        pos.latitude,
        pos.longitude,
        state.isOnline,
      );
    } catch (e) {
      debugPrint('Location fetch error: $e');
    }
  }

  /// Atomically accept a delivery job — checks if job is still available ('searching').
  /// Returns true if successfully accepted, false if already taken by another rider.
  Future<bool> acceptJob(String jobId, double fareRwf,
      [String riderUid = '',
      String riderName = '',
      double riderRating = 5.0,
      String riderPhone = '']) async {
    final success = await _firestoreService.acceptJobAtomic(
        jobId, riderUid, riderName, riderRating, riderPhone);

    if (success) {
      state = state.copyWith(activeJobId: jobId);
      return true;
    }
    return false;
  }

  /// Cancel/reject an active job — reverts status back to 'searching' in Firestore
  /// so it stays available on the dashboard for riders.
  Future<void> cancelActiveJob() async {
    final jobId = state.activeJobId;
    if (jobId != null && jobId.isNotEmpty) {
      await _firestoreService.cancelJobByRider(jobId);
    }
    state = state.copyWith(clearActiveJob: true);
  }

  /// Mark package picked up by rider — updates status to 'pickedUp' in Firestore.
  Future<void> markPickedUp() async {
    final jobId = state.activeJobId;
    if (jobId != null && jobId.isNotEmpty) {
      await _firestoreService.updateDelivery(jobId, {'status': 'pickedUp'});
    }
  }

  /// Complete current delivery job — updates status to 'delivered' in Firestore (awaiting customer confirmation).
  Future<void> completeCurrentJob([double fareRwf = 0.0]) async {
    final jobId = state.activeJobId;
    if (jobId != null && jobId.isNotEmpty) {
      await _firestoreService.completeJobByRider(jobId);
    }

    state = state.copyWith(
      clearActiveJob: true,
    );
  }

  Future<bool> withdrawToMoMo(double amount) async {
    if (amount <= 0 || amount > state.totalBalanceRwf) {
      return false;
    }

    state = state.copyWith(isLoading: true);
    final success = await _repository.withdrawToMoMo(amount, 'rider-1');

    if (success) {
      final updatedBalance = state.totalBalanceRwf - amount;
      final newTx = TransactionModel(
        id: 'tx-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        title: 'Withdrawal to MTN MoMo',
        dateText: 'Just now',
        amountRwf: amount,
        type: TransactionType.withdrawal,
        status: TransactionStatus.completed,
      );

      state = state.copyWith(
        totalBalanceRwf: updatedBalance,
        transactions: [newTx, ...state.transactions],
        isLoading: false,
      );
      return true;
    }

    state = state.copyWith(isLoading: false);
    return false;
  }
}

final riderNotifierProvider =
    StateNotifierProvider<RiderNotifier, RiderState>((ref) {
  final repository = ref.watch(riderRepositoryProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return RiderNotifier(
      repository: repository, firestoreService: firestoreService);
});
