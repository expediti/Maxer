/// Enumerates supported academic grading systems in the Indian statutory and recruitment framework.
enum AcademicGradingType {
  percentage('Percentage', '%', 100.0),
  cgpa('CGPA', 'CGPA', 10.0),
  gpa('GPA', 'GPA', 4.0);

  final String label;
  final String unit;
  final double defaultScaleMax;
  const AcademicGradingType(this.label, this.unit, this.defaultScaleMax);

  static AcademicGradingType fromString(String? val) {
    if (val == null) return AcademicGradingType.cgpa;
    final lower = val.toLowerCase().trim();
    if (lower == 'cgpa') return AcademicGradingType.cgpa;
    if (lower == 'gpa') return AcademicGradingType.gpa;
    if (lower == 'percentage' || lower == 'percent' || lower == '%') {
      return AcademicGradingType.percentage;
    }
    return AcademicGradingType.cgpa;
  }
}

/// A strongly typed academic score model that encapsulates numeric value,
/// grading system type, and grading scale max.
///
/// Invariants:
/// - A score must never be processed or stored without its grading type and scale.
/// - A CGPA must never be treated as or converted into a percentage without an official formula.
/// - Never infer grading type from the numeric value.
class AcademicScore {
  final double scoreValue;
  final AcademicGradingType gradingType;
  final double gradingScaleMax;

  const AcademicScore({
    required this.scoreValue,
    required this.gradingType,
    this.gradingScaleMax = 10.0,
  });

  bool get isCgpa => gradingType == AcademicGradingType.cgpa;
  bool get isPercentage => gradingType == AcademicGradingType.percentage;
  bool get isGpa => gradingType == AcademicGradingType.gpa;

  /// Full truthful human-readable display with grading scale context.
  /// Example: '7.50 CGPA (10-point scale)' or '65.0%' or '3.80 GPA (4-point scale)'
  String get formattedDisplay {
    switch (gradingType) {
      case AcademicGradingType.percentage:
        return '${scoreValue.toStringAsFixed(1)}%';
      case AcademicGradingType.cgpa:
        final scaleStr = gradingScaleMax == 10.0
            ? '10-point scale'
            : '${gradingScaleMax.toStringAsFixed(1)}-point scale';
        return '${scoreValue.toStringAsFixed(2)} CGPA ($scaleStr)';
      case AcademicGradingType.gpa:
        final scaleStr = gradingScaleMax == 4.0
            ? '4-point scale'
            : '${gradingScaleMax.toStringAsFixed(1)}-point scale';
        return '${scoreValue.toStringAsFixed(2)} GPA ($scaleStr)';
    }
  }

  /// Compact representation with unit.
  /// Example: '7.50 CGPA' or '65.0%'
  String get shortDisplay {
    switch (gradingType) {
      case AcademicGradingType.percentage:
        return '${scoreValue.toStringAsFixed(1)}%';
      case AcademicGradingType.cgpa:
        return '${scoreValue.toStringAsFixed(2)} CGPA';
      case AcademicGradingType.gpa:
        return '${scoreValue.toStringAsFixed(2)} GPA';
    }
  }

  Map<String, dynamic> toJson() => {
        'score_value': scoreValue,
        'grading_type': gradingType.name,
        'grading_scale_max': gradingScaleMax,
      };

  factory AcademicScore.fromJson(Map<String, dynamic> json) {
    return AcademicScore(
      scoreValue: (json['score_value'] as num).toDouble(),
      gradingType: AcademicGradingType.fromString(json['grading_type']?.toString()),
      gradingScaleMax: (json['grading_scale_max'] as num?)?.toDouble() ?? 10.0,
    );
  }

  @override
  String toString() => formattedDisplay;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademicScore &&
          runtimeType == other.runtimeType &&
          scoreValue == other.scoreValue &&
          gradingType == other.gradingType &&
          gradingScaleMax == other.gradingScaleMax;

  @override
  int get hashCode => scoreValue.hashCode ^ gradingType.hashCode ^ gradingScaleMax.hashCode;
}

