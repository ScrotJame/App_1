import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_abc/commons/enums.dart';

import '../../../commons/app_images.dart';
import '../../../extentions/icon_extension.dart';
import '../../../helper/format_helper.dart';
import '../../../models/entity/item_entity.dart';
import '../../../models/items_entity.dart';
import '../../../repository/inventory_repository.dart';
import '../../widgets/app_gradient_header.dart';
import '../profile/profile_cubit.dart';
import 'inventory_cubit.dart';

const _kBg       = Color(0xFFF2F3F7);
const _kCard     = Colors.white;
const _kGemColor = Color(0xFFFFB300);
const _kAccent   = Color(0xFF42C8F5);
const _kDark     = Color(0xFF1A1A2E);
const _kGrey     = Color(0xFF9E9E9E);

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  late final InventoryCubit _cubit;
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _cubit = InventoryCubit(context.read<InventoryRepository>());
    _searchCtrl = TextEditingController();
    _cubit.loadInventory();
  }

  @override
  void dispose() {
    _cubit.close();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: _kBg,
        body: BlocBuilder<InventoryCubit, InventoryState>(
          builder: (context, state) {
            return Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                Expanded(child: _buildBody(state)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────

  Widget _buildHeader() {
    return AppGradientHeader(
      height: 160,
      child: Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Column(
          children: [
            _buildTopBar(),
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _kDark, size: 20),
          ),
          Expanded(
            child: Text(
              'My Backpack',
              textAlign: TextAlign.center,
              style: GoogleFonts.balooBhai2(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _kDark,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGemColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _kGemColor.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) {
                final gems = state.data?.gems ?? 0;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(AppImages.imgGem, width: 16),
                    const SizedBox(width: 5),
                    Text(
                      FormatHelper.formatNumberPrice(gems),
                      style: GoogleFonts.balooBhai2(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _kDark,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search bar ───────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _cubit.onSearchChanged,
          style: GoogleFonts.balooBhai2(fontSize: 14, color: _kDark),
          decoration: InputDecoration(
            hintText: 'Search items...',
            hintStyle: GoogleFonts.balooBhai2(fontSize: 14, color: _kGrey),
            prefixIcon:
            const Icon(Icons.search_rounded, color: _kGrey, size: 20),
            suffixIcon: ListenableBuilder(
              listenable: _searchCtrl,
              builder: (_, __) => _searchCtrl.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: _kGrey, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  _cubit.clearSearch();
                },
              )
                  : const SizedBox.shrink(),
            ),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────

  Widget _buildBody(InventoryState state) {
    if (state.status == LOADSTATUS.LOADING ||
        state.status == LOADSTATUS.INITAL) {
      return const Center(
        child: CircularProgressIndicator(color: _kAccent),
      );
    }

    if (state.status == LOADSTATUS.FAILED) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(state.errorMessage ?? 'Có lỗi xảy ra'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _cubit.refresh,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final items = state.filteredItems;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 56, color: _kGrey.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              'No items found',
              style: GoogleFonts.balooBhai2(fontSize: 16, color: _kGrey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _kAccent,
      onRefresh: () async => _cubit.refresh(),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.85,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => InventoryItemCard(
          userItem: items[i],
          onTap: (){

          },),
      ),
    );
  }
}

// ─── Item Card ────────────────────────────────────────────────────────────────

class InventoryItemCard extends StatelessWidget {
  final UserItemEntity userItem;
  final VoidCallback? onTap;

  const InventoryItemCard({
    super.key,
    required this.userItem,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final item = userItem.item;
    final isPressed = ValueNotifier<bool>(false);

    return GestureDetector(
      onTapDown: (_) => isPressed.value = true,
      onTapUp: (_) => isPressed.value = false,
      onTapCancel: () => isPressed.value = false,
      onTap: onTap,
      child: ValueListenableBuilder<bool>(
        valueListenable: isPressed,
        builder: (context, pressed, child) {
          return AnimatedScale(
            scale: pressed ? 0.85 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Tối ưu không gian
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ItemImage(assetPath: item?.icon.toIconData()),
                const SizedBox(height: 10),
                Text(
                  item?.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.balooBhai2(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _kDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'x${userItem.quantity ?? 0}',
                  style: GoogleFonts.balooBhai2(
                      fontSize: 12,
                      color: _kGrey,
                      fontWeight: FontWeight.w800
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Tách riêng Widget Image để Flutter không phải rebuild lại logic ảnh khi nhấn Card
class _ItemImage extends StatelessWidget {
  final String? assetPath;
  const _ItemImage({this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _kAccent.withOpacity(0.15),
        border: Border.all(color: _kAccent.withOpacity(0.4), width: 2),
      ),
      child: ClipOval(
        child: assetPath != null
            ? Image.asset(
          assetPath!,
          fit: BoxFit.cover,
          // Tối ưu bộ nhớ: Flutter tự động cache Image.asset
          // nhưng bạn có thể giới hạn kích thước cache nếu ảnh gốc quá lớn
          cacheWidth: 150,
          cacheHeight: 150,
          errorBuilder: (_, __, ___) => const _FallbackIcon(),
        )
            : const _FallbackIcon(),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.inventory_2_rounded, color: _kAccent, size: 32),
    );
  }
}