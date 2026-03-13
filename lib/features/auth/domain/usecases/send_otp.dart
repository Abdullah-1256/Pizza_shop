import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class SendOtp implements UseCase<Unit, SendOtpParams> {
  final AuthRepository repository;

  SendOtp(this.repository);

  @override
  Future<Either<Failure, Unit>> call(SendOtpParams params) {
    return repository.sendOtpToEmail(params.email);
  }
}

class SendOtpParams {
  final String email;

  SendOtpParams({required this.email});
}
