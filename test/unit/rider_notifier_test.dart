import 'package:flutter_test/flutter_test.dart';

import 'package:gezayo_app/core/services/database_service.dart';
import 'package:gezayo_app/core/services/firestore_service.dart';
import 'package:gezayo_app/features/rider/data/rider_repository.dart';
import 'package:gezayo_app/features/rider/domain/transaction_model.dart';
import 'package:gezayo_app/features/rider/presentation/rider_notifier.dart';

class MockRiderRepository implements RiderRepository {
  bool isOnline = true;
  double balance = 0;

  @override
  Future<bool> getOnlineStatus() async => isOnline;

  @override
  Future<bool> setOnlineStatus(bool online) async {
    isOnline = online;
    return true;
  }

  @override
  Future<double> getTotalBalance() async => balance;

  @override
  Future<double> getEarnedToday() async => 0.0;

  @override
  Future<int> getJobsDoneToday() async => 0;

  @override
  Future<List<TransactionModel>> getTransactions() async => [];

  @override
  Future<List<TransactionModel>> fetchTransactions() async => [];

  @override
  Future<bool> withdrawToMoMo(double amount, String userId) async => true;
}

class MockDatabaseService implements DatabaseService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  List<Map<String, dynamic>> getTransactions() => [];
  @override
  Future<void> addTransaction(Map<String, dynamic> tx) async {}
  @override
  List<Map<String, dynamic>> getDeliveries() => [];
  @override
  Future<void> saveDelivery(Map<String, dynamic> delivery) async {}

  @override
  List<Map<String, dynamic>> getRiders() => [];
}

void main() {
  late RiderNotifier riderNotifier;
  late MockRiderRepository mockRepository;

  setUp(() {
    mockRepository = MockRiderRepository();
    riderNotifier = RiderNotifier(
      repository: mockRepository,
      firestoreService: FirestoreService(MockDatabaseService()),
    );
  });

  group('RiderNotifier Tests', () {
    test('toggleOnlineStatus toggles state', () async {
      expect(riderNotifier.state.isOnline, true);
      await riderNotifier.toggleOnlineStatus(false);
      expect(riderNotifier.state.isOnline, false);
    });

    test('acceptJob sets activeJobId', () async {
      await riderNotifier.acceptJob('GZ-101', 3000);
      expect(riderNotifier.state.activeJobId, 'GZ-101');
    });

    test('completeCurrentJob clears active job awaiting customer confirmation',
        () async {
      await riderNotifier.acceptJob('GZ-101', 3000);
      await riderNotifier.completeCurrentJob(3000);

      expect(riderNotifier.state.activeJobId, null);
    });
  });
}
