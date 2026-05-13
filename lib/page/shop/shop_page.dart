import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_abc/commons/app_images.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/helper/format_helper.dart';
import 'package:test_abc/ultis/extension/label_extension.dart';
import '../../extentions/icon_extension.dart';
import '../../models/items_entity.dart';
import '../../repository/shop_repository.dart';
import '../widgets/app_gradient_header.dart';
import 'shop_cubit.dart';

const _kBg = Color(0xFFF2F3F7);
const _kCard = Colors.white;
const _kGemColor = Color(0xFFFFB300);
const _kAccent = Color(0xFF42C8F5);
const _kDark = Color(0xFF1A1A2E);
const _kGrey = Color(0xFF9E9E9E);

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late ShopCubit _cubit;
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _cubit = ShopCubit(context.read<ShopRepository>());
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _cubit.close();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Handlers ─────────────────────────────────────────────────

  void _handleSuccess(String? itemId) {
    final item = _cubit.state.filteredItems.firstWhere(
          (e) => e.id == itemId,
      orElse: () => ItemsEntity(name: itemId),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Mua "${item.name ?? itemId}" thành công!'),
        backgroundColor: const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _cubit.reset();
  }

  void _handleError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Lỗi không xác định'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _cubit.reset();
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        body: BlocListener<ShopCubit, ShopState>(
          listener: (context, state) {
            if (state.status == ShopStatus.success) {
              _handleSuccess(state.purchasedItemId);
            } else if (state.status == ShopStatus.error) {
              _handleError(state.errorMessage);
            }
          },
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AppGradientHeader(
      height: 145,
      child: Padding(
        padding: const EdgeInsets.only(top: 28),
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _buildBackButton(),
                ),
                Expanded(
                  child: Text(
                    S.of(context).shop.capitalizeWords(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
            const SizedBox(height: 8),
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<ShopCubit, ShopState>(
      builder: (context, state) {
        // ── Loading lần đầu (chưa có items) ──
        if (state.status == ShopStatus.loading && state.filteredItems.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        // ── Lỗi và chưa có items ──
        if (state.status == ShopStatus.error && state.filteredItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.white70, size: 48),
                const SizedBox(height: 12),
                Text(
                  state.errorMessage ?? 'Không thể tải dữ liệu',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _cubit.reset,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        // ── Không có items ──
        if (state.filteredItems.isEmpty) {
          return const Center(
            child: Text(
              'Chưa có sản phẩm nào',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          );
        }

        // ── Danh sách items ──
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: state.filteredItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _ItemCard(item: state.filteredItems[index]),
          ),
        );
      },
    );
  }
}

// ─── Item Card ───────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final ItemsEntity item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShopCubit, ShopState>(
      builder: (context, state) {
        final isLoading = state.status == ShopStatus.loading &&
            state.purchasedItemId == item.id;
        final outOfStock = (item.stock ?? 0) <= 0;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildCardBody(context, isLoading, outOfStock),
              if (item.stock != null)
                _buildDescriptionBar(outOfStock),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardBody(BuildContext context, bool isLoading, bool outOfStock) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          // Icon / ảnh sản phẩm
          _buildItemIcon(),
          const SizedBox(width: 12),
          // Thông tin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name ?? 'Sản phẩm',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E2E2E),
                  ),
                ),
                  const SizedBox(height: 4),
                  Text(
                    item.description ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          // Nút mua
          _BuyButton(
            price: item.price ?? 0,
            isLoading: isLoading,
            disabled: outOfStock,
            onTap: () => context.read<ShopCubit>().purchase(item),
          ),
        ],
      ),
    );
  }

  Widget _buildItemIcon() {
    final icon = item.icon;

    if (icon != null && icon.isNotEmpty) {
      if (icon.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            icon,
            width: 56, height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _defaultIcon(),
          ),
        );
      }

      if (icon.startsWith('assets/')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            icon,
            width: 56, height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _defaultIcon(),
          ),
        );
      }

      return Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(
          icon.toIconData(),
          width: 28,
          height: 28,
        ),
      );
    }

    return _defaultIcon();
  }

  Widget _defaultIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.shopping_bag_outlined, size: 28, color: Color(0xFFBDBDBD)),
    );
  }

  Widget _buildDescriptionBar( bool outOfStock) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: Text(
        outOfStock ? 'Hết hàng' : 'Còn ${item.stock} sản phẩm',
        style: TextStyle(
          fontSize: 12,
          color: outOfStock ? Colors.redAccent : const Color(0xFF43A047),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Buy Button ──────────────────────────────────────────────────────────────

class _BuyButton extends StatelessWidget {
  final num price;
  final bool isLoading;
  final bool disabled;
  final VoidCallback onTap;

  const _BuyButton({
    required this.price,
    required this.isLoading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = !isLoading && !disabled;

    return GestureDetector(
      onTap: canTap ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.grey[300]
              : isLoading
              ? Colors.grey[400]
              : const Color(0xFF5BB75B),
          borderRadius: BorderRadius.circular(30),
        ),
        child: isLoading
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : Row(
              children: [
                Image.asset(AppImages.imgGem, width: 12, height: 12,),
                const SizedBox(width: 4,),
                Text(
                          disabled ? 'Hết hàng' : FormatHelper.formatPrice(price),
                          style: TextStyle(
                color: disabled ? Colors.grey[600] : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                          ),
                        ),
              ],
            ),
      ),
    );
  }
}