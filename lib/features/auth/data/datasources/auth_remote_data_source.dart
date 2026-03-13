import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthRemoteDataSource {
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
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return Left(ServerFailure('User not found'));
      }

      final user = UserEntity.fromSupabaseUser(response.user!);
      return Right(user);
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user == null) {
        return Left(ServerFailure('Failed to create user'));
      }

      final user = UserEntity.fromSupabaseUser(response.user!);
      return Right(user);
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) return const Right(null);

      return Right(UserEntity.fromSupabaseUser(user));
    } catch (e) {
      return Left(ServerFailure('Failed to get current user'));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await supabaseClient.auth.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('Failed to sign out'));
    }
  }

  @override
  Future<Either<Failure, Unit>> resetPassword(String email) async {
    try {
      await supabaseClient.auth.resetPasswordForEmail(email);
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to send password reset email'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await supabaseClient.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (response.user == null) {
        return Left(ServerFailure('Invalid OTP'));
      }

      final user = UserEntity.fromSupabaseUser(response.user!);
      return Right(user);
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendOtpToEmail(String email) async {
    try {
      await supabaseClient.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
      );
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to send OTP'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final response = await supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConstants.oauthRedirectUrl,
        queryParams: {'access_type': 'offline', 'prompt': 'consent'},
      );

      // Note: OAuth flow is handled by redirect, this method initiates the flow
      // The actual user will be available after redirect callback
      // For now, we'll return a placeholder - actual implementation depends on callback handling
      return Left(ServerFailure('OAuth initiated - handle via callback'));
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Google sign in failed'));
    }
  }
}
