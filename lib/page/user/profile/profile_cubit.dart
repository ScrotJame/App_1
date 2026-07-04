import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:test_abc/database/app_db.dart';

import '../../../commons/enums.dart';
import '../../../commons/user_sesion.dart';
import '../../../repository/user_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserRepository _userRepository;
  final _picker = ImagePicker();
  StreamSubscription<UsersEntrieData>? _userSub;
  
  ProfileCubit(this._userRepository) : super(const ProfileState()) {
    _watchUser();
  }
  // ─── Load ─────────────────────────────────────────────────────────

  void _watchUser() {
    final userKey = UserSession.instance.dbUserKey;
    _userSub = _userRepository.watchUser(userKey).listen(
          (row) => emit(state.copyWith(data: row)),
    );
  }
  Future<void> loadProfile() async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      await _userRepository.syncStreak();
      final user = await _userRepository.getCurrentUser();

      if (user == null) {
        emit(state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Không tìm thấy user',
          isSaving: false,
        ));
        return;
      }

      emit(state.copyWith(
        status: ProfileStatus.loaded,
        data: user,
        avatarPath: user.avatar,
        isSaving: false,
      ));
      UserSession.instance.syncFromUser(user);

    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
        isSaving: false,
      ));
    }
  }

  void refresh() => loadProfile();

  // ─── Update username ───────────────────────────────────────────────

  Future<bool> updateUsername(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed == state.data?.username) return true;

    emit(state.copyWith(isSaving: true));
    try {
      final success = await _userRepository.updateUser(
        UsersEntrieCompanion(username: Value(trimmed)),
      );
      if (success) {
        final updated = state.data?.copyWith(username: trimmed);
        emit(state.copyWith(isSaving: false, data: updated));
      } else {
        emit(state.copyWith(isSaving: false));
      }
      return success;
    } catch (_) {
      emit(state.copyWith(isSaving: false));
      return false;
    }
  }

  // ─── Update avatar ─────────────────────────────────────────────────

  /// Mở thư viện ảnh → copy vào thư mục app → lưu path vào DB.
  Future<void> pickAndSaveAvatar() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;

    emit(state.copyWith(isSaving: true));
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
      final destPath = p.join(appDir.path, fileName);

      await File(picked.path).copy(destPath);

      final success = await _userRepository.updateUser(
        UsersEntrieCompanion(avatar: Value(destPath)),
      );

      final check = await _userRepository.getCurrentUser();

      await loadProfile();
    } catch (e, stack) {
      debugPrint('$stack');
      emit(state.copyWith(isSaving: false));
    }
  }

  @override
  Future<void> close() {
    _userSub?.cancel();
    return super.close();
  }
}
