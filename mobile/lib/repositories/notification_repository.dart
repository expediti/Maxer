import 'package:flutter/foundation.dart';
import '../core/supabase_client.dart';
import '../models/notification_item.dart';

abstract class NotificationRepository {
  Future<List<NotificationItem>> getNotifications(String candidateId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String candidateId);
  Future<int> getUnreadCount(String candidateId);
}

class SupabaseNotificationRepository implements NotificationRepository {
  final List<NotificationItem> _fallbackNotifications = [
    NotificationItem(
      id: 'notif-upsc-deadline',
      title: 'UPSC Civil Services 2026 — Application Closes in 48 Hours',
      message: 'Online application window for UPSC CSE 2026 closes on 6th March 2026 at 18:00 IST. Complete OTR and fee submission.',
      type: NotificationType.upcomingDeadline,
      examinationId: 'opp-upsc-cse-2026',
      timestamp: DateTime(2026, 3, 4, 9, 30),
      isRead: false,
      officialSourceUrl: 'https://upsc.gov.in',
    ),
    NotificationItem(
      id: 'notif-isro-corrigendum',
      title: 'ISRO ICRB — Corrigendum Issued for Scientist/Engineer Vacancies',
      message: 'Addendum issued regarding exam center additions in Chandigarh and Guwahati for ICRB 2026 recruitment.',
      type: NotificationType.corrigendum,
      examinationId: 'opp-isro-scientist-2026',
      timestamp: DateTime(2026, 2, 28, 16, 45),
      isRead: true,
      officialSourceUrl: 'https://isro.gov.in',
    ),
    NotificationItem(
      id: 'notif-pmrf-selection',
      title: 'PMRF May 2026 Cycle — Applications Now Open',
      message: 'Prime Minister’s Research Fellowship direct entry nominations are now accepted. Monthly stipend up to ₹80,000 + research grant.',
      type: NotificationType.officialNotification,
      examinationId: 'opp-pmrf-2026',
      timestamp: DateTime(2026, 2, 20, 10, 0),
      isRead: true,
      officialSourceUrl: 'https://pmrf.in',
    ),
  ];

  @override
  Future<List<NotificationItem>> getNotifications(String candidateId) async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final res = await client
            .from('notifications')
            .select()
            .eq('candidate_id', candidateId)
            .order('created_at', ascending: false);

        final items = (res as List).map((row) {
          final isRead = row['is_read'] == true || row['read_at'] != null;
          final sentAt = row['sent_at'] ?? row['created_at'];
          return NotificationItem(
            id: row['id']?.toString() ?? '',
            title: row['title'] ?? '',
            message: row['body'] ?? '',
            type: NotificationType.fromString(row['type']?.toString() ?? 'official'),
            examinationId: row['examination_id']?.toString(),
            timestamp: sentAt != null ? DateTime.tryParse(sentAt) ?? DateTime.now() : DateTime.now(),
            isRead: isRead,
            officialSourceUrl: (row['data'] as Map?)?['source_url']?.toString(),
          );
        }).toList();

        if (items.isNotEmpty) return items;
      } catch (e) {
        debugPrint('[REXAM] Fetch notifications error: $e');
      }
    }
    return _fallbackNotifications;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final idx = _fallbackNotifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _fallbackNotifications[idx] = _fallbackNotifications[idx].copyWith(isRead: true);
    }

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('notifications').update({
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', notificationId);
      } catch (e) {
        debugPrint('[REXAM] Mark notification as read error: $e');
      }
    }
  }

  @override
  Future<void> markAllAsRead(String candidateId) async {
    for (int i = 0; i < _fallbackNotifications.length; i++) {
      _fallbackNotifications[i] = _fallbackNotifications[i].copyWith(isRead: true);
    }

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('notifications').update({
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('candidate_id', candidateId).eq('is_read', false);
      } catch (e) {
        debugPrint('[REXAM] Mark all read error: $e');
      }
    }
  }

  @override
  Future<int> getUnreadCount(String candidateId) async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final res = await client
            .from('notifications')
            .select('id')
            .eq('candidate_id', candidateId)
            .eq('is_read', false);
        return (res as List).length;
      } catch (e) {
        debugPrint('[REXAM] Get unread count error: $e');
      }
    }
    return _fallbackNotifications.where((n) => !n.isRead).length;
  }
}

