import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repository/backup_data_repository.dart';
import 'backup_cubit.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  late final BackupCubit _cubit;
  final _secretController = TextEditingController();
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _cubit = BackupCubit(context.read<BackupRepository>());
  }

  @override
  void dispose() {
    _cubit.close();
    _secretController.dispose();
    super.dispose();
  }

  // ─── accent color (đồng bộ với app) ──────────────────────────────────────
  static const _accent = Color(0xFF6B7FD4);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<BackupCubit, BackupState>(
        listenWhen: (prev, curr) => curr.status != BackupStatus.loading,
        listener: (context, state) {
          if (state.status == BackupStatus.success &&
              state.successMessage != null) {
            _showResultDialog(
              context,
              isSuccess: true,
              message: state.successMessage!,
            );
          } else if (state.status == BackupStatus.failed &&
              state.errorMessage != null) {
            _showResultDialog(
              context,
              isSuccess: false,
              message: state.errorMessage!,
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF5F6FA),
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 20,
            title: const Text(
              'Backup & Restore',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ),
          body: BlocBuilder<BackupCubit, BackupState>(
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Mode selector ──
                    _buildModeSelector(state),
                    const SizedBox(height: 24),

                    // ── Export section ──
                    _buildSectionLabel('Xuất dữ liệu'),
                    const SizedBox(height: 12),
                    _buildExportSection(state),
                    const SizedBox(height: 28),

                    // ── Import section ──
                    _buildSectionLabel('Nhập dữ liệu'),
                    const SizedBox(height: 12),
                    _buildImportSection(state),

                    // ── Server key field (chỉ hiện khi mode = server) ──
                    if (state.mode == BackupMode.server) ...[
                      const SizedBox(height: 28),
                      _buildSectionLabel('Secret key'),
                      const SizedBox(height: 12),
                      _buildSecretKeyField(state),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ─── Mode selector ────────────────────────────────────────────────────────

  Widget _buildModeSelector(BackupState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _modeTab(
            label: 'File cục bộ',
            icon: Icons.folder_outlined,
            value: BackupMode.file,
            active: state.mode,
          ),
          _modeTab(
            label: 'Server',
            icon: Icons.cloud_outlined,
            value: BackupMode.server,
            active: state.mode,
          ),
        ],
      ),
    );
  }

  Widget _modeTab({
    required String label,
    required IconData icon,
    required BackupMode value,
    required BackupMode active,
  }) {
    final isActive = value == active;
    return Expanded(
      child: GestureDetector(
        onTap: () => _cubit.setMode(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: isActive ? Colors.white : Colors.grey.shade500),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ─── Export section ───────────────────────────────────────────────────────

  Widget _buildExportSection(BackupState state) {
    if (state.mode == BackupMode.file) {
      return Column(
        children: [
          _buildActionCard(
            icon: Icons.share_rounded,
            iconColor: _accent,
            title: 'Chia sẻ file backup',
            subtitle: 'Mở share sheet để lưu hoặc gửi file JSON',
            loading: state.isLoading,
            onTap: _cubit.exportAndShare,
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.download_rounded,
            iconColor: const Color(0xFF2E7D32),
            title: 'Lưu vào bộ nhớ máy',
            subtitle: 'Lưu file JSON vào thư mục Downloads / Documents',
            loading: state.isLoading,
            onTap: _cubit.exportToFile,
          ),
        ],
      );
    }

    // mode = server
    return _buildActionCard(
      icon: Icons.cloud_upload_rounded,
      iconColor: _accent,
      title: 'Upload lên server',
      subtitle: 'Dùng secret key để lưu backup trên server',
      loading: state.isLoading,
      onTap: () => _cubit.exportToServer(_secretController.text),
    );
  }

  // ─── Import section ───────────────────────────────────────────────────────

  Widget _buildImportSection(BackupState state) {
    if (state.mode == BackupMode.file) {
      return _buildActionCard(
        icon: Icons.upload_file_rounded,
        iconColor: const Color(0xFFF9A825),
        title: 'Chọn file backup',
        subtitle: 'Chọn file .json từ bộ nhớ máy để nhập dữ liệu',
        loading: state.isLoading,
        onTap: () => _confirmImport(
          context,
          onConfirmed: _cubit.importFromFile,
        ),
      );
    }

    // mode = server
    return _buildActionCard(
      icon: Icons.cloud_download_rounded,
      iconColor: const Color(0xFF00838F),
      title: 'Tải từ server',
      subtitle: 'Dùng secret key để tải backup về và nhập dữ liệu',
      loading: state.isLoading,
      onTap: () => _confirmImport(
        context,
        onConfirmed: () => _cubit.importFromServer(_secretController.text),
      ),
    );
  }

  // ─── Secret key field ─────────────────────────────────────────────────────

  Widget _buildSecretKeyField(BackupState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _secretController,
        obscureText: _obscureKey,
        enabled: !state.isLoading,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Nhập secret key...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon:
          Icon(Icons.key_rounded, color: Colors.grey.shade400, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
            onPressed: () => setState(() => _obscureKey = !_obscureKey),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  // ─── Action card ──────────────────────────────────────────────────────────

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: loading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              loading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: _accent,
                  strokeWidth: 2.5,
                ),
              )
                  : Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade300, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Confirm import dialog ────────────────────────────────────────────────

  Future<void> _confirmImport(
      BuildContext context, {
        required VoidCallback onConfirmed,
      }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nhập dữ liệu',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Dữ liệu sẽ được merge với dữ liệu hiện tại.\n'
              'Bản ghi mới hơn sẽ được giữ lại. Bạn có muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tiếp tục',
                style: TextStyle(
                    color: _accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirmed();
  }

  // ─── Result dialog ────────────────────────────────────────────────────────

  void _showResultDialog(
      BuildContext context, {
        required bool isSuccess,
        required String message,
      }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: isSuccess ? const Color(0xFF2E7D32) : Colors.redAccent,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              isSuccess ? 'Thành công' : 'Thất bại',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK',
                style: TextStyle(
                    color: _accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}