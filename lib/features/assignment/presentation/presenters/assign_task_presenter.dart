import '../../../../core/result/result.dart';
import '../../data/repositories/task_assignment_repository.dart';
import '../../domain/models/assignment_member_option.dart';

class AssignTaskPresenter {
  AssignTaskPresenter({
    TaskAssignmentRepository? repository,
  }) : _repository = repository ?? TaskAssignmentRepository();

  final TaskAssignmentRepository _repository;

  Future<Result<List<AssignmentMemberOption>>> loadMembers() {
    return _repository.fetchAssignableMembers();
  }

  Future<Result<void>> assignTask({
    required String taskId,
    required String memberId,
  }) {
    return _repository.assignTask(
      taskId: taskId,
      memberId: memberId,
    );
  }
}
