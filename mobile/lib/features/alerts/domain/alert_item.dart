enum AlertType {
  matchingOpportunity('New Matching Opportunity'),
  upcomingDeadline('Upcoming Deadline'),
  officialNotification('Official Notification'),
  deadlineChange('Deadline Extension / Change'),
  corrigendum('Corrigendum / Addendum'),
  examDateChange('Examination Date Announced'),
  admitCard('Admit Card Released'),
  result('Result Declared');

  final String label;
  const AlertType(this.label);
}

class AlertItem {
  final String id;
  final String title;
  final String message;
  final AlertType type;
  final String? opportunityId;
  final DateTime timestamp;
  final bool isRead;
  final String? officialSourceUrl;

  const AlertItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.opportunityId,
    required this.timestamp,
    this.isRead = false,
    this.officialSourceUrl,
  });

  AlertItem copyWith({
    String? id,
    String? title,
    String? message,
    AlertType? type,
    String? opportunityId,
    DateTime? timestamp,
    bool? isRead,
    String? officialSourceUrl,
  }) {
    return AlertItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      opportunityId: opportunityId ?? this.opportunityId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      officialSourceUrl: officialSourceUrl ?? this.officialSourceUrl,
    );
  }
}

