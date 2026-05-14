import '../../../../core/result/result.dart';
import '../../data/repositories/task_assignment_repository.dart';
import '../../domain/models/assignment_member_option.dart';
import '../../domain/models/smart_assign_recommendation_model.dart';

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

  Future<Result<List<SmartAssignRecommendationModel>>>
      loadSmartRecommendations({
    required String taskId,
    int limit = 3,
    double hardOverloadThreshold = 1.2,
  }) {
    return _repository.fetchSmartAssignRecommendations(
      taskId: taskId,
      limit: limit,
      hardOverloadThreshold: hardOverloadThreshold,
    );
  }
}
