import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/session_context.dart';
import '../../../../core/session/session_service.dart';

class SessionResolverPresenter {
  SessionResolverPresenter({
    SessionService? sessionServiceOverride,
  }) : _sessionService = sessionServiceOverride ?? sessionService;

  final SessionService _sessionService;

  Future<Result<AppRouteTarget>> resolve({
    bool refresh = false,
  }) async {
    try {
      final target = await _sessionService.resolveTarget(refresh: refresh);
      return Result<AppRouteTarget>.success(target);
    } catch (error) {
      return Result<AppRouteTarget>.failure(ErrorMapper.map(error));
    }
  }
}
