part of 'profile_cubit.dart';

enum ProfileStatus { initial, loading, loaded, error }

class BadgeItem {
  final String id;
  final String name;
  final String icon;
  final bool isUnlocked;

  const BadgeItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.isUnlocked,
  });
}

class LearningCourse {
  final String id;
  final String title;
  final double progress;
  final int current;
  final int total;
  final String unit;
  final int todayGain;

  const LearningCourse({
    required this.id,
    required this.title,
    required this.progress,
    required this.current,
    required this.total,
    required this.unit,
    required this.todayGain,
  });
}

class ProfileData {
  final String name;
  final String level;
  final String avatarUrl;
  final int streak;
  final int totalPoints;
  final List<LearningCourse> courses;
  final List<BadgeItem> badges;

  const ProfileData({
    required this.name,
    required this.level,
    required this.avatarUrl,
    required this.streak,
    required this.totalPoints,
    required this.courses,
    required this.badges,
  });
}

class ProfileState extends Equatable {
  final ProfileStatus status;
  final ProfileData? data;
  final String? errorMessage;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.data,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileData? data,
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