import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';

/// Экран статистики
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final total = provider.products.length;
    final fresh = provider.freshProducts.length;
    final warning = provider.warningProducts.length;
    final expired = provider.expiredProducts.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('СТАТИСТИКА',
                  style: GoogleFonts.exo2(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    letterSpacing: 2,
                  )),
              const SizedBox(height: 20),

              // Большой счётчик
              _BigCounter(total: total),
              const SizedBox(height: 20),

              // Индикатор заполненности
              _FillIndicator(fresh: fresh, warning: warning, expired: expired),
              const SizedBox(height: 20),

              // Карточки по статусам
              Row(
                children: [
                  Expanded(
                      child: _StatCard(
                    icon: '🟢',
                    label: 'Свежих',
                    count: fresh,
                    color: AppColors.fresh,
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _StatCard(
                    icon: '🟡',
                    label: 'Скоро',
                    count: warning,
                    color: AppColors.warning,
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _StatCard(
                    icon: '🔴',
                    label: 'Просроч.',
                    count: expired,
                    color: AppColors.expired,
                  )),
                ],
              ),
              const SizedBox(height: 20),

              // По категориям
              Text('ПО КАТЕГОРИЯМ',
                  style: GoogleFonts.exo2(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 1.5,
                  )),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withOpacity(0.15),
            AppColors.accentDark.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Продуктов\nв холодильнике',
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  )),
              Text('$total',
                  style: GoogleFonts.exo2(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  )),
            ],
          ),
          const Spacer(),
          Text('❄️', style: const TextStyle(fontSize: 56))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 2000.ms),
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
    final total = fresh + warning + expired;
    if (total == 0) return const SizedBox.shrink();

    final fFresh = fresh / total;
    final fWarn = warning / total;
    final fExp = expired / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ЗАПОЛНЕННОСТЬ',
              style: GoogleFonts.exo2(
                fontSize: 9,
                color: AppColors.textMuted,
                letterSpacing: 1.2,
              )),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Flexible(
                    flex: (fFresh * 100).round(),
                    child: Container(color: AppColors.fresh),
                  ),
                  Flexible(
                    flex: (fWarn * 100).round(),
                    child: Container(color: AppColors.warning),
                  ),
                  Flexible(
                    flex: (fExp * 100).round(),
                    child: Container(color: AppColors.expired),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(fFresh * 100).round()}% свежих · '
            '${(fWarn * 100).round()}% скоро · '
            '${(fExp * 100).round()}% просрочено',
            style: GoogleFonts.nunito(color: AppColors.textMuted, fontSize: 11),
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
          Text('$count',
              style: GoogleFonts.exo2(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              )),
          Text(label,
              style: GoogleFonts.nunito(
                fontSize: 10,
                color: AppColors.textMuted,
              )),
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
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
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        )),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(AppColors.accent),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('${e.value}',
                  style: GoogleFonts.exo2(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        );
      }).toList(),
    );
  }
}
