import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/models/subtask_model.dart';
import '../datasources/subtask_remote_datasource.dart';

class SubtaskRepository {
  SubtaskRepository({SubtaskRemoteDatasource? remoteDatasource})
      : _remoteDatasource = remoteDatasource ?? SubtaskRemoteDatasource();

  final SubtaskRemoteDatasource _remoteDatasource;

  Future<Result<List<SubtaskModel>>> fetchSubtasks(String parentTaskId) async {
    try {
      final subtasks = await _remoteDatasource.fetchSubtasks(parentTaskId);
      return Result.success(subtasks);
    } catch (error) {
      return Result<List<SubtaskModel>>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<SubtaskModel>> createSubtask({
    required String parentTaskId,
    required String title,
    required String description,
    required String assignedToEmail,
    required String assignedToName,
    required String createdBy,
  }) async {
    try {
      final subtask = await _remoteDatasource.createSubtask(
        parentTaskId: parentTaskId,
        title: title,
        description: description,
        assignedToEmail: assignedToEmail,
        assignedToName: assignedToName,
        createdBy: createdBy,
      );
      return Result.success(subtask);
    } catch (error) {
      return Result<SubtaskModel>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<SubtaskModel>> updateSubtask({
    required String subtaskId,
    String? title,
    String? description,
    String? status,
  }) async {
    try {
      final subtask = await _remoteDatasource.updateSubtask(
        subtaskId: subtaskId,
        title: title,
        description: description,
        status: status,
      );
      return Result.success(subtask);
    } catch (error) {
      return Result<SubtaskModel>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<void>> deleteSubtask(String subtaskId) async {
    try {
      await _remoteDatasource.deleteSubtask(subtaskId);
      return Result.success(null);
    } catch (error) {
      return Result<void>.failure(ErrorMapper.map(error));
    }
  }
}
