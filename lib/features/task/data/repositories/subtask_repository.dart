import '../../../../core/errors/app_error.dart';
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
      final normalizedParentTaskId = parentTaskId.trim();
      if (normalizedParentTaskId.isEmpty) {
        return Result<List<SubtaskModel>>.failure(
          const AppError('Task utama tidak valid.'),
        );
      }

      final subtasks = await _remoteDatasource.fetchSubtasks(
        normalizedParentTaskId,
      );
      return Result.success(subtasks);
    } catch (error) {
      return Result.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<SubtaskModel>> createSubtask({
    required String parentTaskId,
    required String title,
    required String description,
  }) async {
    try {
      final normalizedParentTaskId = parentTaskId.trim();
      if (normalizedParentTaskId.isEmpty) {
        return Result<SubtaskModel>.failure(
          const AppError('Task utama tidak valid.'),
        );
      }

      final normalizedTitle = title.trim();
      if (normalizedTitle.isEmpty) {
        return Result<SubtaskModel>.failure(
          const AppError('Judul sub-task tidak boleh kosong.'),
        );
      }

      final subtask = await _remoteDatasource.createSubtask(
        parentTaskId: normalizedParentTaskId,
        title: normalizedTitle,
        description: description.trim(),
      );
      return Result.success(subtask);
    } catch (error) {
      return Result.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<SubtaskModel>> updateSubtask({
    required String subtaskId,
    String? title,
    String? description,
    String? status,
  }) async {
    try {
      final normalizedSubtaskId = subtaskId.trim();
      if (normalizedSubtaskId.isEmpty) {
        return Result<SubtaskModel>.failure(
          const AppError('Sub-task tidak valid.'),
        );
      }

      final subtask = await _remoteDatasource.updateSubtask(
        subtaskId: normalizedSubtaskId,
        title: title?.trim(),
        description: description?.trim(),
        status: status?.trim(),
      );
      return Result.success(subtask);
    } catch (error) {
      return Result.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<void>> deleteSubtask(String subtaskId) async {
    try {
      final normalizedSubtaskId = subtaskId.trim();
      if (normalizedSubtaskId.isEmpty) {
        return Result<void>.failure(
          const AppError('Sub-task tidak valid.'),
        );
      }

      await _remoteDatasource.deleteSubtask(normalizedSubtaskId);
      return Result.success(null);
    } catch (error) {
      return Result.failure(ErrorMapper.map(error));
    }
  }
}
