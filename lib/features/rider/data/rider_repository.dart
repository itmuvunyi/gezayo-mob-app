import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/backend_api_service.dart';
import '../../../core/services/firestore_service.dart';
import '../domain/transaction_model.dart';

final riderRepositoryProvider = Provider<RiderRepository>((ref) {
  final api = ref.watch(backendApiServiceProvider);
  final firestore = ref.watch(firestoreServiceProvider);
  return RiderRepositoryImpl(api, firestore);
});

abstract class RiderRepository {
  Future<bool> getOnlineStatus();
  Future<bool> setOnlineStatus(bool isOnline);
  Future<double> getTotalBalance();
  Future<double> getEarnedToday();
  Future<int> getJobsDoneToday();
  Future<List<TransactionModel>> getTransactions();
  Future<List<TransactionModel>> fetchTransactions();
  Future<bool> withdrawToMoMo(double amount, String userId);
}

class RiderRepositoryImpl implements RiderRepository {
  final BackendApiService _apiService;
  final FirestoreService _firestoreService;
  bool _isOnline = false;

  RiderRepositoryImpl(this._apiService, this._firestoreService);

  @override
  Future<bool> getOnlineStatus() async => _isOnline;

  @override
  Future<bool> setOnlineStatus(bool isOnline) async {
    _isOnline = isOnline;
    return true;
  }

  @override
  Future<double> getTotalBalance() async {
    final txs = await getTransactions();
    double balance = 0.0;
    for (final tx in txs) {
      if (tx.isPositive) {
        balance += tx.amountRwf;
      } else {
        balance -= tx.amountRwf;
      }
    }
    return balance < 0 ? 0.0 : balance;
  }

  @override
  Future<double> getEarnedToday() async {
    final txs = await getTransactions();
    double todayEarned = 0.0;
    for (final tx in txs) {
      if (tx.isPositive) {
        todayEarned += tx.amountRwf;
      }
    }
    return todayEarned;
  }

  @override
  Future<int> getJobsDoneToday() async {
    final txs = await getTransactions();
    return txs.where((t) => t.isPositive).length;
  }

  @override
  Future<List<TransactionModel>> getTransactions() => fetchTransactions();

  @override
  Future<List<TransactionModel>> fetchTransactions() async {
    final firestoreTx = await _firestoreService.getTransactions('rider-1');
    if (firestoreTx.isNotEmpty) {
      return firestoreTx;
    }

    final response = await _apiService.getTransactions();
    if (response.isSuccess && response.data != null) {
      return response.data!.map((m) => TransactionModel.fromMap(m)).toList();
    }
    return [];
  }

  @override
  Future<bool> withdrawToMoMo(double amount, String userId) async {
    final response = await _apiService.withdrawToMoMo(amount, userId);
    if (response.isSuccess && response.data != null) {
      final tx = TransactionModel.fromMap(response.data!);
      await _firestoreService.addTransaction(tx);
      return true;
    }
    return response.isSuccess;
  }
}
