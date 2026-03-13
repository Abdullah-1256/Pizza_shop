import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpWithEmail implements UseCase<UserEntity, SignUpWithEmailParams> {
  final AuthRepository repository;

  SignUpWithEmail(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpWithEmailParams params) {
    return repository.signUpWithEmailAndPassword(
      email: params.email,
      password: params.password,
      name: params.name,
    );
  }
}

class SignUpWithEmailParams {
  final String email;
  final String password;
  final String name;

  SignUpWithEmailParams({
    required this.email,
    required this.password,
    required this.name,
  });
}
