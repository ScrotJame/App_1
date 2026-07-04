part of 'splash_cubit.dart';

const _absent = Object();

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
    // Dùng Object? + sentinel để phân biệt "không truyền" vs "truyền null"
    Object? username = _absent,
    Object? errorMessage = _absent,
  }) {
    return SplashState(
      status: status ?? this.status,
      username: username == _absent ? this.username : username as String?,
      errorMessage: errorMessage == _absent ? this.errorMessage : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, username, errorMessage];
}
