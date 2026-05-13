import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../commons/app_images.dart';
import '../../../helper/format_helper.dart';
import '../profile/profile_cubit.dart';
import 'inventory_cubit.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
const _kBg = Color(0xFFF2F3F7);
const _kCard = Colors.white;
const _kGemColor = Color(0xFFFFB300);
const _kAccent = Color(0xFF42C8F5);
const _kDark = Color(0xFF1A1A2E);
const _kGrey = Color(0xFF9E9E9E);

// Màu accent cho từng category
const _kCategoryColors = <ItemCategory, Color>{
  ItemCategory.all: Color(0xFF42C8F5),
  ItemCategory.weapon: Color(0xFFE53935),
  ItemCategory.armor: Color(0xFF1E88E5),
  ItemCategory.potion: Color(0xFF8E24AA),
  ItemCategory.food: Color(0xFF43A047),
  ItemCategory.quest: Color(0xFFFFB300),
  ItemCategory.companion: Color(0xFFFF7043),
};

// Icon cho từng category
const _kCategoryIcons = <ItemCategory, IconData>{
  ItemCategory.all: Icons.apps_rounded,
  ItemCategory.weapon: Icons.sports_martial_arts_rounded,
  ItemCategory.armor: Icons.shield_rounded,
  ItemCategory.potion: Icons.local_drink_rounded,
  ItemCategory.food: Icons.restaurant_rounded,
  ItemCategory.quest: Icons.key_rounded,
  ItemCategory.companion: Icons.egg_alt_rounded,
};

// Label cho từng category
const _kCategoryLabels = <ItemCategory, String>{
  ItemCategory.all: 'All',
  ItemCategory.weapon: 'Weapon',
  ItemCategory.armor: 'Armor',
  ItemCategory.potion: 'Potion',
  ItemCategory.food: 'Food',
  ItemCategory.quest: 'Quest',
  ItemCategory.companion: 'Companion',
};

class InventoryPage extends StatefulWidget {
  final int gems;

  const InventoryPage({super.key, this.gems = 0});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  late final InventoryCubit _cubit;
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _cubit = InventoryCubit();
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
        body: SafeArea(
          child: BlocBuilder<InventoryCubit, InventoryState>(
            builder: (context, state) {
              return Column(
                children: [
                  _buildTopBar(context, state),
                  _buildSearchBar(),
                  const SizedBox(height: 8),
                  _buildCategoryFilter(state),
                  const SizedBox(height: 4),
                  Expanded(child: _buildBody(state)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ─── Top bar ──────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, InventoryState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _kDark, size: 20),
          ),

          // Title
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

          // Gem badge
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kGemColor.withOpacity(0.2),
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

  // ─── Search bar ────────────────────────────────────────────────────

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
          style: GoogleFonts.balooBhai2(
              fontSize: 14, color: _kDark),
          decoration: InputDecoration(
            hintText: 'Search items...',
            hintStyle: GoogleFonts.balooBhai2(
                fontSize: 14, color: _kGrey),
            prefixIcon:
            const Icon(Icons.search_rounded, color: _kGrey, size: 20),
            suffixIcon: ListenableBuilder(
              listenable: _searchCtrl,
              builder: (_, __) =>
              _searchCtrl.text.isNotEmpty
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

  // ─── Category filter chips ──────────────────────────────────────────

  Widget _buildCategoryFilter(InventoryState state) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: ItemCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = ItemCategory.values[i];
          final isSelected = state.selectedCategory == cat;
          final color = _kCategoryColors[cat]!;
          return GestureDetector(
            onTap: () => _cubit.selectCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? color.withOpacity(0.35)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _kCategoryIcons[cat],
                    size: 14,
                    color: isSelected ? Colors.white : _kGrey,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _kCategoryLabels[cat]!,
                    style: GoogleFonts.balooBhai2(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : _kGrey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Body ──────────────────────────────────────────────────────────

  Widget _buildBody(InventoryState state) {
    if (state.status == InventoryStatus.loading ||
        state.status == InventoryStatus.initial) {
      return const Center(
        child: CircularProgressIndicator(color: _kAccent),
      );
    }

    if (state.status == InventoryStatus.error) {
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
            Icon(Icons.inventory_2_outlined, size: 56,
                color: _kGrey.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              'No items found',
              style: GoogleFonts.balooBhai2(
                  fontSize: 16, color: _kGrey),
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
        itemBuilder: (_, i) =>
            _InventoryItemCard(
              item: items[i],
              onAction: () => _cubit.performAction(items[i]),
            ),
      ),
    );
  }

  // ─── Helper ────────────────────────────────────────────────────────


}

// ─── Item Card ────────────────────────────────────────────────────────────────

class _InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onAction;

  const _InventoryItemCard({
    required this.item,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = _kCategoryColors[item.category] ?? _kAccent;

    return Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Item image / placeholder ──
            _buildItemImage(accentColor),
            const SizedBox(height: 10),

            // ── Item name ──
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.balooBhai2(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _kDark,
              ),
            ),

            // ── Category label ──
            Text(
              _kCategoryLabels[item.category] ?? '',
              style: GoogleFonts.balooBhai2(
                fontSize: 12,
                color: _kGrey,
              ),
            ),
            const SizedBox(height: 8),

            // ── Action button ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kDark,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  textStyle: GoogleFonts.balooBhai2(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(item.action),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(Color accentColor) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accentColor.withOpacity(0.15),
        border: Border.all(color: accentColor.withOpacity(0.4), width: 2),
      ),
      child: item.imagePath != null
          ? ClipOval(
        child: Image.asset(
          item.imagePath!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon(accentColor),
        ),
      )
          : _fallbackIcon(accentColor),
    );
  }

  Widget _fallbackIcon(Color color) {
    return Center(
      child: Icon(
        _kCategoryIcons[item.category] ?? Icons.inventory_2_rounded,
        color: color,
        size: 32,
      ),
    );
  }
}