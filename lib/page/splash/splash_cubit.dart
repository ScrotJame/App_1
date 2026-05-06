import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:test_abc/repository/user_repository.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final UserRepository _userRepository;

  SplashCubit(this._userRepository) : super(const SplashState());

  Future<void> init() async {
    if (isClosed) return;
    emit(state.copyWith(status: SplashStatus.loading));

    try {
      await checkAndCreateUser();
    } catch (e, stackTrace) {
      if (isClosed) return;
      emit(state.copyWith(
        status: SplashStatus.error,
        errorMessage: 'Khởi tạo thất bại: $e\n\n$stackTrace',
      ));
    }
  }

  // ─── Kiểm tra và tạo user mặc định ───────────────────────
  Future<void> checkAndCreateUser() async {
    final user = await _userRepository.getCurrentUser();
    if (isClosed) return;

    if (user == null) {
      // Lần đầu mở app → tạo user local
      final newName = _generateDefaultUsername();
      await _userRepository.createLocalUser(newName);
      if (isClosed) return;

      emit(state.copyWith(
        status: SplashStatus.newUser,
        username: newName,
      ));
    } else {
      // Đã có user local → vào thẳng
      emit(state.copyWith(
        status: SplashStatus.returning,
        username: user.username,
      ));
    }
  }

  // ─── Sinh tên mặc định ngẫu nhiên ────────────────────────
  String _generateDefaultUsername() {
    final adjectives = [
      'Swift', 'Brave', 'Calm', 'Bright', 'Cool',
      'Sharp', 'Wise', 'Bold', 'Quick', 'Keen',
    ];
    final nouns = [
      'Panda', 'Fox', 'Hawk', 'Wolf', 'Bear',
      'Eagle', 'Tiger', 'Lion', 'Deer', 'Owl',
    ];

    final adj = (adjectives..shuffle()).first;
    final noun = (nouns..shuffle()).first;
    final number = DateTime.now().millisecondsSinceEpoch % 1000;

    return '$adj$noun$number';
  }
}