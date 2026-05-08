import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase_config.dart';
import '../../../../core/utils/storage_avatar_url_resolver.dart';
import '../../../workload/domain/models/workload_item_model.dart';
import '../../models/member_model.dart';

class MembersRemoteDatasource {
  MembersRemoteDatasource({
    SupabaseClient? client,
    StorageAvatarUrlResolver? avatarUrlResolver,
  })  : _client = client ?? supabase,
        _avatarUrlResolver = avatarUrlResolver ?? StorageAvatarUrlResolver();

  final SupabaseClient _client;
  final StorageAvatarUrlResolver _avatarUrlResolver;

  Future<List<Member>> fetchMembers(String organizationId) async {
    final responses = await Future.wait<dynamic>([
      _client
          .from('members')
          .select(
            'id, profile_id, organization_id, role, position_code, '
            'division_code, weekly_capacity_hours, '
            'profiles(full_name, email, avatar_path)',
          )
          .eq('organization_id', organizationId)
          .eq('status', 'active')
          .order('joined_at', ascending: true),
      _client
          .from('v_member_workload')
          .select()
          .eq('organization_id', organizationId),
      _client
          .from('position_templates')
          .select('code, label')
          .eq('is_active', true),
      _client
          .from('division_templates')
          .select('code, label')
          .eq('is_active', true),
    ]);

    final memberRows = responses[0] as List<dynamic>;
    if (memberRows.isEmpty) {
      return const [];
    }

    final workloadRows = responses[1] as List<dynamic>;
    final positionRows = responses[2] as List<dynamic>;
    final divisionRows = responses[3] as List<dynamic>;

    final workloadByMemberId = <String, WorkloadItemModel>{};
    for (final rawRow in workloadRows) {
      final workload = WorkloadItemModel.fromJson(
        Map<String, dynamic>.from(rawRow as Map),
      );
      workloadByMemberId[workload.memberId] = workload;
    }

    final positionLabelByCode = _buildLabelMap(positionRows);
    final divisionLabelByCode = _buildLabelMap(divisionRows);
    final memberIds = memberRows
        .map((row) => (row as Map)['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
    final skillsByMemberId = await _fetchSkillsByMemberId(memberIds);
    final avatarSignedUrlByPath = await _avatarUrlResolver.resolveMany(
      memberRows.map((row) {
        final profile = _asMap((row as Map)['profiles'] ?? row['profile']);
        return profile?['avatar_path']?.toString();
      }),
    );

    return memberRows.map((rawMember) {
      final member = Map<String, dynamic>.from(rawMember as Map);
      final memberId = member['id']?.toString() ?? '';
      final profile = _asMap(member['profiles'] ?? member['profile']);
      final avatarPath = profile?['avatar_path']?.toString();
      final positionCode = member['position_code']?.toString();
      final divisionCode = member['division_code']?.toString();
      final workload = workloadByMemberId[memberId];

      final weeklyCapacityHours = workload?.weeklyCapacityHours ??
          _readInt(member['weekly_capacity_hours']);
      final assignedHours = workload?.assignedHours ?? 0;
      final loadRatio = workload?.loadRatio ??
          (weeklyCapacityHours <= 0
              ? 0.0
              : assignedHours / weeklyCapacityHours);

      return Member(
        memberId: memberId,
        profileId: member['profile_id']?.toString() ?? '',
        name: profile?['full_name']?.toString() ?? 'Tanpa Nama',
        role: member['role']?.toString() ?? 'member',
        email: profile?['email']?.toString() ?? '',
        positionCode: positionCode,
        positionLabel:
            positionCode == null ? null : positionLabelByCode[positionCode],
        divisionCode: divisionCode,
        divisionLabel:
            divisionCode == null ? null : divisionLabelByCode[divisionCode],
        avatarPath: avatarPath,
        avatarSignedUrl: avatarPath == null
            ? null
            : avatarSignedUrlByPath[avatarPath.trim()],
        capacityMax: weeklyCapacityHours,
        capacityUsed: assignedHours,
        skills: skillsByMemberId[memberId] ?? const [],
        activeTaskCount: workload?.activeTaskCount ?? 0,
        loadRatio: loadRatio,
        loadPercentage: workload?.loadPercentage ?? loadRatio * 100,
        workloadStatus: workload?.workloadStatus ??
            _buildWorkloadStatus(
              weeklyCapacityHours: weeklyCapacityHours,
              loadRatio: loadRatio,
            ),
      );
    }).toList();
  }

  Future<Map<String, List<String>>> _fetchSkillsByMemberId(
    List<String> memberIds,
  ) async {
    if (memberIds.isEmpty) {
      return const {};
    }

    try {
      final response = await _client
          .from('member_skills')
          .select('member_id, skills(name)')
          .inFilter('member_id', memberIds);

      final skillsByMemberId = <String, List<String>>{};
      for (final rawRow in response as List<dynamic>) {
        final row = Map<String, dynamic>.from(rawRow as Map);
        final memberId = row['member_id']?.toString();
        final skill = _asMap(row['skills'] ?? row['skill']);
        final skillName = skill?['name']?.toString().trim();

        if (memberId == null ||
            memberId.isEmpty ||
            skillName == null ||
            skillName.isEmpty) {
          continue;
        }

        skillsByMemberId.putIfAbsent(memberId, () => <String>[]);
        if (!skillsByMemberId[memberId]!.contains(skillName)) {
          skillsByMemberId[memberId]!.add(skillName);
        }
      }

      for (final skills in skillsByMemberId.values) {
        skills.sort((left, right) => left.toLowerCase().compareTo(
              right.toLowerCase(),
            ));
      }

      return skillsByMemberId;
    } catch (error) {
      debugPrint('MembersRemoteDatasource skill query failed: $error');
      return const {};
    }
  }

  Map<String, String> _buildLabelMap(List<dynamic> rows) {
    return {
      for (final rawRow in rows)
        if ((rawRow as Map)['code'] != null && rawRow['label'] != null)
          rawRow['code'].toString(): rawRow['label'].toString(),
    };
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

  String _buildWorkloadStatus({
    required int weeklyCapacityHours,
    required double loadRatio,
  }) {
    if (weeklyCapacityHours <= 0) {
      return 'no_capacity';
    }
    if (loadRatio > 1) {
      return 'overload';
    }
    if (loadRatio > 0.9) {
      return 'critical';
    }
    if (loadRatio >= 0.7) {
      return 'warning';
    }
    return 'safe';
  }
}
