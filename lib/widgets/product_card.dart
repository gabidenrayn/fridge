import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/date_utils.dart';
import '../models/product_model.dart';

/// Карточка продукта в инвентаре — стиль RPG-инвентаря
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final int index;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onDelete,
    this.index = 0,
  });

  Color _getStatusColor(bool isDark) {
    switch (product.freshnessStatus) {
      case 0:
        return isDark ? AppColors.fresh : AppColors.lightFresh;
      case 1:
        return isDark ? AppColors.warning : AppColors.lightWarning;
      case 2:
        return isDark ? AppColors.expired : AppColors.lightExpired;
      default:
        return isDark ? AppColors.fresh : AppColors.lightFresh;
    }
  }

  Color _getStatusBg(bool isDark) {
    switch (product.freshnessStatus) {
      case 0:
        return isDark ? AppColors.freshBg : AppColors.lightFreshBg;
      case 1:
        return isDark ? AppColors.warningBg : AppColors.lightWarningBg;
      case 2:
        return isDark ? AppColors.expiredBg : AppColors.lightExpiredBg;
      default:
        return isDark ? AppColors.freshBg : AppColors.lightFreshBg;
    }
  }

  String get _statusLabel {
    switch (product.freshnessStatus) {
      case 0:
        return 'СВЕЖИЙ';
      case 1:
        return 'СКОРО';
      case 2:
        return 'ПРОСРОЧЕН';
      default:
        return 'СВЕЖИЙ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(isDark);
    final statusBg = _getStatusBg(isDark);
    final cardBgColor = isDark ? AppColors.cardBg : AppColors.lightCardBg;
    final textPrimaryColor =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondaryColor =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMutedColor =
        isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Левый цветовой индикатор
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  // Иконка категории
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        product.category.icon,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Основная информация
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: GoogleFonts.exo2(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Статус-бейдж
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                _statusLabel,
                                style: GoogleFonts.exo2(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: statusColor.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppDateUtils.getExpiryLabel(product.expiryDate),
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${product.quantity} ${product.unit}',
                              style: GoogleFonts.exo2(
                                fontSize: 12,
                                color: textSecondaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (product.brand != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            product.brand!,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: textMutedColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Кнопка удаления
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: textMutedColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        // Анимация появления карточки
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1, end: 0);
  }
}
