import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/alert_item.dart';
import 'package:rexam/core/providers/repository_providers.dart';
import 'package:rexam/repositories/notification_repository.dart';
import 'package:rexam/features/auth/presentation/providers/auth_provider.dart';

class AlertsNotifier extends StateNotifier<List<AlertItem>> {
  final NotificationRepository notifRepo;
  final String candidateId;

  AlertsNotifier({
    required this.notifRepo,
    required this.candidateId,
  }) : super([]) {
    loadAlerts();
  }

  Future<void> loadAlerts() async {
    try {
      final items = await notifRepo.getNotifications(candidateId);
      final mapped = items.map((n) {
        AlertType mappedType = AlertType.officialNotification;
        final typeName = n.type.name.toLowerCase();
        if (typeName.contains('deadline')) {
          mappedType = AlertType.upcomingDeadline;
        } else if (typeName.contains('corrigendum')) {
          mappedType = AlertType.corrigendum;
        } else if (typeName.contains('admit')) {
          mappedType = AlertType.admitCard;
        } else if (typeName.contains('result')) {
          mappedType = AlertType.result;
        }

        return AlertItem(
          id: n.id,
          title: n.title,
          message: n.message,
          type: mappedType,
          opportunityId: n.examinationId,
          timestamp: n.timestamp,
          isRead: n.isRead,
          officialSourceUrl: n.officialSourceUrl,
        );
      }).toList();

      state = mapped;
    } catch (_) {}
  }

  int get unreadCount => state.where((item) => !item.isRead).length;

  Future<void> markAsRead(String alertId) async {
    state = state.map((item) {
      if (item.id == alertId) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();

    await notifRepo.markAsRead(alertId);
  }

  Future<void> markAllAsRead() async {
    state = state.map((item) => item.copyWith(isRead: true)).toList();
    await notifRepo.markAllAsRead(candidateId);
  }

  void removeAlert(String alertId) {
    state = state.where((item) => item.id != alertId).toList();
  }
}

final alertsProvider = StateNotifierProvider<AlertsNotifier, List<AlertItem>>((ref) {
  final notifRepo = ref.watch(notificationRepositoryProvider);
  final authState = ref.watch(authProvider);
  final candidateId = authState.user?.id ?? 'candidate-rexam-001';

  return AlertsNotifier(
    notifRepo: notifRepo,
    candidateId: candidateId,
  );
});

final unreadAlertsCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(alertsProvider);
  return alerts.where((a) => !a.isRead).length;
});
