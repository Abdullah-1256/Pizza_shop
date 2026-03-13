import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<Failure, UserEntity>> signInWithOtp({
    required String email,
    required String otp,
  });

  Future<Either<Failure, Unit>> sendOtpToEmail(String email);

  Future<Either<Failure, UserEntity>> signInWithGoogle();

  Future<Either<Failure, UserEntity?>> getCurrentUser();

  Future<Either<Failure, Unit>> signOut();

  Future<Either<Failure, Unit>> resetPassword(String email);

  Stream<UserEntity?> get authStateChanges;
}
