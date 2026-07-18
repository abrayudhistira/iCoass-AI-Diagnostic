import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([this.properties = const <dynamic>[]]);

  final List<dynamic> properties;

  @override
  List<Object?> get props => properties;
}

class ServerFailure extends Failure {
  final String message;

  const ServerFailure(this.message) : super();

  @override
  List<Object?> get props => [message];
}

class CacheFailure extends Failure {}
