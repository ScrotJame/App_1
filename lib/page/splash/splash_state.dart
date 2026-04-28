part of 'splash_cubit.dart';

enum SplashStatus { initial, loading, newUser, returning, error }

class SplashState extends Equatable {
  final SplashStatus status;
  final String? username;
  final String? errorMessage;

  const SplashState({
    this.status = SplashStatus.initial,
    this.username,
    this.errorMessage,
  });

  SplashState copyWith({
    SplashStatus? status,
    String? username,
    String? errorMessage,
  }) {
    return SplashState(
      status: status ?? this.status,
      username: username ?? this.username,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, username, errorMessage];
}