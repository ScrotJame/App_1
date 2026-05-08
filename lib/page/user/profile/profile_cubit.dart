import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:test_abc/database/app_db.dart';

import '../../../repository/user_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserRepository _userRepository;
  final _picker = ImagePicker();

  ProfileCubit(this._userRepository) : super(const ProfileState());

  // ─── Load ─────────────────────────────────────────────────────────

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

      // Khôi phục avatarPath đã lưu (nếu có trong DB hoặc local)
      final savedPath = user.avatar; // thêm field này vào DB nếu chưa có
      emit(state.copyWith(
        status: ProfileStatus.loaded,
        data: user,
        avatarPath: savedPath,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void refresh() => loadProfile();

  // ─── Update username ───────────────────────────────────────────────

  Future<bool> updateUsername(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed == state.data?.username) return true; // không đổi

    emit(state.copyWith(isSaving: true));
    try {
      final success = await _userRepository.updateUser(
        UsersEntrieCompanion(username: Value(trimmed)),
      );

      if (success) {
        // Cập nhật data local ngay, không cần reload từ DB
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
    if (picked == null) return; // user huỷ

    emit(state.copyWith(isSaving: true));
    try {
      // Copy ảnh vào thư mục persistent của app
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
      final destPath = p.join(appDir.path, fileName);
      await File(picked.path).copy(destPath);

      // Lưu path vào DB
      await _userRepository.updateUser(
        UsersEntrieCompanion(avatar: Value(destPath)),
      );

      emit(state.copyWith(isSaving: false, avatarPath: destPath));
    } catch (_) {
      emit(state.copyWith(isSaving: false));
    }
  }
}