import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import '../models/admin_models.dart';
import 'package:flutter/foundation.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// РџСЂРѕРІРµСЂРєР° РїСЂР°РІ Р°РґРјРёРЅРёСЃС‚СЂР°С‚РѕСЂР°
  Future<bool> isUserAdmin(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return data['isAdmin'] == true || data['role'] == 'admin' || data['role'] == 'superAdmin';
      }
      return false;
    } catch (e) {
      debugPrint('ERROR: [AdminService] Failed to check admin status: $e');
      return false;
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ СЂРѕР»Рё РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<UserRole> getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final roleString = data['role'] ?? 'user';
        return UserRole.values.byName(roleString);
      }
      return UserRole.user;
    } catch (e) {
      debugPrint('ERROR: [AdminService] Failed to get user role: $e');
      return UserRole.user;
    }
  }

  /// Р›РѕРіРёСЂРѕРІР°РЅРёРµ РґРµР№СЃС‚РІРёСЏ Р°РґРјРёРЅРёСЃС‚СЂР°С‚РѕСЂР°
  Future<void> logAdminAction({
    required String adminId,
    required String adminEmail,
    required AdminAction action,
    required String target,
    String? targetId,
    String? description,
    AdminActionStatus status = AdminActionStatus.completed,
    Map<String, dynamic>? metadata,
    String? errorMessage,
  }) async {
    try {
      final log = AdminLog(
        id: _uuid.v4(),
        adminId: adminId,
        adminEmail: adminEmail,
        action: action,
        target: target,
        targetId: targetId,
        description: description,
        status: status,
        timestamp: DateTime.now(),
        metadata: metadata,
        errorMessage: errorMessage,
      );

      await _firestore.collection('admin_logs').doc(log.id).set(log.toMap());
      debugPrint('INFO: [AdminService] Admin action logged: ${action.name} on $target');
    } catch (e) {
      debugPrint('ERROR: [AdminService] Failed to log admin action: $e');
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ Р»РѕРіРѕРІ Р°РґРјРёРЅРёСЃС‚СЂР°С‚РѕСЂР°
  Stream<List<AdminLog>> getAdminLogsStream({
    String? adminId,
    AdminAction? action,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) {
    Query query = _firestore.collection('admin_logs');

    if (adminId != null) {
      query = query.where('adminId', isEqualTo: adminId);
    }
    if (action != null) {
      query = query.where('action', isEqualTo: action.name);
    }
    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.orderBy('timestamp', descending: true).limit(limit).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => AdminLog.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ СЃС‚Р°С‚РёСЃС‚РёРєРё РґРµР№СЃС‚РІРёР№ Р°РґРјРёРЅРёСЃС‚СЂР°С‚РѕСЂР°
  Future<Map<String, dynamic>> getAdminStats(String adminId,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore.collection('admin_logs').where('adminId', isEqualTo: adminId);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final logs =
          snapshot.docs.map((doc) => AdminLog.fromMap(doc.data() as Map<String, dynamic>)).toList();

      final stats = <String, dynamic>{
        'totalActions': logs.length,
        'completedActions': logs.where((log) => log.status == AdminActionStatus.completed).length,
        'failedActions': logs.where((log) => log.status == AdminActionStatus.failed).length,
        'actionsByType': <String, int>{},
        'actionsByTarget': <String, int>{},
      };

      for (final log in logs) {
        // РџРѕРґСЃС‡РµС‚ РїРѕ С‚РёРїР°Рј РґРµР№СЃС‚РІРёР№
        final actionType = log.action.name;
        stats['actionsByType'][actionType] = (stats['actionsByType'][actionType] ?? 0) + 1;

        // РџРѕРґСЃС‡РµС‚ РїРѕ С†РµР»СЏРј
        final target = log.target;
        stats['actionsByTarget'][target] = (stats['actionsByTarget'][target] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('ERROR: [AdminService] Failed to get admin stats: $e');
      return {};
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ СЃРїРёСЃРєР° РІСЃРµС… Р°РґРјРёРЅРёСЃС‚СЂР°С‚РѕСЂРѕРІ
  Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final snapshot = await _firestore.collection('users').where('isAdmin', isEqualTo: true).get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('ERROR: [AdminService] Failed to get all admins: $e');
      return [];
    }
  }

  /// РќР°Р·РЅР°С‡РµРЅРёРµ РїСЂР°РІ Р°РґРјРёРЅРёСЃС‚СЂР°С‚РѕСЂР°
  Future<bool> grantAdminRights(String userId, String adminId, String adminEmail) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': true,
        'role': 'admin',
        'updatedAt': DateTime.now(),
      });

      await logAdminAction(
        adminId: adminId,
        adminEmail: adminEmail,
        action: AdminAction.update,
        target: 'user',
        targetId: userId,
        description: 'Granted admin rights to user $userId',
        metadata: {'grantedBy': adminId},
      );

      debugPrint('INFO: [AdminService] Admin rights granted to user $userId');
      return true;
    } catch (e) {
      debugPrint('ERROR: [AdminService] Failed to grant admin rights: $e');
      await logAdminAction(
        adminId: adminId,
        adminEmail: adminEmail,
        action: AdminAction.update,
        target: 'user',
        targetId: userId,
        description: 'Failed to grant admin rights to user $userId',
        status: AdminActionStatus.failed,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// РћС‚Р·С‹РІ РїСЂР°РІ Р°РґРјРёРЅРёСЃС‚СЂР°С‚РѕСЂР°
  Future<bool> revokeAdminRights(String userId, String adminId, String adminEmail) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': false,
        'role': 'user',
        'updatedAt': DateTime.now(),
      });

      await logAdminAction(
        adminId: adminId,
        adminEmail: adminEmail,
        action: AdminAction.update,
        target: 'user',
        targetId: userId,
        description: 'Revoked admin rights from user $userId',
        metadata: {'revokedBy': adminId},
      );

      debugPrint('INFO: [AdminService] Admin rights revoked from user $userId');
      return true;
    } catch (e) {
      debugPrint('ERROR: [AdminService] Failed to revoke admin rights: $e');
      await logAdminAction(
        adminId: adminId,
        adminEmail: adminEmail,
        action: AdminAction.update,
        target: 'user',
        targetId: userId,
        description: 'Failed to revoke admin rights from user $userId',
        status: AdminActionStatus.failed,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ СЃРёСЃС‚РµРјРЅРѕР№ СЃС‚Р°С‚РёСЃС‚РёРєРё
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final stats = <String, dynamic>{};

      // РћР±С‰РµРµ РєРѕР»РёС‡РµСЃС‚РІРѕ РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№
      final usersSnapshot = await _firestore.collection('users').get();
      stats['totalUsers'] = usersSnapshot.docs.length;

      // РђРєС‚РёРІРЅС‹Рµ РїРѕР»СЊР·РѕРІР°С‚РµР»Рё (Р·Р° РїРѕСЃР»РµРґРЅРёРµ 30 РґРЅРµР№)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final activeUsersSnapshot = await _firestore
          .collection('users')
          .where('lastActiveAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();
      stats['activeUsers'] = activeUsersSnapshot.docs.length;

      // РћР±С‰РµРµ РєРѕР»РёС‡РµСЃС‚РІРѕ С‚СЂР°РЅР·Р°РєС†РёР№
      final transactionsSnapshot = await _firestore.collection('transactions').get();
      stats['totalTransactions'] = transactionsSnapshot.docs.length;

      // РћР±С‰Р°СЏ РІС‹СЂСѓС‡РєР°
      double totalRevenue = 0.0;
      for (final doc in transactionsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'completed') {
          totalRevenue += (data['amount'] ?? 0.0).toDouble();
        }
      }
      stats['totalRevenue'] = totalRevenue;

      // РљРѕР»РёС‡РµСЃС‚РІРѕ РїРѕРґРїРёСЃРѕРє
      final subscriptionsSnapshot = await _firestore.collection('user_subscriptions').get();
      stats['totalSubscriptions'] = subscriptionsSnapshot.docs.length;

      // РљРѕР»РёС‡РµСЃС‚РІРѕ Р°РєС‚РёРІРЅС‹С… РїРѕРґРїРёСЃРѕРє
      final activeSubscriptionsSnapshot = await _firestore
          .collection('user_subscriptions')
          .where('status', isEqualTo: 'active')
          .get();
      stats['activeSubscriptions'] = activeSubscriptionsSnapshot.docs.length;

      return stats;
    } catch (e) {
      debugPrint('ERROR: [AdminService] Failed to get system stats: $e');
      return {};
    }
  }

  /// Р­РєСЃРїРѕСЂС‚ РґР°РЅРЅС‹С… РІ CSV
  Future<String> exportDataToCSV({
    required String collection,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.where(entry.key, isEqualTo: entry.value);
        }
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;

      if (docs.isEmpty) {
        return '';
      }

      // РЎРѕР·РґР°РЅРёРµ CSV Р·Р°РіРѕР»РѕРІРєРѕРІ
      final headers = (docs.first.data() as Map<String, dynamic>).keys.toList();
      final csv = StringBuffer();
      csv.writeln(headers.join(','));

      // Р”РѕР±Р°РІР»РµРЅРёРµ РґР°РЅРЅС‹С…
      for (final doc in docs) {
        final data = doc.data();
        final row = headers
            .map((header) => (data as Map<String, dynamic>)[header]?.toString() ?? '')
            .join(',');
        csv.writeln(row);
      }

      return csv.toString();
    } catch (e) {
      debugPrint('ERROR: [AdminService] Failed to export data to CSV: $e');
      return '';
    }
  }
}

