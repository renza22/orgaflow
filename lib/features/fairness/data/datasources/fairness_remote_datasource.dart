import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase_config.dart';
import '../../domain/models/fairness_summary_model.dart';
import '../../domain/models/fairness_trend_model.dart';
import '../../domain/models/member_fairness_breakdown_model.dart';

class FairnessRemoteDatasource {
  FairnessRemoteDatasource({
    SupabaseClient? client,
  }) : _client = client ?? supabase;

  final SupabaseClient _client;

  Future<FairnessSummaryModel?> fetchOrganizationFairnessSummary(
    String organizationId,
  ) async {
    final response = await _client.rpc(
      'get_organization_fairness_summary',
      params: {
        'p_organization_id': organizationId,
      },
    );

    final row = _extractSingleRow(response);
    if (row == null) {
      return null;
    }

    return FairnessSummaryModel.fromJson(row);
  }

  Future<List<MemberFairnessBreakdownModel>> fetchMemberFairnessBreakdown(
    String organizationId,
  ) async {
    final response = await _client.rpc(
      'get_member_fairness_breakdown',
      params: {
        'p_organization_id': organizationId,
      },
    );

    final rows = _extractRows(response);
    return rows.map(MemberFairnessBreakdownModel.fromJson).toList();
  }

  Future<List<FairnessTrendModel>> fetchOrganizationFairnessTrend(
    String organizationId, {
    int limit = 12,
  }) async {
    final response = await _client
        .from('v_organization_fairness_trend')
        .select(
          'organization_id, score_date, average_load_percentage, '
          'stddev_load_percentage, fairness_score, safe_count, '
          'warning_count, overload_count',
        )
        .eq('organization_id', organizationId)
        .order('score_date', ascending: false)
        .limit(limit);

    final trend = (response as List<dynamic>)
        .map(
          (row) => FairnessTrendModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();

    trend.sort((left, right) {
      final leftDate = left.scoreDate ?? DateTime(1970);
      final rightDate = right.scoreDate ?? DateTime(1970);
      return leftDate.compareTo(rightDate);
    });

    return trend;
  }

  Future<void> refreshOrganizationFairnessScores({
    required String organizationId,
    required DateTime scoreDate,
  }) async {
    await _client.rpc(
      'refresh_organization_fairness_scores',
      params: {
        'p_organization_id': organizationId,
        'p_score_date': _formatDate(scoreDate),
      },
    );
  }

  Map<String, dynamic>? _extractSingleRow(dynamic response) {
    if (response == null) {
      return null;
    }

    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _extractRows(dynamic response) {
    if (response == null) {
      return const [];
    }

    if (response is List) {
      return response
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }

    final row = _extractSingleRow(response);
    return row == null ? const [] : [row];
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
