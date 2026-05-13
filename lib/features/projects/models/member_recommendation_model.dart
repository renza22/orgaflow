class MemberRecommendation {
  final int id;
  final String name;
  final String role;
  final String avatarUrl;
  final double matchScore;
  final String reason;
  final int capacityUsed;
  final int capacityMax;
  final List<String> matchingSkills;

  MemberRecommendation({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.matchScore,
    required this.reason,
    required this.capacityUsed,
    required this.capacityMax,
    required this.matchingSkills,
  });

  String get initials {
    return name.split(' ').map((n) => n[0]).join('').substring(0, 2);
  }

  double get loadRatio => (capacityUsed / capacityMax) * 100;
}
