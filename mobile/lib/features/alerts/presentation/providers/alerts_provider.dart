import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/alert_item.dart';

class AlertsNotifier extends StateNotifier<List<AlertItem>> {
  AlertsNotifier()
      : super([
          AlertItem(
            id: 'alert-1',
            title: 'Deadline Approaching: UPSC CSE 2026',
            message:
                'Online registration for Civil Services Examination (Preliminary) 2026 closes on 6th March 2026 at 18:00 IST. Ensure application fee is settled.',
            type: AlertType.upcomingDeadline,
            opportunityId: 'opp-upsc-cse-2026',
            timestamp: DateTime(2026, 3, 4, 9, 30),
            isRead: false,
            officialSourceUrl: 'https://upsc.gov.in',
          ),
          AlertItem(
            id: 'alert-2',
            title: 'New Official Notification: DRDO Scientist "B"',
            message:
                'DRDO RAC has officially released Advt 148 for 204 Scientist "B" posts through valid GATE score. Online portal active.',
            type: AlertType.officialNotification,
            opportunityId: 'opp-drdo-scientist-b-2026',
            timestamp: DateTime(2026, 3, 2, 14, 15),
            isRead: false,
            officialSourceUrl: 'https://rac.gov.in',
          ),
          AlertItem(
            id: 'alert-3',
            title: 'Corrigendum: ISRO ICRB 01/2026',
            message:
                'VSSC has issued an addendum clarifying the CGPA-to-percentage conversion norm for autonomous engineering institutions.',
            type: AlertType.corrigendum,
            opportunityId: 'opp-isro-scientist-2026',
            timestamp: DateTime(2026, 3, 1, 11, 0),
            isRead: true,
            officialSourceUrl: 'https://isro.gov.in',
          ),
          AlertItem(
            id: 'alert-4',
            title: 'Admit Card Expected: SBI PO Prelims',
            message:
                'Preliminary online examination call letters for SBI PO are scheduled for release in the 2nd week of April 2026.',
            type: AlertType.admitCard,
            opportunityId: 'opp-sbi-po-2026',
            timestamp: DateTime(2026, 2, 28, 16, 45),
            isRead: true,
            officialSourceUrl: 'https://sbi.co.in/careers',
          ),
        ]);

  int get unreadCount => state.where((item) => !item.isRead).length;

  void markAsRead(String alertId) {
    state = state.map((item) {
      if (item.id == alertId) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
  }

  void markAllAsRead() {
    state = state.map((item) => item.copyWith(isRead: true)).toList();
  }

  void removeAlert(String alertId) {
    state = state.where((item) => item.id != alertId).toList();
  }
}

final alertsProvider = StateNotifierProvider<AlertsNotifier, List<AlertItem>>((ref) {
  return AlertsNotifier();
});

final unreadAlertsCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(alertsProvider);
  return alerts.where((a) => !a.isRead).length;
});
