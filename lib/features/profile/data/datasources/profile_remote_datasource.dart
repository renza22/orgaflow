import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/supabase_config.dart';
import '../../../../core/utils/storage_avatar_url_resolver.dart';
import '../../domain/models/profile_portfolio_link_model.dart';
import '../../domain/models/profile_skill_model.dart';
import '../../domain/models/profile_task_history_model.dart';
import '../../domain/models/profile_workload_trend_model.dart';
import '../../domain/models/user_profile_detail_model.dart';

class ProfileRemoteDatasource {
  ProfileRemoteDatasource({
    SupabaseClient? client,
    StorageAvatarUrlResolver? avatarUrlResolver,
  })  : _client = client ?? supabase,
        _avatarUrlResolver = avatarUrlResolver ?? StorageAvatarUrlResolver();

  static const String _avatarBucket = StorageAvatarUrlResolver.bucketName;

  final SupabaseClient _client;
  final StorageAvatarUrlResolver _avatarUrlResolver;

  Future<UserProfileDetailModel?> fetchProfileDetail(String memberId) async {
    final memberRow = await _client.from('members').select('''
          id,
          profile_id,
          organization_id,
          role,
          position_code,
          division_code,
          weekly_capacity_hours,
          availability_status,
          joined_at,
          created_at,
          updated_at,
          profile:profiles!inner(
            id,
            email,
            full_name,
            nim,
            study_program_code,
            avatar_path,
            bio,
            created_at,
            updated_at
          )
        ''').eq('id', memberId).maybeSingle();

    if (memberRow == null) {
      return null;
    }

    final member = Map<String, dynamic>.from(memberRow);
    final profile = _asMap(member['profile'] ?? member['profiles']);
    if (profile == null) {
      return null;
    }

    final profileId = profile['id']?.toString() ?? '';
    final organizationId = member['organization_id']?.toString() ?? '';
    final positionCode = member['position_code']?.toString();
    final divisionCode = member['division_code']?.toString();
    final studyProgramCode = profile['study_program_code']?.toString();

    final responses = await Future.wait<dynamic>([
      _fetchWorkload(memberId),
      _fetchWorkloadThresholds(organizationId),
      _fetchLabel('study_programs', studyProgramCode),
      _fetchLabel('position_templates', positionCode),
      _fetchLabel('division_templates', divisionCode),
      _fetchSkills(memberId),
      _fetchPortfolioLinks(profileId),
      _fetchFairnessScores(memberId),
      _fetchTaskHistory(memberId),
      _avatarUrlResolver.resolve(profile['avatar_path']?.toString()),
    ]);

    final workload = responses[0] as Map<String, dynamic>?;
    final thresholds = responses[1] as ({double warning, double overload});
    final studyProgramLabel = responses[2] as String?;
    final positionLabel = responses[3] as String?;
    final divisionLabel = responses[4] as String?;
    final skills = responses[5] as List<ProfileSkillModel>;
    final portfolioLinks = responses[6] as List<ProfilePortfolioLinkModel>;
    final fairnessRows = responses[7] as List<Map<String, dynamic>>;
    final taskHistory = responses[8] as List<ProfileTaskHistoryModel>;
    final avatarSignedUrl = responses[9] as String?;

    final latestFairness = fairnessRows.isEmpty ? null : fairnessRows.first;
    final workloadTrend = fairnessRows.reversed
        .map(
          (row) => ProfileWorkloadTrendModel(
            label: _formatTrendLabel(_parseDateTime(row['score_date'])),
            scoreDate: _parseDateTime(row['score_date']) ?? DateTime.now(),
            workloadHours: _readInt(row['workload_hours']),
            capacityHours: _readInt(row['capacity_hours']),
          ),
        )
        .toList();

    final weeklyCapacityHours = _readInt(
      workload?['weekly_capacity_hours'] ?? member['weekly_capacity_hours'],
    );
    final assignedHours = _readInt(workload?['assigned_hours']);
    final loadRatio = _readDouble(workload?['load_ratio']);
    final loadPercentage =
        workload != null && workload['load_percentage'] != null
            ? _readDouble(workload['load_percentage'])
            : loadRatio * 100;

    return UserProfileDetailModel(
      memberId: member['id']?.toString() ?? memberId,
      profileId: profileId,
      organizationId: organizationId,
      fullName: profile['full_name']?.toString() ?? '',
      email: profile['email']?.toString() ?? '',
      nim: profile['nim']?.toString(),
      studyProgramCode: studyProgramCode,
      studyProgramLabel: studyProgramLabel,
      avatarPath: profile['avatar_path']?.toString(),
      avatarSignedUrl: avatarSignedUrl,
      bio: profile['bio']?.toString(),
      role: member['role']?.toString() ?? 'member',
      positionCode: positionCode,
      positionLabel: positionLabel,
      divisionCode: divisionCode,
      divisionLabel: divisionLabel,
      weeklyCapacityHours: weeklyCapacityHours,
      assignedHours: assignedHours,
      activeTaskCount: _readInt(workload?['active_task_count']),
      loadRatio: loadRatio,
      loadPercentage: loadPercentage,
      workloadStatus: workload?['workload_status']?.toString() ??
          _buildWorkloadStatus(
            weeklyCapacityHours: weeklyCapacityHours,
            loadRatio: loadRatio,
            warningThreshold: thresholds.warning,
            overloadThreshold: thresholds.overload,
          ),
      availabilityStatus:
          member['availability_status']?.toString() ?? 'available',
      joinedAt: _parseDateTime(member['joined_at']),
      createdAt: _parseDateTime(profile['created_at']),
      updatedAt: _parseDateTime(profile['updated_at']),
      fairnessScore: latestFairness == null
          ? null
          : _readDouble(latestFairness['fairness_score']),
      fairnessScoreDate: latestFairness == null
          ? null
          : _parseDateTime(latestFairness['score_date']),
      skills: skills,
      taskHistory: taskHistory,
      workloadTrend: workloadTrend,
      portfolioLinks: portfolioLinks,
    );
  }

  Future<void> updateProfile({
    required String profileId,
    required String fullName,
    required String? nim,
    required String? bio,
    String? studyProgramCode,
  }) async {
    await _client.from('profiles').update({
      'full_name': fullName,
      'nim': _emptyToNull(nim),
      'bio': _emptyToNull(bio),
      if (studyProgramCode != null) 'study_program_code': studyProgramCode,
    }).eq('id', profileId);
  }

  Future<void> updateWeeklyCapacity({
    required String memberId,
    required int weeklyCapacityHours,
  }) async {
    await _client.from('members').update({
      'weekly_capacity_hours': weeklyCapacityHours,
    }).eq('id', memberId);
  }

  Future<String> uploadProfileAvatar({
    required String profileId,
    required XFile imageFile,
    String? existingAvatarPath,
  }) async {
    final extension = _readExtension(imageFile);
    final contentType = _contentTypeFor(extension);
    final bytes = await imageFile.readAsBytes();

    if (bytes.isEmpty) {
      throw const AppError('File foto kosong.');
    }

    final normalizedExtension = extension == 'jpeg' ? 'jpg' : extension;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newPath = '$profileId/avatar_$timestamp.$normalizedExtension';
    final storage = _client.storage.from(_avatarBucket);

    await storage.uploadBinary(
      newPath,
      bytes,
      fileOptions: FileOptions(contentType: contentType),
    );

    try {
      await _client.from('profiles').update({
        'avatar_path': newPath,
      }).eq('id', profileId);
    } catch (_) {
      await _removeAvatarBestEffort(newPath);
      rethrow;
    }

    final oldPath = existingAvatarPath?.trim();
    if (oldPath != null && oldPath.isNotEmpty && oldPath != newPath) {
      await _removeAvatarBestEffort(oldPath);
    }

    return newPath;
  }

  Future<Map<String, dynamic>?> _fetchWorkload(String memberId) async {
    final response = await _client
        .from('v_member_workload')
        .select()
        .eq('member_id', memberId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Map<String, dynamic>.from(response);
  }

  Future<({double warning, double overload})> _fetchWorkloadThresholds(
    String organizationId,
  ) async {
    try {
      final response = await _client
          .from('organization_workload_settings')
          .select('warning_threshold, overload_threshold')
          .eq('organization_id', organizationId)
          .maybeSingle();

      return (
        warning: _readDouble(response?['warning_threshold'], fallback: 0.70),
        overload: _readDouble(response?['overload_threshold'], fallback: 1.00),
      );
    } catch (_) {
      return (warning: 0.70, overload: 1.00);
    }
  }

  Future<String?> _fetchLabel(String table, String? code) async {
    final normalizedCode = code?.trim();
    if (normalizedCode == null || normalizedCode.isEmpty) {
      return null;
    }

    final response = await _client
        .from(table)
        .select('label')
        .eq('code', normalizedCode)
        .maybeSingle();

    return response?['label']?.toString();
  }

  Future<List<ProfileSkillModel>> _fetchSkills(String memberId) async {
    final response = await _client
        .from('member_skills')
        .select('proficiency_level, skill:skills(name)')
        .eq('member_id', memberId);

    final skills = <ProfileSkillModel>[];
    for (final rawRow in response as List<dynamic>) {
      final row = Map<String, dynamic>.from(rawRow as Map);
      final skill = _asMap(row['skill'] ?? row['skills']);
      final name = skill?['name']?.toString().trim();
      if (name == null || name.isEmpty) {
        continue;
      }

      skills.add(
        ProfileSkillModel(
          name: name,
          proficiencyLevel: _readInt(row['proficiency_level']),
        ),
      );
    }

    skills.sort((left, right) => left.name.toLowerCase().compareTo(
          right.name.toLowerCase(),
        ));
    return skills;
  }

  Future<List<ProfilePortfolioLinkModel>> _fetchPortfolioLinks(
    String profileId,
  ) async {
    final response = await _client
        .from('portfolio_links')
        .select(
            'platform_code, url, sort_order, platform:portfolio_platforms(label)')
        .eq('profile_id', profileId)
        .order('sort_order', ascending: true);

    final links = <ProfilePortfolioLinkModel>[];
    for (final rawRow in response as List<dynamic>) {
      final row = Map<String, dynamic>.from(rawRow as Map);
      final platform = _asMap(row['platform'] ?? row['portfolio_platforms']);
      final platformCode = row['platform_code']?.toString() ?? '';
      final url = row['url']?.toString().trim() ?? '';
      if (url.isEmpty) {
        continue;
      }

      links.add(
        ProfilePortfolioLinkModel(
          platformCode: platformCode,
          platformLabel: platform?['label']?.toString() ?? platformCode,
          url: url,
        ),
      );
    }

    return links;
  }

  Future<List<Map<String, dynamic>>> _fetchFairnessScores(
    String memberId,
  ) async {
    final response = await _client
        .from('fairness_scores')
        .select('score_date, workload_hours, capacity_hours, fairness_score')
        .eq('member_id', memberId)
        .order('score_date', ascending: false)
        .limit(12);

    return (response as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<ProfileTaskHistoryModel>> _fetchTaskHistory(
    String memberId,
  ) async {
    final response = await _client
        .from('task_assignments')
        .select('''
          id,
          assigned_at,
          allocation_hours,
          task:tasks!inner(
            id,
            title,
            status,
            due_date,
            project:projects!inner(name)
          )
        ''')
        .eq('member_id', memberId)
        .order('assigned_at', ascending: false)
        .limit(20);

    final history = <ProfileTaskHistoryModel>[];
    for (final rawRow in response as List<dynamic>) {
      final row = Map<String, dynamic>.from(rawRow as Map);
      final task = _asMap(row['task'] ?? row['tasks']);
      if (task == null) {
        continue;
      }

      final project = _asMap(task['project'] ?? task['projects']);
      history.add(
        ProfileTaskHistoryModel(
          id: row['id']?.toString() ?? task['id']?.toString() ?? '',
          title: task['title']?.toString() ?? '-',
          projectName: project?['name']?.toString() ?? '-',
          status: task['status']?.toString() ?? '',
          assignedAt: _parseDateTime(row['assigned_at']),
          dueDate: _parseDateTime(task['due_date']),
          allocationHours: row['allocation_hours'] == null
              ? null
              : _readInt(row['allocation_hours']),
        ),
      );
    }

    return history;
  }

  Future<void> _removeAvatarBestEffort(String avatarPath) async {
    try {
      await _client.storage.from(_avatarBucket).remove([avatarPath]);
    } catch (_) {
      // Best-effort cleanup only.
    }
  }

  String _readExtension(XFile imageFile) {
    final source = imageFile.name.trim().isNotEmpty
        ? imageFile.name.trim()
        : imageFile.path.trim();
    final dotIndex = source.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == source.length - 1) {
      throw const AppError('Format foto harus jpg, jpeg, png, atau webp.');
    }

    final extension = source.substring(dotIndex + 1).toLowerCase();
    if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
      throw const AppError('Format foto harus jpg, jpeg, png, atau webp.');
    }

    return extension;
  }

  String _contentTypeFor(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  String _buildWorkloadStatus({
    required int weeklyCapacityHours,
    required double loadRatio,
    double warningThreshold = 0.70,
    double overloadThreshold = 1.00,
  }) {
    if (weeklyCapacityHours <= 0) {
      return 'no_capacity';
    }
    if (loadRatio >= overloadThreshold) {
      return 'overload';
    }
    if (loadRatio >= warningThreshold) {
      return 'warning';
    }
    return 'safe';
  }

  String _formatTrendLabel(DateTime? value) {
    if (value == null) {
      return '-';
    }

    return '${value.day}/${value.month}';
  }

  String? _emptyToNull(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }

    return null;
  }

  int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return num.tryParse(value?.toString() ?? '')?.toInt() ?? 0;
  }

  double _readDouble(dynamic value, {double fallback = 0}) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
