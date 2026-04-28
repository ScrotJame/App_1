part of 'profile_cubit.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final UsersEntrieData? data;
  final String? errorMessage;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.data,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    UsersEntrieData? data,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}