import '../../../../core/result/result.dart';
import '../../../../core/session/session_context.dart';
import '../../../../core/session/session_service.dart';
import '../../data/repositories/auth_repository.dart';

class AuthPresenter {
  AuthPresenter({
    AuthRepository? repository,
    SessionService? sessionServiceOverride,
  })  : _repository = repository ?? AuthRepository(),
        _sessionService = sessionServiceOverride ?? sessionService;

  final AuthRepository _repository;
  final SessionService _sessionService;

  Future<Result<AppRouteTarget>> signIn({
    required String email,
    required String password,
  }) async {
    final signInResult = await _repository.signIn(
      email: email,
      password: password,
    );

    if (signInResult.isFailure) {
      return Result<AppRouteTarget>.failure(signInResult.error!);
    }

    final routeTarget = await _sessionService.resolveTarget(refresh: true);
    return Result<AppRouteTarget>.success(routeTarget);
  }
}
