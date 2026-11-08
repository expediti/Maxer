enum NotificationType {
  upcomingDeadline('Upcoming Deadline'),
  officialNotification('Official Notification'),
  deadlineChange('Deadline Extension / Change'),
  corrigendum('Corrigendum / Addendum'),
  examDateChange('Examination Date Announced'),
  admitCard('Admit Card Released'),
  result('Result Declared');

  final String label;
  const NotificationType(this.label);

  static NotificationType fromString(String val) {
    for (final t in NotificationType.values) {
      if (t.label.toLowerCase() == val.toLowerCase() || t.name.toLowerCase() == val.toLowerCase()) {
        return t;
      }
    }
    return NotificationType.officialNotification;
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String? examinationId;
  final DateTime timestamp;
  final bool isRead;
  final String? officialSourceUrl;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.examinationId,
    required this.timestamp,
    this.isRead = false,
    this.officialSourceUrl,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    String? examinationId,
    DateTime? timestamp,
    bool? isRead,
    String? officialSourceUrl,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      examinationId: examinationId ?? this.examinationId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      officialSourceUrl: officialSourceUrl ?? this.officialSourceUrl,
    );
  }
}

