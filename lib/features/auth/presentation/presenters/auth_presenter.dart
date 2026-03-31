import '../../../../core/errors/app_error.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/session_context.dart';
import '../../../../core/session/session_service.dart';
import '../../data/repositories/auth_repository.dart';

class AuthPresenter {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

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

  Future<Result<void>> requestPasswordReset({
    required String email,
  }) {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      return Future.value(
        Result<void>.failure(
          const AppError('Masukkan email akun Anda untuk reset password.'),
        ),
      );
    }

    if (!_emailPattern.hasMatch(normalizedEmail)) {
      return Future.value(
        Result<void>.failure(
          const AppError('Masukkan email yang valid untuk reset password.'),
        ),
      );
    }

    return _repository.requestPasswordReset(
      email: normalizedEmail,
    );
  }
}
