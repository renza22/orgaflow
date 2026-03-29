import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/supabase_config.dart';
import '../../../onboarding/domain/models/master_option.dart';
import '../../domain/models/assignment_member_option.dart';

class TaskAssignmentRemoteDatasource {
  TaskAssignmentRemoteDatasource({
    SupabaseClient? client,
  }) : _client = client ?? supabase;

  final SupabaseClient _client;

  Future<List<AssignmentMemberOption>> fetchOrganizationMembers(
    String organizationId,
  ) async {
    final responses = await Future.wait<dynamic>([
      _client
          .from('members')
          .select('id, position_code, profiles(full_name)')
          .eq('organization_id', organizationId)
          .eq('status', 'active'),
      _client
          .from('position_templates')
          .select('code, label')
          .eq('is_active', true),
    ]);

    final memberRows = responses[0] as List<dynamic>;
    final positionRows = responses[1] as List<dynamic>;

    final positions = positionRows
        .map((json) => MasterOption.fromJson(json as Map<String, dynamic>))
        .toList();

    final positionMap = {
      for (final position in positions) position.code: position.label,
    };

    return memberRows.map((json) {
      final item = Map<String, dynamic>.from(json as Map);
      final profile = item['profiles'];

      String fullName = 'Tanpa Nama';
      if (profile is Map<String, dynamic>) {
        fullName = profile['full_name'] as String? ?? fullName;
      } else if (profile is List && profile.isNotEmpty) {
        final profileMap = Map<String, dynamic>.from(profile.first as Map);
        fullName = profileMap['full_name'] as String? ?? fullName;
      }

      final positionCode = item['position_code'] as String?;
      return AssignmentMemberOption(
        id: item['id'] as String,
        fullName: fullName,
        positionCode: positionCode,
        positionLabel: positionCode == null ? null : positionMap[positionCode],
      );
    }).toList();
  }

  Future<void> assignTask({
    required String taskId,
    required String memberId,
    required String assignedBy,
  }) async {
    final existing = await _client
        .from('task_assignments')
        .select('id')
        .eq('task_id', taskId)
        .eq('member_id', memberId)
        .maybeSingle();

    if (existing != null) {
      throw const AppError('Member ini sudah ditugaskan pada task tersebut.');
    }

    await _client.from('task_assignments').insert({
      'task_id': taskId,
      'member_id': memberId,
      'assigned_by': assignedBy,
    });
  }
}
