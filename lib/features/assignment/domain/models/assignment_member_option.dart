class AssignmentMemberOption {
  const AssignmentMemberOption({
    required this.id,
    required this.fullName,
    this.positionCode,
    this.positionLabel,
  });

  final String id;
  final String fullName;
  final String? positionCode;
  final String? positionLabel;

  String get displayLabel {
    if (positionLabel != null && positionLabel!.isNotEmpty) {
      return '$fullName - $positionLabel';
    }

    return fullName;
  }
}
