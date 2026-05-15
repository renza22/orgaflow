import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase_config.dart';
import '../../../onboarding/domain/models/master_option.dart';
import '../../domain/models/workload_item_model.dart';

class WorkloadRemoteDatasource {
  WorkloadRemoteDatasource({
    SupabaseClient? client,
  }) : _client = client ?? supabase;

  // Task 61: only todo and in_progress count toward active workload.
  static const _activeWorkloadStatuses = {'todo', 'in_progress'};

  final SupabaseClient _client;

  Future<List<WorkloadItemModel>> fetchWorkload(String organizationId) async {
    final labelMaps = await _fetchLabelMaps();

    try {
      final response = await _client
          .from('v_member_workload')
          .select()
          .eq('organization_id', organizationId)
          .order('load_ratio', ascending: false);

      return _mapWorkloadRows(
        response as List<dynamic>,
        positionMap: labelMaps.$1,
        divisionMap: labelMaps.$2,
      );
    } on PostgrestException {
      // Fall back to table reads when the workload view is unavailable or not
      // yet refreshed in Supabase.
    }

    return _fetchWorkloadFallback(
      organizationId,
      positionMap: labelMaps.$1,
      divisionMap: labelMaps.$2,
    );
  }

  Future<List<WorkloadItemModel>> _fetchWorkloadFallback(
    String organizationId, {
    required Map<String, String> positionMap,
    required Map<String, String> divisionMap,
  }) async {
    final thresholds = await _fetchWorkloadThresholds(organizationId);
    final memberRows = await _client
        .from('members')
        .select(
          'id, organization_id, profile_id, position_code, division_code, weekly_capacity_hours, profiles(full_name)',
        )
        .eq('organization_id', organizationId)
        .eq('status', 'active');

    final memberIds = (memberRows as List<dynamic>)
        .map((rawMember) => (rawMember as Map<String, dynamic>)['id'] as String)
        .toList();

    final assignmentRows = memberIds.isEmpty
        ? const <dynamic>[]
        : await _client
            .from('task_assignments')
            .select(
                'member_id, allocation_hours, tasks(estimated_hours, status)')
            .inFilter('member_id', memberIds);

    final assignedHoursByMemberId = <String, int>{};
    final activeTaskCountByMemberId = <String, int>{};
    for (final rawAssignment in assignmentRows) {
      final assignment = Map<String, dynamic>.from(rawAssignment as Map);
      final memberId = assignment['member_id'] as String?;
      if (memberId == null) {
        continue;
      }

      final task = _asMap(assignment['tasks']);
      final taskStatus = (task?['status'] as String? ?? '')
          .trim()
          .toLowerCase()
          .replaceAll('-', '_');

      if (!_activeWorkloadStatuses.contains(taskStatus)) {
        continue;
      }

      final taskHours = _readNullableInt(assignment['allocation_hours']) ??
          _readNullableInt(task?['estimated_hours']) ??
          0;

      assignedHoursByMemberId.update(
        memberId,
        (current) => current + taskHours,
        ifAbsent: () => taskHours,
      );
      activeTaskCountByMemberId.update(
        memberId,
        (current) => current + 1,
        ifAbsent: () => 1,
      );
    }

    return memberRows.map((rawMember) {
      final member = Map<String, dynamic>.from(rawMember as Map);
      final profile = member['profiles'];
      String fullName = 'Tanpa Nama';

      if (profile is Map<String, dynamic>) {
        fullName = profile['full_name'] as String? ?? fullName;
      } else if (profile is List && profile.isNotEmpty) {
        final profileMap = Map<String, dynamic>.from(profile.first as Map);
        fullName = profileMap['full_name'] as String? ?? fullName;
      }

      final weeklyCapacityHours =
          _readNullableInt(member['weekly_capacity_hours']) ?? 0;
      final assignedHours =
          assignedHoursByMemberId[member['id'] as String] ?? 0;
      final loadRatio =
          weeklyCapacityHours <= 0 ? 0.0 : assignedHours / weeklyCapacityHours;

      return WorkloadItemModel(
        memberId: member['id'] as String,
        organizationId: member['organization_id'] as String? ?? '',
        profileId: member['profile_id'] as String? ?? '',
        fullName: fullName,
        positionCode: member['position_code'] as String?,
        positionLabel: positionMap[member['position_code'] as String? ?? ''],
        divisionCode: member['division_code'] as String?,
        divisionLabel: divisionMap[member['division_code'] as String? ?? ''],
        weeklyCapacityHours: weeklyCapacityHours,
        assignedHours: assignedHours,
        activeTaskCount: activeTaskCountByMemberId[member['id'] as String] ?? 0,
        loadRatio: loadRatio,
        loadPercentage: loadRatio * 100,
        warningThreshold: thresholds.warning,
        criticalThreshold: thresholds.overload,
        overloadThreshold: thresholds.overload,
        workloadStatus: _buildWorkloadStatus(
          weeklyCapacityHours: weeklyCapacityHours,
          loadRatio: loadRatio,
          warningThreshold: thresholds.warning,
          overloadThreshold: thresholds.overload,
        ),
      );
    }).toList()
      ..sort((left, right) => right.loadRatio.compareTo(left.loadRatio));
  }

  List<WorkloadItemModel> _mapWorkloadRows(
    List<dynamic> rows, {
    required Map<String, String> positionMap,
    required Map<String, String> divisionMap,
  }) {
    return rows.map((rawRow) {
      final row = Map<String, dynamic>.from(rawRow as Map);
      final positionCode = row['position_code'] as String?;
      final divisionCode = row['division_code'] as String?;
      return WorkloadItemModel.fromJson({
        ...row,
        'position_label':
            positionCode == null ? null : positionMap[positionCode],
        'division_label':
            divisionCode == null ? null : divisionMap[divisionCode],
      });
    }).toList();
  }

  Future<(Map<String, String>, Map<String, String>)> _fetchLabelMaps() async {
    final responses = await Future.wait<dynamic>([
      _client
          .from('position_templates')
          .select('code, label')
          .eq('is_active', true),
      _client
          .from('division_templates')
          .select('code, label')
          .eq('is_active', true),
    ]);

    final positions = (responses[0] as List<dynamic>)
        .map((json) => MasterOption.fromJson(json as Map<String, dynamic>))
        .toList();
    final divisions = (responses[1] as List<dynamic>)
        .map((json) => MasterOption.fromJson(json as Map<String, dynamic>))
        .toList();

    return (
      {
        for (final item in positions) item.code: item.label,
      },
      {
        for (final item in divisions) item.code: item.label,
      },
    );
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
        warning: _readNullableDouble(response?['warning_threshold']) ?? 0.70,
        overload: _readNullableDouble(response?['overload_threshold']) ?? 1.00,
      );
    } catch (_) {
      return (warning: 0.70, overload: 1.00);
    }
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

  int? _readNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toInt();
    }
    return num.tryParse(value.toString())?.toInt();
  }

  double? _readNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
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
}
