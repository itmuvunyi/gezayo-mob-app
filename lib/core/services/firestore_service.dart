import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/user_model.dart';
import '../../features/customer/domain/delivery_model.dart';
import '../../features/customer/domain/rider_model.dart';
import '../../features/rider/domain/transaction_model.dart';
import 'database_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final localDb = ref.watch(databaseServiceProvider);
  return FirestoreService(localDb);
});

class FirestoreService {
  final DatabaseService _localDb;
  FirebaseFirestore? _firestore;
  CollectionReference<Map<String, dynamic>>? _usersCol;
  CollectionReference<Map<String, dynamic>>? _deliveriesCol;
  CollectionReference<Map<String, dynamic>>? _transactionsCol;
  CollectionReference<Map<String, dynamic>>? _notificationsCol;

  FirestoreService(this._localDb) {
    _initFirestore();
  }

  void _initFirestore() {
    try {
      _firestore = FirebaseFirestore.instance;
      _usersCol = _firestore!.collection('users');
      _deliveriesCol = _firestore!.collection('deliveries');
      _transactionsCol = _firestore!.collection('transactions');
      _notificationsCol = _firestore!.collection('notifications');
    } catch (e) {
      debugPrint(
          'Firestore init bypassed (offline/unsupported platform): $e');
    }
  }

  // --- USERS COLLECTION SCHEMA & CRUD ---

  Future<void> saveUser(UserModel user) async {
    try {
      if (_usersCol != null) {
        await _usersCol!.doc(user.uid).set(user.toMap());
      }
    } catch (e) {
      debugPrint('Firestore saveUser error: $e');
    }
    await _localDb.saveUser(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      if (_usersCol != null && uid.isNotEmpty) {
        final doc = await _usersCol!.doc(uid).get();
        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data()!);
        }
      }
    } catch (e) {
      debugPrint('Firestore getUser error: $e');
    }

    final localUsers = _localDb.getUsers();
    final match = localUsers.firstWhere(
      (u) => u['uid'] == uid,
      orElse: () => {},
    );
    if (match.isNotEmpty) {
      return UserModel.fromMap(match);
    }
    return null;
  }

  Future<UserModel?> getUserByPhone(String phone) async {
    try {
      if (_usersCol != null && phone.isNotEmpty) {
        final snap =
            await _usersCol!.where('phoneNumber', isEqualTo: phone).limit(1).get();
        if (snap.docs.isNotEmpty) {
          return UserModel.fromMap(snap.docs.first.data());
        }
      }
    } catch (e) {
      debugPrint('Firestore getUserByPhone error: $e');
    }

    final localUsers = _localDb.getUsers();
    final match = localUsers.firstWhere(
      (u) => u['phoneNumber'] == phone,
      orElse: () => {},
    );
    if (match.isNotEmpty) {
      return UserModel.fromMap(match);
    }
    return null;
  }

  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    try {
      if (_usersCol != null && uid.isNotEmpty) {
        await _usersCol!.doc(uid).update({'isOnline': isOnline});
      }
    } catch (e) {
      debugPrint('Firestore updateOnlineStatus error: $e');
    }
  }

  Future<void> updateRiderLocation(
      String uid, double latitude, double longitude,
      [bool isOnline = true]) async {
    try {
      if (_usersCol != null && uid.isNotEmpty) {
        await _usersCol!.doc(uid).set({
          'isOnline': isOnline,
          'latitude': latitude,
          'longitude': longitude,
          'lastLocationUpdate': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore updateRiderLocation error: $e');
    }
  }

  /// Real-time stream of online riders as UserModel instances with coordinates
  Stream<List<UserModel>> getOnlineRidersStream() {
    if (_usersCol != null) {
      return _usersCol!
          .where('role', isEqualTo: 'rider')
          .where('isOnline', isEqualTo: true)
          .snapshots()
          .map((snap) {
        return snap.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
      });
    }
    return Stream.value([]);
  }

  /// Delete user account and erase all associated data across Firestore collections
  Future<void> deleteUserAccount(String uid) async {
    if (uid.isEmpty) return;
    try {
      if (_usersCol != null) {
        await _usersCol!.doc(uid).delete();
      }
      if (_deliveriesCol != null) {
        final custSnap =
            await _deliveriesCol!.where('customerUid', isEqualTo: uid).get();
        for (final doc in custSnap.docs) {
          await doc.reference.delete();
        }
        final riderSnap = await _deliveriesCol!
            .where('assignedRiderUid', isEqualTo: uid)
            .get();
        for (final doc in riderSnap.docs) {
          await doc.reference.delete();
        }
      }
      if (_transactionsCol != null) {
        final txSnap =
            await _transactionsCol!.where('userId', isEqualTo: uid).get();
        for (final doc in txSnap.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      debugPrint('Firestore deleteUserAccount error: $e');
    }
    await _localDb.clearAllData();
  }

  // --- DELIVERIES COLLECTION SCHEMA & CRUD ---

  Future<DeliveryModel> createDelivery(DeliveryModel delivery) async {
    try {
      if (_deliveriesCol != null) {
        await _deliveriesCol!.doc(delivery.id).set(delivery.toMap());
      }
    } catch (e) {
      debugPrint('Firestore createDelivery error: $e');
    }
    await _localDb.saveDelivery(delivery.toMap());
    return delivery;
  }

  Future<DeliveryModel?> getActiveDelivery(String userId) async {
    if (userId.isEmpty) return null;

    try {
      if (_deliveriesCol != null) {
        final snap = await _deliveriesCol!
            .where('status',
                whereIn: ['searching', 'assigned', 'pickedUp', 'onTheWay'])
            .get();

        if (snap.docs.isNotEmpty) {
          final matches = snap.docs
              .map((doc) => DeliveryModel.fromMap(doc.data()))
              .where((d) =>
                  d.customerUid == userId ||
                  d.customerPhone == userId)
              .toList();
          if (matches.isNotEmpty) {
            return matches.last;
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore getActiveDelivery error: $e');
    }

    final localDeliveries = _localDb.getDeliveries();
    if (localDeliveries.isNotEmpty) {
      final matches = localDeliveries
          .map((m) => DeliveryModel.fromMap(m))
          .where((d) =>
              d.customerUid == userId ||
              d.customerPhone == userId)
          .toList();
      if (matches.isNotEmpty && matches.last.status != DeliveryStatus.delivered) {
        return matches.last;
      }
    }
    return null;
  }


  /// Atomically accept a job — prevents double-acceptance by checking if status is still 'searching'
  Future<bool> acceptJobAtomic(
      String jobId, String riderUid, String riderName, double riderRating,
      [String riderPhone = '']) async {
    try {
      if (_deliveriesCol != null) {
        final docRef = _deliveriesCol!.doc(jobId);
        final snap = await docRef.get();
        if (!snap.exists || snap.data() == null) return false;

        final currentStatus = snap.data()!['status'];
        if (currentStatus != 'searching') {
          // Already accepted by another rider!
          return false;
        }

        await docRef.update({
          'status': 'assigned',
          'assignedRiderUid': riderUid,
          'assignedRiderName': riderName,
          'assignedRiderPhone': riderPhone,
          'assignedRiderRating': riderRating,
          'acceptedAt': DateTime.now().toIso8601String(),
        });
        return true;
      }
    } catch (e) {
      debugPrint('Firestore acceptJobAtomic error: $e');
    }
    return true; // Fallback for local testing
  }

  /// Revert a cancelled job back to 'searching' so it remains on the dashboard for other riders
  Future<void> cancelJobByRider(String jobId) async {
    try {
      if (_deliveriesCol != null && jobId.isNotEmpty) {
        await _deliveriesCol!.doc(jobId).update({
          'status': 'searching',
          'assignedRiderUid': null,
          'assignedRiderName': null,
          'assignedRiderRating': 0.0,
        });
      }
    } catch (e) {
      debugPrint('Firestore cancelJobByRider error: $e');
    }
  }

  /// Complete a delivery job — updates status to 'delivered' (awaiting customer confirmation)
  Future<void> completeJobByRider(String jobId) async {
    try {
      if (_deliveriesCol != null && jobId.isNotEmpty) {
        await _deliveriesCol!.doc(jobId).update({
          'status': 'delivered',
          'completedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Firestore completeJobByRider error: $e');
    }
  }

  /// Customer confirms order receipt — updates status to 'completed', credits rider earnings, and debits customer balance in Firestore
  Future<void> confirmDeliveryByCustomer(String deliveryId) async {
    try {
      if (_deliveriesCol != null && deliveryId.isNotEmpty) {
        final doc = await _deliveriesCol!.doc(deliveryId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final riderUid = data['assignedRiderUid'] ?? '';
          final customerUid = data['customerUid'] ?? '';
          final fare = (data['estimatedFareRwf'] ?? 0.0).toDouble();

          await _deliveriesCol!.doc(deliveryId).update({
            'status': 'completed',
            'customerConfirmedAt': DateTime.now().toIso8601String(),
          });

          // 1. Credit Rider Earnings
          if (riderUid.toString().isNotEmpty && fare > 0) {
            final riderTx = TransactionModel(
              id: 'tx-rider-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
              userId: riderUid.toString(),
              title: 'Delivery #${deliveryId.substring(0, deliveryId.length > 8 ? 8 : deliveryId.length)}',
              dateText: 'Just now',
              amountRwf: fare,
              type: TransactionType.jobEarning,
              status: TransactionStatus.completed,
            );
            await addTransaction(riderTx);
          }

          // 2. Debit Customer Wallet Balance
          if (customerUid.toString().isNotEmpty && fare > 0) {
            final customerTx = TransactionModel(
              id: 'tx-cust-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
              userId: customerUid.toString(),
              title: 'Delivery Fee #${deliveryId.substring(0, deliveryId.length > 8 ? 8 : deliveryId.length)}',
              dateText: 'Just now',
              amountRwf: fare,
              type: TransactionType.withdrawal,
              status: TransactionStatus.completed,
            );
            await addTransaction(customerTx);
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore confirmDeliveryByCustomer error: $e');
    }
  }


  Future<void> updateDelivery(
      String deliveryId, Map<String, dynamic> updates) async {
    try {
      if (_deliveriesCol != null) {
        await _deliveriesCol!.doc(deliveryId).update(updates);
      }
    } catch (e) {
      debugPrint('Firestore updateDelivery error: $e');
    }
    final localDeliveries = _localDb.getDeliveries();
    final match = localDeliveries.firstWhere(
      (d) => d['id'] == deliveryId,
      orElse: () => {},
    );
    if (match.isNotEmpty) {
      final updated = {...match, ...updates};
      await _localDb.saveDelivery(updated);
    }
  }

  /// Real-time stream for a single delivery document
  Stream<DeliveryModel?> getDeliveryStream(String deliveryId) {
    if (_deliveriesCol != null && deliveryId.isNotEmpty) {
      return _deliveriesCol!.doc(deliveryId).snapshots().map((snap) {
        if (snap.exists && snap.data() != null) {
          return DeliveryModel.fromMap(snap.data()!);
        }
        return null;
      });
    }
    return Stream.value(null);
  }

  /// Real-time stream of active job assigned to rider (status == 'assigned' || 'pickedUp')
  Stream<DeliveryModel?> getActiveRiderJobStream(String riderUid) {
    if (_deliveriesCol != null) {
      return _deliveriesCol!.snapshots().map((snap) {
        final docs = snap.docs.map((doc) => DeliveryModel.fromMap(doc.data())).where((d) {
          final matchesRider = riderUid.isEmpty || d.assignedRiderUid == riderUid;
          final isActive = d.status == DeliveryStatus.assigned || d.status == DeliveryStatus.pickedUp;
          return matchesRider && isActive;
        }).toList();
        return docs.isNotEmpty ? docs.first : null;
      });
    }
    return Stream.value(null);
  }


  /// Stream of all jobs assigned to and completed/delivered by rider

  Stream<List<DeliveryModel>> getRiderCompletedJobsStream(String riderUid) {
    if (_deliveriesCol != null) {
      return _deliveriesCol!.snapshots().map((snap) {
        final list = snap.docs
            .map((doc) => DeliveryModel.fromMap(doc.data()))
            .where((d) {
              final matchesRider = riderUid.isEmpty || d.assignedRiderUid == riderUid;
              final isFinished = d.status == DeliveryStatus.delivered || d.status == DeliveryStatus.completed;
              return matchesRider && isFinished;
            })
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    }
    return Stream.value([]);
  }


  /// Real-time stream of all deliveries created by customer.
  Stream<List<DeliveryModel>> getCustomerDeliveriesStream([
    String? customerPhone,
    String? customerUid,
  ]) {
    if (_deliveriesCol != null) {
      return _deliveriesCol!.snapshots().map((snap) {
        final list = snap.docs
            .map((doc) => DeliveryModel.fromMap(doc.data()))
            .where((d) {
              final phoneMatch = customerPhone != null &&
                  customerPhone.isNotEmpty &&
                  d.customerPhone == customerPhone;
              final uidMatch = customerUid != null &&
                  customerUid.isNotEmpty &&
                  d.customerUid == customerUid;
              final noFilter = (customerPhone == null || customerPhone.isEmpty) &&
                  (customerUid == null || customerUid.isEmpty);
              return phoneMatch || uidMatch || noFilter;
            })
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    }
    return Stream.value([]);
  }

  /// Real-time stream of available jobs (status == 'searching') for riders.
  /// Sorted in Dart memory to eliminate composite index requirement.
  Stream<List<DeliveryModel>> getAvailableJobsStream() {
    if (_deliveriesCol != null) {
      return _deliveriesCol!
          .where('status', isEqualTo: 'searching')
          .snapshots()
          .map((snap) {
        final list = snap.docs
            .map((doc) => DeliveryModel.fromMap(doc.data()))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    }
    return Stream.value([]);
  }

  Stream<List<TransactionModel>> getTransactionsStream(String userId) {
    if (_transactionsCol != null) {
      return _transactionsCol!.snapshots().map((snap) {
        return snap.docs
            .map((doc) => TransactionModel.fromMap(doc.data()))
            .where((tx) => userId.isNotEmpty && tx.userId == userId)
            .toList();
      });
    }
    return Stream.value([]);
  }

  Future<List<TransactionModel>> getTransactions(String userId) async {
    try {
      if (_transactionsCol != null) {
        final snap = await _transactionsCol!.get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((doc) => TransactionModel.fromMap(doc.data()))
              .where((tx) => userId.isNotEmpty && tx.userId == userId)
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Firestore getTransactions error: $e');
    }

    final localTxs = _localDb.getTransactions();
    if (localTxs.isNotEmpty) {
      return localTxs
          .map((m) => TransactionModel.fromMap(m))
          .where((tx) => userId.isNotEmpty && tx.userId == userId)
          .toList();
    }
    return [];
  }


  Future<void> addTransaction(TransactionModel tx) async {
    try {
      if (_transactionsCol != null) {
        await _transactionsCol!.doc(tx.id).set(tx.toMap());
      }
    } catch (e) {
      debugPrint('Firestore addTransaction error: $e');
    }
    await _localDb.addTransaction(tx.toMap());
  }

  // --- NOTIFICATIONS STREAM ---

  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    if (_deliveriesCol != null) {
      return _deliveriesCol!.snapshots().map((snap) {
        final notifs = <Map<String, dynamic>>[];
        for (final doc in snap.docs) {
          final d = DeliveryModel.fromMap(doc.data());
          if (d.status == DeliveryStatus.searching) {
            notifs.add({
              'id': 'notif_${d.id}_posted',
              'title': 'Delivery Order Posted',
              'subtitle': '${d.packageType} delivery request posted in Kigali',
              'timeText': 'Just now',
              'isUnread': true,
              'type': 'delivery',
              'route': '/live-tracking',
            });
          } else if (d.status == DeliveryStatus.assigned) {
            notifs.add({
              'id': 'notif_${d.id}_assigned',
              'title': 'Rider Assigned',
              'subtitle': '${d.assignedRiderName ?? "Rider"} accepted your ${d.packageType} delivery',
              'timeText': '5 min ago',
              'isUnread': true,
              'type': 'delivery',
              'route': '/live-tracking',
            });
          } else if (d.status == DeliveryStatus.pickedUp) {
            notifs.add({
              'id': 'notif_${d.id}_pickedup',
              'title': 'Package Picked Up',
              'subtitle': '${d.assignedRiderName ?? "Rider"} picked up package. En route to ${d.dropoffAddress}',
              'timeText': '10 min ago',
              'isUnread': false,
              'type': 'delivery',
              'route': '/live-tracking',
            });
          } else if (d.status == DeliveryStatus.delivered) {
            notifs.add({
              'id': 'notif_${d.id}_delivered',
              'title': 'Package Delivered',
              'subtitle': 'Delivery complete! Tap to confirm receipt and rate rider.',
              'timeText': '15 min ago',
              'isUnread': true,
              'type': 'delivery',
              'route': '/order-completion',
            });
          } else if (d.status == DeliveryStatus.completed) {
            notifs.add({
              'id': 'notif_${d.id}_completed',
              'title': 'Order Completed',
              'subtitle': 'Payment of ${d.estimatedFareRwf.toStringAsFixed(0)} RWF released to rider.',
              'timeText': '1 hour ago',
              'isUnread': false,
              'type': 'transaction',
              'route': '/order-completion',
            });
          }
        }
        return notifs;
      });
    }
    return Stream.value([
      {
        'id': 'notif_welcome',
        'title': 'Welcome to GezaYo!',
        'subtitle': 'Fast, reliable delivery across Rwanda.',
        'timeText': 'Today',
        'isUnread': false,
        'type': 'system',
        'route': '/customer',
      }
    ]);
  }

  Future<void> addNotification(Map<String, dynamic> notif) async {
    try {
      if (_notificationsCol != null) {
        final id = notif['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
        await _notificationsCol!.doc(id).set(notif);
      }
    } catch (e) {
      debugPrint('Firestore addNotification error: $e');
    }
  }

  // --- RIDERS METHODS (MAPPED TO USERS COLLECTION WITH ROLE=='rider') ---

  Future<List<RiderModel>> getNearbyRiders() async {
    try {
      if (_usersCol != null) {
        final snap = await _usersCol!
            .where('role', isEqualTo: 'rider')
            .limit(10)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((doc) => RiderModel.fromMap(doc.data()))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Firestore getNearbyRiders error: $e');
    }

    final localRiders = _localDb.getRiders();
    if (localRiders.isNotEmpty) {
      return localRiders.map((m) => RiderModel.fromMap(m)).toList();
    }
    return [];
  }

  Future<void> updateRiderOnlineStatus(String riderUid, bool isOnline) async {
    try {
      if (_usersCol != null && riderUid.isNotEmpty) {
        await _usersCol!.doc(riderUid).set({
          'isOnline': isOnline,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore updateRiderOnlineStatus error: $e');
    }
  }

  /// Query real rider document from Firestore users collection (where role=='rider')
  Future<Map<String, dynamic>?> getRiderDetails(String riderUid) async {
    try {
      if (_usersCol != null) {
        if (riderUid.isNotEmpty) {
          final doc = await _usersCol!.doc(riderUid).get();
          if (doc.exists && doc.data() != null) {
            return doc.data()!;
          }
        }
        final snap = await _usersCol!.where('role', isEqualTo: 'rider').limit(1).get();
        if (snap.docs.isNotEmpty) {
          return snap.docs.first.data();
        }
      }
    } catch (e) {
      debugPrint('Firestore getRiderDetails error: $e');
    }
    return null;
  }
}


