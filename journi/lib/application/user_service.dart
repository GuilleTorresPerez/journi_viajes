import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/user.dart';
import 'package:journi/domain/ports/user_repository.dart';
import 'package:journi/application/use_cases/user_use_cases.dart';

abstract class UserService {
  Future<Result<User>> register(RegisterUserCommand cmd);
  Future<Result<User>> authenticate(AuthenticateUserCommand cmd);
  Future<Result<User?>> getById(String id);
  Future<Result<Unit>> deleteById(String id);
  Stream<List<User>> watchAll();
}

class DefaultUserService implements UserService {
  final RegisterUserUseCase _register;
  final AuthenticateUserUseCase _auth;
  final GetUserByIdUseCase _get;
  final DeleteUserUseCase _del;
  final ListUsersUseCase _watch;

  DefaultUserService(UserRepository repo)
      : _register = RegisterUserUseCase(repo),
        _auth = AuthenticateUserUseCase(repo),
        _get = GetUserByIdUseCase(repo),
        _del = DeleteUserUseCase(repo),
        _watch = ListUsersUseCase(repo);

  @override
  Future<Result<User>> register(RegisterUserCommand cmd) => _register(cmd);

  @override
  Future<Result<User>> authenticate(AuthenticateUserCommand cmd) => _auth(cmd);

  @override
  Future<Result<User?>> getById(String id) => _get(id);

  @override
  Future<Result<Unit>> deleteById(String id) => _del(id);

  @override
  Stream<List<User>> watchAll() => _watch();
}

DefaultUserService makeUserService(UserRepository repo) =>
    DefaultUserService(repo);
