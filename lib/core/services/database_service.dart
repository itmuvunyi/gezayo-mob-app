import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return DatabaseService(storage.prefs);
});

class DatabaseService {
  final SharedPreferences _prefs;

  DatabaseService(this._prefs);

  static const String _keyUsers = 'gezayo_db_users';
  static const String _keyDeliveries = 'gezayo_db_deliveries';
  static const String _keyTransactions = 'gezayo_db_transactions';
  static const String _keyNotifications = 'gezayo_db_notifications';

  // Generic DB Operations
  List<Map<String, dynamic>> getCollection(String key) {
    final rawJson = _prefs.getString(key);
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final List decoded = json.decode(rawJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCollection(
      String key, List<Map<String, dynamic>> items) async {
    await _prefs.setString(key, json.encode(items));
  }

  // Specific Entity APIs
  List<Map<String, dynamic>> getUsers() => getCollection(_keyUsers);

  Future<void> saveUser(Map<String, dynamic> userMap) async {
    final users = getUsers();
    final index = users.indexWhere((u) => u['uid'] == userMap['uid']);
    if (index >= 0) {
      users[index] = userMap;
    } else {
      users.add(userMap);
    }
    await saveCollection(_keyUsers, users);
  }

  List<Map<String, dynamic>> getDeliveries() => getCollection(_keyDeliveries);

  Future<void> saveDelivery(Map<String, dynamic> deliveryMap) async {
    final deliveries = getDeliveries();
    final index = deliveries.indexWhere((d) => d['id'] == deliveryMap['id']);
    if (index >= 0) {
      deliveries[index] = deliveryMap;
    } else {
      deliveries.add(deliveryMap);
    }
    await saveCollection(_keyDeliveries, deliveries);
  }

  List<Map<String, dynamic>> getRiders() =>
      getUsers().where((u) => u['role'] == 'rider').toList();

  List<Map<String, dynamic>> getTransactions() =>
      getCollection(_keyTransactions);

  Future<void> addTransaction(Map<String, dynamic> txMap) async {
    final txs = getTransactions();
    txs.insert(0, txMap);
    await saveCollection(_keyTransactions, txs);
  }

  List<Map<String, dynamic>> getNotifications() =>
      getCollection(_keyNotifications);

  Future<void> clearAllData() async {
    await _prefs.remove(_keyUsers);
    await _prefs.remove(_keyDeliveries);
    await _prefs.remove(_keyTransactions);
    await _prefs.remove(_keyNotifications);
  }
}

