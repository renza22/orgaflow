import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/session_service.dart';
import '../../domain/models/assignment_member_option.dart';
import '../datasources/task_assignment_remote_datasource.dart';

class TaskAssignmentRepository {
  TaskAssignmentRepository({
    TaskAssignmentRemoteDatasource? remoteDatasource,
    SessionService? sessionServiceOverride,
  })  : _remoteDatasource =
            remoteDatasource ?? TaskAssignmentRemoteDatasource(),
        _sessionService = sessionServiceOverride ?? sessionService;

  final TaskAssignmentRemoteDatasource _remoteDatasource;
  final SessionService _sessionService;

  Future<Result<List<AssignmentMemberOption>>> fetchAssignableMembers() async {
    try {
      final context = await _sessionService.getCurrentContext(refresh: true);
      final activeMember = context?.activeMember;

      if (activeMember == null) {
        return Result<List<AssignmentMemberOption>>.failure(
          const AppError('User belum memiliki membership aktif.'),
        );
      }

      final members = await _remoteDatasource.fetchOrganizationMembers(
        activeMember.organizationId,
      );
      return Result<List<AssignmentMemberOption>>.success(members);
    } catch (error) {
      return Result<List<AssignmentMemberOption>>.failure(
        ErrorMapper.map(error),
      );
    }
  }

  Future<Result<void>> assignTask({
    required String taskId,
    required String memberId,
  }) async {
    try {
      final userId = _sessionService.currentUserId;
      if (userId == null) {
        return Result<void>.failure(
          const AppError('User belum login.'),
        );
      }

      await _remoteDatasource.assignTask(
        taskId: taskId,
        memberId: memberId,
        assignedBy: userId,
      );

      return Result<void>.success(null);
    } catch (error) {
      return Result<void>.failure(ErrorMapper.map(error));
    }
  }
}
