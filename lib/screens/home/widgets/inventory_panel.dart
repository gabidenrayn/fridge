import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../../../widgets/product_card.dart';
import '../../product/product_form_screen.dart';

/// Панель инвентаря — открывается после анимации холодильника или морозильника
class InventoryPanel extends StatefulWidget {
  final bool isFreezer;
  final VoidCallback? onClose;

  const InventoryPanel({super.key, required this.isFreezer, this.onClose});

  @override
  State<InventoryPanel> createState() => _InventoryPanelState();
}

class _InventoryPanelState extends State<InventoryPanel> {
  ProductCategory? _selectedCategory;
  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final products =
        widget.isFreezer ? provider.freezerProducts : provider.fridgeProducts;
    final sectionTitle = widget.isFreezer ? 'Морозильник' : 'Холодильник';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dy;
        });
      },
      onVerticalDragEnd: (details) {
        // Если свайпили вниз более чем на 100 пиксельей или скорость > 200 пикселей в сек
        if (_dragOffset > 100 || details.velocity.pixelsPerSecond.dy > 200) {
          widget.onClose?.call();
        } else {
          // Вернуть в исходное положение
          setState(() {
            _dragOffset = 0;
          });
        }
      },
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.panelBg : AppColors.lightPanelBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark
                  ? AppColors.borderLight.withOpacity(0.5)
                  : AppColors.lightBorder.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.accent : AppColors.lightAccent)
                    .withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // ─── Заголовок ───
              _PanelHeader(
                total: products.length,
                sectionTitle: sectionTitle,
                isFreezer: widget.isFreezer,
              ),

              // ─── Категории (горизонтальный скролл) ───
              _CategoryFilter(
                selected: _selectedCategory,
                onSelect: (cat) {
                  setState(() => _selectedCategory = cat);
                  provider.setFilter(cat);
                },
              ),

              // ─── Статистика-строка ───
              _StatsRow(products: products),

              // ─── Список продуктов ───
              Expanded(
                child: products.isEmpty
                    ? _EmptyInventory(isFreezer: widget.isFreezer)
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
        ),
      ),
    )
        .animate()
        .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOut)
        .fadeIn(duration: 400.ms);
  }

  void _confirmDelete(BuildContext context, ProductModel product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Удалить?',
            style: GoogleFonts.exo2(
              color:
                  isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
            )),
        content: Text('«${product.name}» будет удалён.',
            style: GoogleFonts.nunito(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.lightTextSecondary,
            )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена',
                style: TextStyle(
                  color:
                      isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                )),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProductProvider>().deleteProduct(product);
            },
            child: Text('Удалить',
                style: TextStyle(
                  color: isDark ? AppColors.expired : AppColors.lightExpired,
                )),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final int total;
  final String sectionTitle;
  final bool isFreezer;

  const _PanelHeader({
    required this.total,
    required this.sectionTitle,
    required this.isFreezer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                      color: isDark
                          ? AppColors.borderLight
                          : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  sectionTitle.toUpperCase(),
                  style: GoogleFonts.exo2(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.accent : AppColors.lightAccent,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  '$total предметов',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          // Кнопка добавить
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductFormScreen(
                  initialCategory: isFreezer ? ProductCategory.frozen : null,
                ),
              ),
            ).then((_) => context.read<ProductProvider>().loadProducts()),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.accent : AppColors.lightAccent)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isDark ? AppColors.accent : AppColors.lightAccent)
                      .withOpacity(0.4),
                ),
              ),
              child: Icon(Icons.add_rounded,
                  color: isDark ? AppColors.accent : AppColors.lightAccent,
                  size: 20),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.accent : AppColors.lightAccent)
                  .withOpacity(0.2)
              : isDark
                  ? AppColors.cardBg
                  : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? isDark
                    ? AppColors.accent
                    : AppColors.lightAccent
                : isDark
                    ? AppColors.border
                    : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: isSelected
                      ? isDark
                          ? AppColors.accent
                          : AppColors.lightAccent
                      : isDark
                          ? AppColors.textSecondary
                          : AppColors.lightTextSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<ProductModel> products;
  const _StatsRow({required this.products});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          _StatChip(
            count: products.where((p) => p.freshnessStatus == 0).length,
            label: 'свежих',
            color: AppColors.fresh,
          ),
          const SizedBox(width: 8),
          _StatChip(
            count: products.where((p) => p.freshnessStatus == 1).length,
            label: 'скоро',
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          _StatChip(
            count: products.where((p) => p.freshnessStatus == 2).length,
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
  final bool isFreezer;

  const _EmptyInventory({required this.isFreezer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 48))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 1500.ms),
          const SizedBox(height: 16),
          Text(
            isFreezer ? 'Морозильник пуст' : 'Холодильник пуст',
            style: GoogleFonts.exo2(
              color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Добавьте продукты через сканер\nили кнопку «+»',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
