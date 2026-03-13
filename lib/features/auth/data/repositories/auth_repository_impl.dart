import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.fold((failure) => Left(failure), (user) async {
        // Create/update profile in database
        await SupabaseService.createOrUpdateProfile(
          userId: user.id,
          email: user.email ?? '',
          name: user.name,
        );
        return Right(user);
      });
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final result = await remoteDataSource.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );
      return result.fold((failure) => Left(failure), (user) async {
        // Create profile in database
        await SupabaseService.createOrUpdateProfile(
          userId: user.id,
          email: user.email ?? '',
          name: user.name,
        );
        return Right(user);
      });
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final result = await remoteDataSource.signInWithOtp(
        email: email,
        otp: otp,
      );
      return result.fold((failure) => Left(failure), (user) async {
        // Create/update profile in database
        await SupabaseService.createOrUpdateProfile(
          userId: user.id,
          email: user.email ?? '',
          name: user.name,
        );
        return Right(user);
      });
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendOtpToEmail(String email) async {
    try {
      return await remoteDataSource.sendOtpToEmail(email);
    } catch (e) {
      return Left(ServerFailure('Failed to send OTP'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final result = await remoteDataSource.signInWithGoogle();
      return result.fold((failure) => Left(failure), (user) async {
        // Create/update profile in database
        await SupabaseService.createOrUpdateProfile(
          userId: user.id,
          email: user.email ?? '',
          name: user.name,
        );
        return Right(user);
      });
    } catch (e) {
      return Left(ServerFailure('Google sign in failed'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      return await remoteDataSource.getCurrentUser();
    } catch (e) {
      return Left(ServerFailure('Failed to get current user'));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      return await remoteDataSource.signOut();
    } catch (e) {
      return Left(ServerFailure('Failed to sign out'));
    }
  }

  @override
  Future<Either<Failure, Unit>> resetPassword(String email) async {
    try {
      return await remoteDataSource.resetPassword(email);
    } catch (e) {
      return Left(ServerFailure('Failed to send password reset email'));
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    // This would need to be implemented with a stream from Supabase
    // For now, we'll return an empty stream
    return Stream.empty();
  }
}
