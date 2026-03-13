import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInWithOtp implements UseCase<UserEntity, SignInWithOtpParams> {
  final AuthRepository repository;

  SignInWithOtp(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignInWithOtpParams params) {
    return repository.signInWithOtp(email: params.email, otp: params.otp);
  }
}

class SignInWithOtpParams {
  final String email;
  final String otp;

  SignInWithOtpParams({required this.email, required this.otp});
}
