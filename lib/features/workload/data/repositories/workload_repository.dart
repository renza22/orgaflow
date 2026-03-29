import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/session_service.dart';
import '../../domain/models/workload_item_model.dart';
import '../datasources/workload_remote_datasource.dart';

class WorkloadRepository {
  WorkloadRepository({
    WorkloadRemoteDatasource? remoteDatasource,
    SessionService? sessionServiceOverride,
  })  : _remoteDatasource = remoteDatasource ?? WorkloadRemoteDatasource(),
        _sessionService = sessionServiceOverride ?? sessionService;

  final WorkloadRemoteDatasource _remoteDatasource;
  final SessionService _sessionService;

  Future<Result<List<WorkloadItemModel>>> fetchWorkload() async {
    try {
      final context = await _sessionService.getCurrentContext(refresh: true);
      final activeMember = context?.activeMember;

      if (activeMember == null) {
        return Result<List<WorkloadItemModel>>.failure(
          const AppError('User belum memiliki membership aktif.'),
        );
      }

      final items = await _remoteDatasource.fetchWorkload(
        activeMember.organizationId,
      );

      return Result<List<WorkloadItemModel>>.success(items);
    } catch (error) {
      return Result<List<WorkloadItemModel>>.failure(
        ErrorMapper.map(error),
      );
    }
  }
}
