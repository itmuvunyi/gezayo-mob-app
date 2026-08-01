import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gezayo_app/core/services/database_service.dart';
import 'package:gezayo_app/core/services/backend_api_service.dart';
import 'package:gezayo_app/core/services/firestore_service.dart';
import 'package:gezayo_app/features/customer/data/delivery_repository.dart';
import 'package:gezayo_app/features/customer/domain/delivery_model.dart';
import 'package:gezayo_app/features/customer/domain/rider_model.dart';
import 'package:gezayo_app/features/customer/presentation/delivery_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DeliveryRepository repo;
  late FirestoreService firestore;
  late DeliveryNotifier deliveryNotifier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = DatabaseService(prefs);
    final api = BackendApiService(db);
    firestore = FirestoreService(db);
    repo = DeliveryRepositoryImpl(api, firestore);
    deliveryNotifier = DeliveryNotifier(repo, firestore);
  });

  group('DeliveryNotifier Tests', () {
    test('createDeliveryRequest sets active delivery correctly', () async {
      await deliveryNotifier.createDeliveryRequest(
        pickupAddress: 'Kigali Heights',
        dropoffAddress: 'Kimihurura',
        packageType: 'Food',
        weightClass: 'Light (<5kg)',
        instructions: 'Handle with care',
        estimatedFare: 2500,
      );

      expect(deliveryNotifier.state.activeDelivery, isNotNull);
      expect(deliveryNotifier.state.activeDelivery?.pickupAddress,
          'Kigali Heights');
      expect(deliveryNotifier.state.activeDelivery?.estimatedFareRwf, 2500);
    });

    test('selectRider assigns rider to active delivery', () async {
      await deliveryNotifier.createDeliveryRequest(
        pickupAddress: 'Kigali Heights',
        dropoffAddress: 'Kimihurura',
        packageType: 'Food',
        weightClass: 'Light (<5kg)',
        instructions: '',
        estimatedFare: 2500,
      );

      const dummyRider = RiderModel(
        id: 'r1',
        name: 'Jean-Paul',
        rating: 4.9,
        completedJobs: 150,
        vehicleType: 'EV Motor',
        etaText: '4 mins',
      );

      await deliveryNotifier.selectRider(dummyRider);
      expect(deliveryNotifier.state.activeDelivery?.assignedRiderName,
          'Jean-Paul');
      expect(deliveryNotifier.state.activeDelivery?.status,
          DeliveryStatus.assigned);
    });
  });
}
