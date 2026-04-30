import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/product_model.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>();
    final provider = context.watch<ProductProvider>();
    final total = provider.products.length;
    final fresh = provider.freshProducts.length;
    final warning = provider.warningProducts.length;
    final expired = provider.expiredProducts.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.getLocalizedString('statistics'),
                style: GoogleFonts.exo2(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              _BigCounter(total: total),
              const SizedBox(height: 20),
              _FillIndicator(fresh: fresh, warning: warning, expired: expired),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: '🟢',
                      label: t.getLocalizedString('fresh_label'),
                      count: fresh,
                      color: AppColors.fresh,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: '🟡',
                      label: t.getLocalizedString('warning_label'),
                      count: warning,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: '🔴',
                      label: t.getLocalizedString('expired_label'),
                      count: expired,
                      color: AppColors.expired,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                t.getLocalizedString('by_category'),
                style: GoogleFonts.exo2(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textMuted
                      : AppColors.lightTextMuted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _CategoryBreakdown(products: provider.products),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigCounter extends StatelessWidget {
  final int total;
  const _BigCounter({required this.total});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.accent : AppColors.lightAccent;
    final accentDarkColor =
        isDark ? AppColors.accentDark : AppColors.lightAccentDark;
    final textSecondaryColor =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.15),
            accentDarkColor.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.getLocalizedString('products_in_fridge'),
                style: GoogleFonts.nunito(
                  color: textSecondaryColor,
                  fontSize: 13,
                ),
              ),
              Text(
                '$total',
                style: GoogleFonts.exo2(
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Text('❄️', style: TextStyle(fontSize: 56))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 2000.ms,
              ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }
}

class _FillIndicator extends StatelessWidget {
  final int fresh, warning, expired;
  const _FillIndicator({
    required this.fresh,
    required this.warning,
    required this.expired,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final freshColor = isDark ? AppColors.fresh : AppColors.lightFresh;
    final warningColor = isDark ? AppColors.warning : AppColors.lightWarning;
    final expiredColor = isDark ? AppColors.expired : AppColors.lightExpired;
    final textMutedColor =
        isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    final total = fresh + warning + expired;
    if (total == 0) return const SizedBox.shrink();

    final fFresh = fresh / total;
    final fWarn = warning / total;
    final fExp = expired / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.getLocalizedString('fill_level'),
            style: GoogleFonts.exo2(
              fontSize: 9,
              color: textMutedColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Flexible(
                    flex: (fFresh * 100).round(),
                    child: Container(color: freshColor),
                  ),
                  Flexible(
                    flex: (fWarn * 100).round(),
                    child: Container(color: warningColor),
                  ),
                  Flexible(
                    flex: (fExp * 100).round(),
                    child: Container(color: expiredColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(fFresh * 100).round()}% ${t.getLocalizedString('fresh')} · '
            '${(fWarn * 100).round()}% ${t.getLocalizedString('expiring')} · '
            '${(fExp * 100).round()}% ${t.getLocalizedString('expired')}',
            style: GoogleFonts.nunito(color: textMutedColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon, label;
  final int count;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textMutedColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textMuted
        : AppColors.lightTextMuted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: GoogleFonts.exo2(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(fontSize: 10, color: textMutedColor),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final List<ProductModel> products;
  const _CategoryBreakdown({required this.products});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textPrimaryColor =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondaryColor =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final accentColor = isDark ? AppColors.accent : AppColors.lightAccent;

    final Map<ProductCategory, int> counts = {};
    for (final p in products) {
      counts[p.category] = (counts[p.category] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.map((e) {
        final pct = products.isEmpty ? 0.0 : e.value / products.length;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Text(e.key.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.key.label,
                        style: GoogleFonts.nunito(
                            color: textPrimaryColor, fontSize: 12)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: borderColor,
                        valueColor: AlwaysStoppedAnimation(accentColor),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${e.value}',
                style: GoogleFonts.exo2(
                  color: textSecondaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
