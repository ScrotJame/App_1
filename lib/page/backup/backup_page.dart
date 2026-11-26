import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../commons/enums.dart';
import '../../config/app_config.dart';
import '../../components/login_bottom_sheet.dart';
import '../../cubit/auth_cubit.dart';
import '../../generated/l10n.dart';
import '../../repository/backup_data_repository.dart';
import '../../repository/vocabulary_repository.dart';
import '../../service/alarm_service.dart';
import 'backup_cubit.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  late final BackupCubit _cubit;

  @override
  void initState() {
    super.initState();
    final vocabulary = context.read<VocabularyRepository>();
    _cubit = BackupCubit(
      context.read<BackupRepository>(),
      onImported: () => AlarmService.syncReviewReminder(vocabulary),
    );
  }

  @override
  void dispose() {
    _cubit.close();
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
            title: Text(
              S.of(context).save_data,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ),
          body: BlocBuilder<BackupCubit, BackupState>(
            builder: (context, backupState) {
              return BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Mode selector ──
                        if (AppConfig.cloudEnabled) ...[
                          _buildModeSelector(backupState),
                          const SizedBox(height: 24),
                        ],

                        // ── Auth banner (chỉ hiện khi mode = server) ──
                        if (backupState.mode == BackupMode.server) ...[
                          _buildAuthSection(authState),
                          const SizedBox(height: 20),
                        ],

                        // ── Export section ──
                        _buildSectionLabel(S.of(context).backup_export_section),
                        const SizedBox(height: 12),
                        _buildExportSection(backupState, authState),
                        const SizedBox(height: 28),

                        // ── Import section ──
                        _buildSectionLabel(S.of(context).backup_import_section),
                        const SizedBox(height: 12),
                        _buildImportSection(backupState, authState),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            S.of(context).backup_scope_note,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // ─── Auth section ─────────────────────────────────────────────────────────

  Widget _buildAuthSection(AuthState authState) {
    if (authState.isAuthenticated) {
      return _buildAuthenticatedBanner(authState);
    }
    return _buildLoginPromptBanner();
  }

  Widget _buildAuthenticatedBanner(AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accent.withValues(alpha: 0.08),
            _accent.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // ── Avatar ──
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: authState.photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      authState.photoUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildDefaultAvatar(authState),
                    ),
                  )
                : _buildDefaultAvatar(authState),
          ),
          const SizedBox(width: 14),
          // ── Info ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authState.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                if (authState.displayEmail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    authState.displayEmail!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // ── Connected badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32), size: 14),
                const SizedBox(width: 4),
                Text(
                  S.of(context).backup_connected,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(AuthState authState) {
    final initial = authState.displayName.isNotEmpty
        ? authState.displayName[0].toUpperCase()
        : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _accent,
        ),
      ),
    );
  }

  Widget _buildLoginPromptBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.08),
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
              color: Colors.amber.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_open_rounded, color: Colors.amber),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).backup_not_connected,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  S.of(context).backup_login_to_cloud,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => LoginBottomSheet.show(context),
            child: Text(
              S.of(context).backup_sign_in,
              style: const TextStyle(fontWeight: FontWeight.w700, color: _accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequiredCard({
    required IconData icon,
    required Color iconColor,
    required String title,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => LoginBottomSheet.show(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                  color: iconColor.withValues(alpha: 0.12),
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
                      S.of(context).backup_login_for_account_cloud,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.login_rounded, color: _accent, size: 22),
            ],
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _modeTab(
            label: S.of(context).backup_mode_file,
            icon: Icons.folder_outlined,
            value: BackupMode.file,
            active: state.mode,
          ),
          _modeTab(
            label: S.of(context).backup_mode_server,
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

  Widget _buildExportSection(BackupState state, AuthState authState) {
    if (state.mode == BackupMode.file) {
      return Column(
        children: [
          _buildActionCard(
            icon: Icons.share_rounded,
            iconColor: _accent,
            title: S.of(context).backup_share_title,
            subtitle: S.of(context).backup_share_subtitle,
            loading: state.isLoading,
            onTap: _cubit.exportAndShare,
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.download_rounded,
            iconColor: const Color(0xFF2E7D32),
            title: S.of(context).backup_save_title,
            subtitle: S.of(context).backup_save_subtitle,
            loading: state.isLoading,
            onTap: _cubit.exportToFile,
          ),
        ],
      );
    }

    // mode = server
    if (authState.isAuthenticated) {
      // Đã đăng nhập → dùng backupKey tự động
      return _buildActionCard(
        icon: Icons.cloud_upload_rounded,
        iconColor: _accent,
        title: S.of(context).backup_upload_title,
        subtitle: S.of(context).backup_upload_subtitle,
        loading: state.isLoading,
        onTap: () => _cubit.exportToServer(),
      );
    }

    return _buildLoginRequiredCard(
      icon: Icons.cloud_upload_rounded,
      iconColor: _accent,
      title: S.of(context).backup_login_to_backup,
    );
  }

  // ─── Import section ───────────────────────────────────────────────────────

  Widget _buildImportSection(BackupState state, AuthState authState) {
    if (state.mode == BackupMode.file) {
      return _buildActionCard(
        icon: Icons.upload_file_rounded,
        iconColor: const Color(0xFFF9A825),
        title: S.of(context).backup_pick_file_title,
        subtitle: S.of(context).backup_pick_file_subtitle,
        loading: state.isLoading,
        onTap: () => _confirmImport(
          context,
          onConfirmed: _cubit.importFromFile,
        ),
      );
    }

    // mode = server
    if (authState.isAuthenticated) {
      // Đã đăng nhập → dùng backupKey tự động
      return _buildActionCard(
        icon: Icons.cloud_download_rounded,
        iconColor: const Color(0xFF00838F),
        title: S.of(context).backup_download_title,
        subtitle: S.of(context).backup_download_subtitle,
        loading: state.isLoading,
        onTap: () => _confirmImport(
          context,
          onConfirmed: () =>
              _cubit.importFromServer(),
        ),
      );
    }

    return _buildLoginRequiredCard(
      icon: Icons.cloud_download_rounded,
      iconColor: const Color(0xFF00838F),
      title: S.of(context).backup_login_to_restore,
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
                color: Colors.black.withValues(alpha: 0.05),
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
                  color: iconColor.withValues(alpha: 0.12),
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
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(S.of(ctx).backup_import_confirm_title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(S.of(ctx).backup_import_confirm_message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.of(ctx).cancel, style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.of(ctx).backup_continue,
                style: const TextStyle(color: _accent, fontWeight: FontWeight.w700)),
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
              isSuccess
                  ? S.of(ctx).backup_result_success
                  : S.of(ctx).backup_result_failed,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(ctx).backup_ok,
                style: const TextStyle(
                    color: _accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
