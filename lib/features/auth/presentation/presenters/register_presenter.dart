import '../../../../core/result/result.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/register_flow_result.dart';
import '../../domain/models/register_input.dart';

class RegisterPresenter {
  RegisterPresenter({
    AuthRepository? repository,
  }) : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  Future<Result<RegisterFlowResult>> register(RegisterInput input) {
    return _repository.signUp(input);
  }
}
