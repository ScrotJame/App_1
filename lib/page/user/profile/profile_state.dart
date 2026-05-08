part of 'profile_cubit.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final UsersEntrieData? data;
  final String? errorMessage;

  /// Đang lưu username hoặc avatar
  final bool isSaving;

  /// Path ảnh avatar local (null = dùng asset mặc định)
  final String? avatarPath;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.data,
    this.errorMessage,
    this.isSaving = false,
    this.avatarPath,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    UsersEntrieData? data,
    String? errorMessage,
    bool? isSaving,
    String? avatarPath,
    bool clearAvatarPath = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      isSaving: isSaving ?? this.isSaving,
      avatarPath: clearAvatarPath ? null : (avatarPath ?? this.avatarPath),
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage, isSaving, avatarPath];
}