import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:test_abc/database/app_db.dart';
import '../../../repository/user_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserRepository _userRepository;

  ProfileCubit(this._userRepository) : super(const ProfileState());

  Future<void> loadProfile() async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final user = await _userRepository.getCurrentUser();
      if (user == null) {
        emit(state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Không tìm thấy user',
        ));
        return;
      }
      emit(state.copyWith(status: ProfileStatus.loaded, data: user));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void refresh() => loadProfile();
}