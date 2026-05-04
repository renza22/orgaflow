import '../../../../core/result/result.dart';
import '../../data/repositories/members_repository.dart';
import '../../models/member_model.dart';

class MembersPresenter {
  MembersPresenter({
    MembersRepository? repository,
  }) : _repository = repository ?? MembersRepository();

  final MembersRepository _repository;

  Future<Result<List<Member>>> loadMembers() {
    return _repository.fetchMembers();
  }
}
