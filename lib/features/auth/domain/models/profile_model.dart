class ProfileModel {
  const ProfileModel({
    required this.id,
    this.email,
    this.fullName,
    this.nim,
    this.studyProgramCode,
    this.avatarPath,
    this.bio,
    required this.onboardingCompleted,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? email;
  final String? fullName;
  final String? nim;
  final String? studyProgramCode;
  final String? avatarPath;
  final String? bio;
  final bool onboardingCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      nim: json['nim'] as String?,
      studyProgramCode: json['study_program_code'] as String?,
      avatarPath: json['avatar_path'] as String?,
      bio: json['bio'] as String?,
      onboardingCompleted: (json['onboarding_completed'] as bool?) ?? false,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
