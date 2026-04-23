import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(const ProfileState());

  Future<void> loadProfile() async {
    emit(state.copyWith(status: ProfileStatus.loading));

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 800));

      const data = ProfileData(
        name: 'Alex Gardener',
        level: 'Level 24 • Master Planter',
        avatarUrl: 'https://i.pravatar.cc/150?img=12',
        streak: 15,
        totalPoints: 142,
        courses: [
          LearningCourse(
            id: '1',
            title: 'Spanish Vocabulary',
            progress: 0.85,
            current: 1240,
            total: 1500,
            unit: 'words',
            todayGain: 12,
          ),
          LearningCourse(
            id: '2',
            title: 'French Grammar',
            progress: 0.42,
            current: 210,
            total: 500,
            unit: 'lessons',
            todayGain: 3,
          ),
        ],
        badges: [
          BadgeItem(
            id: '1',
            name: 'Early Bird',
            icon: '🏆',
            isUnlocked: true,
          ),
          BadgeItem(
            id: '2',
            name: 'Nurturer',
            icon: '💧',
            isUnlocked: true,
          ),
          BadgeItem(
            id: '3',
            name: 'Polyglot',
            icon: '🧠',
            isUnlocked: true,
          ),
          BadgeItem(
            id: '4',
            name: 'Legend',
            icon: '✨',
            isUnlocked: false,
          ),
        ],
      );

      emit(state.copyWith(status: ProfileStatus.loaded, data: data));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void refresh() => loadProfile();
}