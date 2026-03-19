import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../../../widgets/product_card.dart';
import '../../product/product_form_screen.dart';

/// Панель инвентаря — открывается после анимации холодильника
class InventoryPanel extends StatefulWidget {
  const InventoryPanel({super.key});

  @override
  State<InventoryPanel> createState() => _InventoryPanelState();
}

class _InventoryPanelState extends State<InventoryPanel> {
  ProductCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final products = provider.products;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.borderLight.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ─── Заголовок ───
          _PanelHeader(total: products.length),

          // ─── Категории (горизонтальный скролл) ───
          _CategoryFilter(
            selected: _selectedCategory,
            onSelect: (cat) {
              setState(() => _selectedCategory = cat);
              provider.setFilter(cat);
            },
          ),

          // ─── Статистика-строка ───
          _StatsRow(provider: provider),

          // ─── Список продуктов ───
          Expanded(
            child: products.isEmpty
                ? _EmptyInventory()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: products.length,
                    itemBuilder: (ctx, i) => ProductCard(
                      product: products[i],
                      index: i,
                      onTap: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => ProductFormScreen(
                            product: products[i],
                          ),
                        ),
                      ).then((_) => provider.loadProducts()),
                      onDelete: () => _confirmDelete(ctx, products[i]),
                    ),
                  ),
          ),
        ],
      ),
    )
        .animate()
        .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOut)
        .fadeIn(duration: 400.ms);
  }

  void _confirmDelete(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Удалить?',
            style: GoogleFonts.exo2(color: AppColors.textPrimary)),
        content: Text('«${product.name}» будет удалён.',
            style: GoogleFonts.nunito(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProductProvider>().deleteProduct(product);
            },
            child: Text('Удалить', style: TextStyle(color: AppColors.expired)),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final int total;
  const _PanelHeader({required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Drag handle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'ИНВЕНТАРЬ',
                  style: GoogleFonts.exo2(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  '$total предметов',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Кнопка добавить
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductFormScreen()),
            ).then((_) => context.read<ProductProvider>().loadProducts()),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withOpacity(0.4)),
              ),
              child: Icon(Icons.add_rounded, color: AppColors.accent, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final ProductCategory? selected;
  final ValueChanged<ProductCategory?> onSelect;

  const _CategoryFilter({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        children: [
          // Кнопка "Все"
          _CatChip(
            label: 'Все',
            icon: '🔍',
            isSelected: selected == null,
            onTap: () => onSelect(null),
          ),
          ...ProductCategory.values.map((cat) => _CatChip(
                label: cat.label,
                icon: cat.icon,
                isSelected: selected == cat,
                onTap: () => onSelect(cat == selected ? null : cat),
              )),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label, icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CatChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.accent.withOpacity(0.2) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color:
                      isSelected ? AppColors.accent : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final ProductProvider provider;
  const _StatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          _StatChip(
            count: provider.freshProducts.length,
            label: 'свежих',
            color: AppColors.fresh,
          ),
          const SizedBox(width: 8),
          _StatChip(
            count: provider.warningProducts.length,
            label: 'скоро',
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          _StatChip(
            count: provider.expiredProducts.length,
            label: 'просрочено',
            color: AppColors.expired,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatChip({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: GoogleFonts.exo2(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📭', style: const TextStyle(fontSize: 48))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 1500.ms),
          const SizedBox(height: 16),
          Text('Холодильник пуст',
              style:
                  GoogleFonts.exo2(color: AppColors.textMuted, fontSize: 16)),
          const SizedBox(height: 6),
          Text('Добавьте продукты через сканер\nили кнопку «+»',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.nunito(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
