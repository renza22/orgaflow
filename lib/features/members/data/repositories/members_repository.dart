import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/session_service.dart';
import '../../models/member_model.dart';
import '../datasources/members_remote_datasource.dart';

class MembersRepository {
  MembersRepository({
    MembersRemoteDatasource? remoteDatasource,
    SessionService? sessionServiceOverride,
  })  : _remoteDatasource = remoteDatasource ?? MembersRemoteDatasource(),
        _sessionService = sessionServiceOverride ?? sessionService;

  final MembersRemoteDatasource _remoteDatasource;
  final SessionService _sessionService;

  Future<Result<List<Member>>> fetchMembers() async {
    try {
      final context = await _sessionService.getCurrentContext(refresh: true);
      final activeMember = context?.activeMember;

      if (activeMember == null) {
        return Result<List<Member>>.failure(
          const AppError('User belum memiliki organisasi aktif.'),
        );
      }

      final members = await _remoteDatasource.fetchMembers(
        activeMember.organizationId,
      );

      return Result<List<Member>>.success(members);
    } catch (error) {
      return Result<List<Member>>.failure(ErrorMapper.map(error));
    }
  }
}
