import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/ultis/extension/label_extension.dart';
import '../../models/items_entity.dart';
import '../../repository/shop_repository.dart';
import 'shop_cubit.dart';

// ─── Helper format giá ───────────────────────────────────────────────────────

String _formatPrice(num price) {
  final str = price.toInt().toString();
  if (str.length <= 3) return str;
  final buf = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
    buf.write(str[i]);
  }
  return buf.toString();
}

// ─── ShopPage ────────────────────────────────────────────────────────────────

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late ShopCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ShopCubit(context.read<ShopRepository>());
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  // ── Handlers ─────────────────────────────────────────────────

  void _handleSuccess(String? itemId) {
    final item = _cubit.state.items.firstWhere(
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
        backgroundColor: const Color(0xFF5BB75B),
        body: BlocListener<ShopCubit, ShopState>(
          listener: (context, state) {
            if (state.status == ShopStatus.success) {
              _handleSuccess(state.purchasedItemId);
            } else if (state.status == ShopStatus.error) {
              _handleError(state.errorMessage);
            }
          },
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildBackButton(),
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
        if (state.status == ShopStatus.loading && state.items.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        // ── Lỗi và chưa có items ──
        if (state.status == ShopStatus.error && state.items.isEmpty) {
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
        if (state.items.isEmpty) {
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
            itemCount: state.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _ItemCard(item: state.items[index]),
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
              if (item.description != null && item.description!.isNotEmpty)
                _buildDescriptionBar(),
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
                if (item.stock != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    outOfStock ? 'Hết hàng' : 'Còn ${item.stock} sản phẩm',
                    style: TextStyle(
                      fontSize: 12,
                      color: outOfStock ? Colors.redAccent : const Color(0xFF43A047),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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

    // Nếu icon là URL hoặc asset path
    if (icon != null && icon.isNotEmpty) {
      if (icon.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            icon,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _defaultIcon(),
          ),
        );
      }
      // Asset path
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          icon,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultIcon(),
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

  Widget _buildDescriptionBar() {
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
        item.description!,
        style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
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
            : Text(
          disabled ? 'Hết hàng' : 'đ ${_formatPrice(price)}',
          style: TextStyle(
            color: disabled ? Colors.grey[600] : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}