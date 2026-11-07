import 'package:rexam/features/opportunities/domain/opportunity.dart';

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
  const ApplicationStatus(this.label);
}

class ApplicationTrackerItem {
  final String id;
  final String opportunityId;
  final Opportunity opportunity;
  final ApplicationStatus status;
  final String? applicationNumber;
  final DateTime appliedDate;
  final DateTime? examDate;
  final String? personalNotes;
  final List<String> completedChecklist;
  final DateTime lastUpdated;

  const ApplicationTrackerItem({
    required this.id,
    required this.opportunityId,
    required this.opportunity,
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
    String? opportunityId,
    Opportunity? opportunity,
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
      opportunityId: opportunityId ?? this.opportunityId,
      opportunity: opportunity ?? this.opportunity,
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
