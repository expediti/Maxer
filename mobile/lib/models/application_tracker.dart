import 'examination.dart';

enum ApplicationStatus {
  interested('Interested'),
  preparingDocuments('Preparing Documents'),
  readyToApply('Ready to Apply'),
  applied('Applied'),
  admitCardReleased('Admit Card Released'),
  examCompleted('Examination Completed'),
  resultDeclared('Result Declared'),
  selected('Selected'),
  rejected('Rejected'),
  withdrawn('Withdrawn');

  final String label;
  String get displayName => label;
  const ApplicationStatus(this.label);

  static ApplicationStatus fromString(String val) {
    final clean = val.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    for (final s in ApplicationStatus.values) {
      final sCleanLabel = s.label.toLowerCase().replaceAll(' ', '');
      final sCleanName = s.name.toLowerCase();
      if (sCleanLabel == clean || sCleanName == clean) {
        return s;
      }
    }
    return ApplicationStatus.interested;
  }
}

class ApplicationTrackerItem {
  final String id;
  final String examinationId;
  final Examination examination;
  final ApplicationStatus status;
  final String? applicationNumber;
  final DateTime appliedDate;
  final DateTime? examDate;
  final String? personalNotes;
  final List<String> completedChecklist;
  final DateTime lastUpdated;

  const ApplicationTrackerItem({
    required this.id,
    required this.examinationId,
    required this.examination,
    required this.status,
    this.applicationNumber,
    required this.appliedDate,
    this.examDate,
    this.personalNotes,
    this.completedChecklist = const [],
    required this.lastUpdated,
  });

  ApplicationTrackerItem copyWith({
    String? id,
    String? examinationId,
    Examination? examination,
    ApplicationStatus? status,
    String? applicationNumber,
    DateTime? appliedDate,
    DateTime? examDate,
    String? personalNotes,
    List<String>? completedChecklist,
    DateTime? lastUpdated,
  }) {
    return ApplicationTrackerItem(
      id: id ?? this.id,
      examinationId: examinationId ?? this.examinationId,
      examination: examination ?? this.examination,
      status: status ?? this.status,
      applicationNumber: applicationNumber ?? this.applicationNumber,
      appliedDate: appliedDate ?? this.appliedDate,
      examDate: examDate ?? this.examDate,
      personalNotes: personalNotes ?? this.personalNotes,
      completedChecklist: completedChecklist ?? this.completedChecklist,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

