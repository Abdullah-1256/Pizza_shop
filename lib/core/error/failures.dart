import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final StackTrace? stackTrace;

  const Failure(this.message, [this.stackTrace]);

  @override
  List<Object?> get props => [message, stackTrace];

  @override
  String toString() => 'Failure(message: $message, stackTrace: $stackTrace)';
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}

class CacheFailure extends Failure {
  const CacheFailure(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String message = 'Unauthorized', StackTrace? stackTrace])
      : super(message, stackTrace);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Not Found', StackTrace? stackTrace])
      : super(message, stackTrace);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([String message = 'Request Timeout', StackTrace? stackTrace])
      : super(message, stackTrace);
}

class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'Unknown Error', StackTrace? stackTrace])
      : super(message, stackTrace);
}
