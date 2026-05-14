import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/supabase_config.dart';
import '../../../onboarding/domain/models/master_option.dart';
import '../../domain/models/assignment_member_option.dart';
import '../../domain/models/smart_assign_recommendation_model.dart';

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

  Future<List<SmartAssignRecommendationModel>> fetchSmartAssignRecommendations({
    required String taskId,
    int limit = 3,
    double hardOverloadThreshold = 1.2,
  }) async {
    final response = await _client.rpc(
      'get_smart_assign_recommendations',
      params: {
        'p_task_id': taskId,
        'p_limit': limit,
        'p_hard_overload_threshold': hardOverloadThreshold,
      },
    );

    if (response == null) {
      return const [];
    }

    if (response is List) {
      return response
          .map(
            (json) => SmartAssignRecommendationModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList(growable: false);
    }

    if (response is Map) {
      return [
        SmartAssignRecommendationModel.fromJson(
          Map<String, dynamic>.from(response),
        ),
      ];
    }

    throw const AppError('Response rekomendasi Smart Assign tidak valid.');
  }

  Future<void> assignTask({
    required String taskId,
    required String memberId,
  }) async {
    await _client.rpc(
      'assign_task_with_notification',
      params: {
        'p_task_id': taskId,
        'p_member_id': memberId,
      },
    );
  }
}
