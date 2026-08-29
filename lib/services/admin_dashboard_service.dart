import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/resource_item.dart';
import '../models/user_model.dart';

class AdminDashboardMetrics {
  const AdminDashboardMetrics({
    required this.totalUsers,
    required this.usersByRole,
    required this.pendingApprovals,
    required this.ictAssets,
    required this.maintenanceItems,
    required this.activeBorrowings,
  });

  final int totalUsers;
  final Map<String, int> usersByRole;
  final int pendingApprovals;
  final int ictAssets;
  final int maintenanceItems;
  final int activeBorrowings;
}

class AdminPendingUser {
  const AdminPendingUser({required this.user, required this.documentId});

  final UserModel user;
  final String documentId;
}

class AdminAuditEvent {
  const AdminAuditEvent({
    required this.actorName,
    required this.description,
    required this.timestamp,
    required this.icon,
  });

  final String actorName;
  final String description;
  final DateTime? timestamp;
  final String icon;
}

class AdminDashboardService {
  AdminDashboardService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const usersCollection = 'users';
  static const resourcesCollection = 'resources';
  static const transactionsCollection = 'borrow_transactions';
  static const auditLogsCollection = 'audit_logs';

  Stream<AdminDashboardMetrics> watchMetrics() {
    late StreamController<AdminDashboardMetrics> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? usersSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? resourcesSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? transactionsSub;
    QuerySnapshot<Map<String, dynamic>>? usersSnapshot;
    QuerySnapshot<Map<String, dynamic>>? resourcesSnapshot;
    QuerySnapshot<Map<String, dynamic>>? transactionsSnapshot;

    void emitMetrics() {
      if (usersSnapshot == null ||
          resourcesSnapshot == null ||
          transactionsSnapshot == null) {
        return;
      }
      final users = usersSnapshot!.docs;
      final roleCounts = <String, int>{
        'student': 0,
        'teacher': 0,
        'custodian': 0,
        'admin': 0,
      };
      var pendingApprovals = 0;
      for (final document in users) {
        final data = document.data();
        final role = _normalizedRole(data['role']);
        if (roleCounts.containsKey(role)) {
          roleCounts[role] = roleCounts[role]! + 1;
        }
        if (data['isApproved'] == false ||
            data['status']?.toString().toLowerCase() == 'pending_approval') {
          pendingApprovals++;
        }
      }
      final resources = resourcesSnapshot!.docs.map(
        (document) => ResourceItem.fromMap(document.id, document.data()),
      );
      final ictAssets = resources.where(_isIctAsset).length;
      final maintenanceItems = resources.where(_needsMaintenance).length;
      final activeBorrowings = transactionsSnapshot!.docs
          .where(
            (document) =>
                document.data()['status']?.toString().toLowerCase() ==
                'borrowed',
          )
          .length;
      controller.add(
        AdminDashboardMetrics(
          totalUsers: users.length,
          usersByRole: roleCounts,
          pendingApprovals: pendingApprovals,
          ictAssets: ictAssets,
          maintenanceItems: maintenanceItems,
          activeBorrowings: activeBorrowings,
        ),
      );
    }

    controller = StreamController<AdminDashboardMetrics>(
      onListen: () {
        usersSub = _firestore.collection(usersCollection).snapshots().listen((
          snapshot,
        ) {
          usersSnapshot = snapshot;
          emitMetrics();
        });
        resourcesSub = _firestore
            .collection(resourcesCollection)
            .snapshots()
            .listen((snapshot) {
              resourcesSnapshot = snapshot;
              emitMetrics();
            });
        transactionsSub = _firestore
            .collection(transactionsCollection)
            .snapshots()
            .listen((snapshot) {
              transactionsSnapshot = snapshot;
              emitMetrics();
            });
      },
      onCancel: () async {
        await usersSub?.cancel();
        await resourcesSub?.cancel();
        await transactionsSub?.cancel();
      },
    );
    return controller.stream;
  }

  Stream<List<AdminPendingUser>> watchPendingUsers({int limit = 5}) {
    return _firestore.collection(usersCollection).snapshots().map((snapshot) {
      final pending =
          snapshot.docs.where((document) {
            final data = document.data();
            return data['isApproved'] == false ||
                data['status']?.toString().toLowerCase() == 'pending_approval';
          }).toList()..sort(
            (a, b) => _dateFrom(
              b.data()['createdAt'],
            ).compareTo(_dateFrom(a.data()['createdAt'])),
          );
      return pending
          .take(limit)
          .map(
            (document) => AdminPendingUser(
              user: UserModel.fromMap(document.data(), id: document.id),
              documentId: document.id,
            ),
          )
          .toList();
    });
  }

  Stream<List<AdminAuditEvent>> watchAuditEvents({int limit = 5}) {
    return _firestore
        .collection(auditLogsCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((document) {
            final data = document.data();
            return AdminAuditEvent(
              actorName: (data['actorName'] ?? data['userName'] ?? 'System')
                  .toString(),
              description:
                  (data['description'] ?? data['action'] ?? 'Activity recorded')
                      .toString(),
              timestamp: _dateFromNullable(
                data['timestamp'] ?? data['createdAt'],
              ),
              icon: (data['icon'] ?? data['actionType'] ?? 'activity')
                  .toString(),
            );
          }).toList(),
        );
  }

  Future<void> approveUser(String documentId) {
    return _firestore.collection(usersCollection).doc(documentId).update({
      'isApproved': true,
      'status': 'Active',
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectUser(String documentId, String reason) {
    return _firestore.collection(usersCollection).doc(documentId).update({
      'isApproved': false,
      'status': 'rejected',
      'rejectionReason': reason.trim(),
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  static String _normalizedRole(Object? value) {
    final role = value?.toString().trim().toLowerCase() ?? '';
    if (role.contains('student')) return 'student';
    if (role.contains('teacher')) return 'teacher';
    if (role.contains('custodian')) return 'custodian';
    if (role == 'admin' || role.contains('ict coordinator')) return 'admin';
    return role;
  }

  static bool _isIctAsset(ResourceItem resource) {
    final category = resource.mainCategory.toLowerCase();
    final type = '${resource.itemType} ${resource.itemName}'.toLowerCase();
    return category == 'ict' ||
        category == 'ict equipment' ||
        type.contains('laptop') ||
        type.contains('tablet') ||
        type.contains('projector') ||
        type.contains('network');
  }

  static bool _needsMaintenance(ResourceItem resource) {
    final status = resource.inventoryStatus.toLowerCase();
    final condition = resource.condition.toLowerCase();
    return status == 'damaged' ||
        status == 'under_repair' ||
        status == 'for_replacement' ||
        condition == 'damaged' ||
        condition == 'under_repair' ||
        condition == 'for_replacement' ||
        resource.damagedQuantity > 0;
  }

  static DateTime _dateFrom(Object? value) =>
      _dateFromNullable(value) ?? DateTime.fromMillisecondsSinceEpoch(0);

  static DateTime? _dateFromNullable(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }
}
