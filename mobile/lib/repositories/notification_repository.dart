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
  @override
  Future<List<NotificationItem>> getNotifications(String candidateId) async {
    final client = SupabaseConfig.client;
    if (client == null || candidateId.trim().isEmpty) {
      return [];
    }

    try {
      final res = await client
          .from('notifications')
          .select('*')
          .eq('candidate_id', candidateId)
          .order('sent_at', ascending: false);

      return (res as List).map<NotificationItem>((item) {
        final typeStr = (item['notification_type'] ?? item['type'] ?? 'official').toString().toLowerCase();
        NotificationType mappedType = NotificationType.officialNotification;
        if (typeStr.contains('deadline')) {
          mappedType = NotificationType.upcomingDeadline;
        } else if (typeStr.contains('corrigendum')) {
          mappedType = NotificationType.corrigendum;
        } else if (typeStr.contains('admit')) {
          mappedType = NotificationType.admitCard;
        } else if (typeStr.contains('result')) {
          mappedType = NotificationType.result;
        }

        return NotificationItem(
          id: item['id']?.toString() ?? '',
          title: item['title']?.toString() ?? '',
          message: item['body'] ?? item['message'] ?? '',
          type: mappedType,
          examinationId: item['examination_id']?.toString() ?? '',
          timestamp: item['sent_at'] != null
              ? DateTime.tryParse(item['sent_at']) ?? DateTime.now()
              : DateTime.now(),
          isRead: item['is_read'] == true,
          officialSourceUrl: item['official_source_url'],
        );
      }).toList();
    } catch (e) {
      debugPrint('[REXAM] Fetch notifications Supabase error: $e');
      return [];
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      await client.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', notificationId);
    } catch (e) {
      debugPrint('[REXAM] Mark notification as read error: $e');
    }
  }

  @override
  Future<void> markAllAsRead(String candidateId) async {
    final client = SupabaseConfig.client;
    if (client == null || candidateId.trim().isEmpty) return;

    try {
      await client.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('candidate_id', candidateId);
    } catch (e) {
      debugPrint('[REXAM] Mark all notifications read error: $e');
    }
  }

  @override
  Future<int> getUnreadCount(String candidateId) async {
    final client = SupabaseConfig.client;
    if (client == null || candidateId.trim().isEmpty) return 0;

    try {
      final res = await client
          .from('notifications')
          .select('id')
          .eq('candidate_id', candidateId)
          .eq('is_read', false);

      return (res as List).length;
    } catch (e) {
      debugPrint('[REXAM] Get unread count error: $e');
      return 0;
    }
  }
}
