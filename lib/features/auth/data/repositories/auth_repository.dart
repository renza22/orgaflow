import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/session_service.dart';
import '../../domain/models/register_flow_result.dart';
import '../../domain/models/register_input.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepository {
  AuthRepository({
    AuthRemoteDatasource? remoteDatasource,
    SessionService? sessionServiceOverride,
  })  : _remoteDatasource = remoteDatasource ?? AuthRemoteDatasource(),
        _sessionService = sessionServiceOverride ?? sessionService;

  final AuthRemoteDatasource _remoteDatasource;
  final SessionService _sessionService;

  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _remoteDatasource.signIn(
        email: email,
        password: password,
      );
      await _sessionService.clearCache();
      return Result<void>.success(null);
    } catch (error) {
      return Result<void>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<RegisterFlowResult>> signUp(RegisterInput input) async {
    try {
      final response = await _remoteDatasource.signUp(input);
      await _sessionService.clearCache();

      final hasSession = response.session != null;
      return Result<RegisterFlowResult>.success(
        RegisterFlowResult(
          hasSession: hasSession,
          message: hasSession
              ? 'Akun berhasil dibuat.'
              : 'Akun berhasil dibuat. Cek email Anda untuk konfirmasi sebelum login.',
        ),
      );
    } catch (error) {
      return Result<RegisterFlowResult>.failure(ErrorMapper.map(error));
    }
  }
}
