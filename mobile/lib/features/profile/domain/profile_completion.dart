import 'package:rexam/models/candidate_profile.dart';

enum ProfileSectionCategory {
  core,
  education,
  preferences,
  optional,
}

class ProfileCompletionItem {
  final String key;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isOptional;
  final ProfileSectionCategory category;
  final String actionLabel;
  final String targetRoute;

  const ProfileCompletionItem({
    required this.key,
    required this.title,
    required this.description,
    required this.isCompleted,
    this.isOptional = false,
    required this.category,
    required this.actionLabel,
    this.targetRoute = '/profile/wizard',
  });
}

class ProfileCompletionReport {
  final int percentage;
  final int completedCount;
  final int totalCoreCount;
  final List<ProfileCompletionItem> completedItems;
  final List<ProfileCompletionItem> missingItems;
  final List<ProfileCompletionItem> optionalItems;

  const ProfileCompletionReport({
    required this.percentage,
    required this.completedCount,
    required this.totalCoreCount,
    required this.completedItems,
    required this.missingItems,
    required this.optionalItems,
  });

  static ProfileCompletionReport evaluate(CandidateProfile profile) {
    final coreItems = <ProfileCompletionItem>[
      ProfileCompletionItem(
        key: 'full_name',
        title: 'Full Legal Name',
        description: 'As recorded in matriculation (Class 10) certificate.',
        isCompleted: profile.fullName.trim().isNotEmpty,
        category: ProfileSectionCategory.core,
        actionLabel: 'Enter Full Name',
      ),
      ProfileCompletionItem(
        key: 'date_of_birth',
        title: 'Date of Birth',
        description: 'Crucial for deterministic statutory age limit & cut-off evaluation.',
        isCompleted: profile.dateOfBirth != null,
        category: ProfileSectionCategory.core,
        actionLabel: 'Select Date of Birth',
      ),
      ProfileCompletionItem(
        key: 'gender',
        title: 'Gender Identity',
        description: 'Required for post-specific eligibility, reservation, and fee waivers.',
        isCompleted: profile.gender != null && profile.gender!.isNotEmpty,
        category: ProfileSectionCategory.core,
        actionLabel: 'Set Gender',
      ),
      ProfileCompletionItem(
        key: 'social_category',
        title: 'Reservation Category',
        description: 'General, OBC-NCL, SC, ST, or EWS for age and fee relaxations.',
        isCompleted: profile.socialCategory.isNotEmpty,
        category: ProfileSectionCategory.core,
        actionLabel: 'Select Category',
      ),
      ProfileCompletionItem(
        key: 'state',
        title: 'State Domicile',
        description: 'Enables state reservation quota and State PSC opportunity matching.',
        isCompleted: profile.state != null && profile.state!.isNotEmpty,
        category: ProfileSectionCategory.core,
        actionLabel: 'Select State Domicile',
      ),
      ProfileCompletionItem(
        key: 'district',
        title: 'Home District',
        description: 'Required for district police, revenue, and local administrative posts.',
        isCompleted: profile.district != null && profile.district!.isNotEmpty,
        category: ProfileSectionCategory.core,
        actionLabel: 'Set District',
      ),
      ProfileCompletionItem(
        key: 'current_status',
        title: 'Current Status',
        description: 'Student, pursuing degree, employed professional, or preparing.',
        isCompleted: profile.currentStatus != null && profile.currentStatus!.isNotEmpty,
        category: ProfileSectionCategory.core,
        actionLabel: 'Set Current Status',
      ),
      ProfileCompletionItem(
        key: 'secondary_school',
        title: '10th / 12th Board Details',
        description: 'Matriculation or Intermediate passing year and percentage.',
        isCompleted: (profile.class10Year != null) || (profile.class12Year != null),
        category: ProfileSectionCategory.education,
        actionLabel: 'Add Board Scores',
      ),
      ProfileCompletionItem(
        key: 'highest_qualification',
        title: 'Highest Qualification Level',
        description: 'Class 10, 12, ITI, Diploma, Undergraduate, PG, or PhD.',
        isCompleted: profile.highestQualification != null && profile.highestQualification!.isNotEmpty,
        category: ProfileSectionCategory.education,
        actionLabel: 'Select Qualification',
      ),
      ProfileCompletionItem(
        key: 'degree_stream',
        title: 'Degree & Academic Stream',
        description: 'Degree specialization (e.g. B.Tech Computer Science, B.Sc, BA).',
        isCompleted: (profile.degreeName != null && profile.degreeName!.isNotEmpty) ||
                     (profile.stream != null && profile.stream!.isNotEmpty),
        category: ProfileSectionCategory.education,
        actionLabel: 'Specify Degree & Stream',
      ),
      ProfileCompletionItem(
        key: 'academic_score',
        title: 'Qualifying Score (CGPA / %)',
        description: 'Official CGPA or percentage for minimum threshold evaluation.',
        isCompleted: profile.effectiveScore != null && profile.effectiveScore! > 0,
        category: ProfileSectionCategory.education,
        actionLabel: 'Enter Academic Score',
      ),
      ProfileCompletionItem(
        key: 'preferred_categories',
        title: 'Opportunity Preferences',
        description: 'Target sectors: UPSC, SSC, Banking, Railways, Defence, PSUs.',
        isCompleted: profile.preferredCategories.isNotEmpty,
        category: ProfileSectionCategory.preferences,
        actionLabel: 'Select Categories',
      ),
      ProfileCompletionItem(
        key: 'career_interests',
        title: 'Career & Domain Interests',
        description: 'Specialization areas to curate relevant vacancy dispatches.',
        isCompleted: profile.careerInterests.isNotEmpty,
        category: ProfileSectionCategory.preferences,
        actionLabel: 'Add Interests',
      ),
      ProfileCompletionItem(
        key: 'avatar_url',
        title: 'Candidate Profile Photograph',
        description: 'Official portrait photo for identification on tracking cards.',
        isCompleted: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty,
        category: ProfileSectionCategory.core,
        actionLabel: 'Upload Photo',
      ),
    ];

    final optionalItems = <ProfileCompletionItem>[
      ProfileCompletionItem(
        key: 'pwbd',
        title: 'PwBD Disability Details',
        description: 'Statutory disability category for compensatory time and reservation.',
        isCompleted: profile.isPwBD,
        isOptional: true,
        category: ProfileSectionCategory.optional,
        actionLabel: 'Configure PwBD',
      ),
      ProfileCompletionItem(
        key: 'ex_serviceman',
        title: 'Ex-Servicemen Concession',
        description: 'Armed forces service duration for ESM age relaxation.',
        isCompleted: profile.isExServiceman,
        isOptional: true,
        category: ProfileSectionCategory.optional,
        actionLabel: 'Configure ESM',
      ),
      ProfileCompletionItem(
        key: 'gate_net',
        title: 'GATE / CSIR-UGC NET Qualification',
        description: 'Competitive score for direct PSU recruitments and research fellowships.',
        isCompleted: (profile.gateScore != null && profile.gateScore! > 0) || profile.hasNetJrf,
        isOptional: true,
        category: ProfileSectionCategory.optional,
        actionLabel: 'Add GATE / NET',
      ),
      ProfileCompletionItem(
        key: 'work_experience',
        title: 'Professional Work Experience',
        description: 'Relevant sector experience for specialist and lateral entry posts.',
        isCompleted: profile.workExperienceYears > 0,
        isOptional: true,
        category: ProfileSectionCategory.optional,
        actionLabel: 'Add Experience',
      ),
    ];

    final completedList = coreItems.where((i) => i.isCompleted).toList();
    final missingList = coreItems.where((i) => !i.isCompleted).toList();
    final totalCore = coreItems.length;
    final pct = totalCore == 0 ? 0 : ((completedList.length / totalCore) * 100).round();

    return ProfileCompletionReport(
      percentage: pct,
      completedCount: completedList.length,
      totalCoreCount: totalCore,
      completedItems: completedList,
      missingItems: missingList,
      optionalItems: optionalItems,
    );
  }
}

