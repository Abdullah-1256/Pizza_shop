import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmail implements UseCase<UserEntity, SignInWithEmailParams> {
  final AuthRepository repository;

  SignInWithEmail(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignInWithEmailParams params) {
    return repository.signInWithEmailAndPassword(
      email: params.email,
      password: params.password,
    );
  }
}

class SignInWithEmailParams {
  final String email;
  final String password;

  SignInWithEmailParams({required this.email, required this.password});
}
