part of 'profile_cubit.dart';

class ProfileState extends Equatable {
  final ProfileStatus status;
  final UsersEntrieData? data;
  final String? errorMessage;

  /// Đang lưu username hoặc avatar
  final bool isSaving;

  /// Path ảnh avatar local (null = dùng asset mặc định)
  final String? avatarPath;
  final int? gems;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.data,
    this.errorMessage,
    this.isSaving = false,
    this.avatarPath,
    this.gems
  });

  ProfileState copyWith({
    ProfileStatus? status,
    UsersEntrieData? data,
    String? errorMessage,
    bool? isSaving,
    String? avatarPath,
    bool clearAvatarPath = false,
    int? gems,
  }) {
    return ProfileState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      isSaving: isSaving ?? this.isSaving,
      avatarPath: clearAvatarPath ? null : (avatarPath ?? this.avatarPath),
      gems: gems ?? this.gems,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage, isSaving, avatarPath, gems];
}
