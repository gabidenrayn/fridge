import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/product_provider.dart';
import 'widgets/fridge_widget.dart';
import 'widgets/inventory_panel.dart';

/// Главный экран с холодильником и инвентарём
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _fridgeOpen = false;

  @override
  void initState() {
    super.initState();
    // Загружаем продукты при старте
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ─── Фоновые декоративные круги ───
          _BackgroundDecoration(),

          // ─── Основное содержимое ───
          SafeArea(
            child: Column(
              children: [
                // Заголовок
                _AppHeader(),

                // Холодильник по центру
                SizedBox(
                  height: _fridgeOpen ? 200 : screenH * 0.45,
                  child: Center(
                    child: FridgeWidget(
                      isOpen: _fridgeOpen,
                      totalItems: provider.products.length,
                      expiringCount: provider.warningProducts.length +
                          provider.expiredProducts.length,
                      onTap: () => setState(() => _fridgeOpen = !_fridgeOpen),
                    ),
                  ),
                ),

                // Панель инвентаря — появляется когда холодильник открыт
                if (_fridgeOpen) Expanded(child: const InventoryPanel()),

                if (!_fridgeOpen) _HintText(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SmartFridge',
                  style: GoogleFonts.exo2(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              Text('Управление продуктами',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  )),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Icon(Icons.notifications_outlined,
                color: AppColors.accent, size: 20),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }
}

class _HintText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Text(
          '↑ Нажмите на холодильник',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 1000.ms)
            .then(delay: 500.ms)
            .fadeOut(duration: 1000.ms),
      ],
    );
  }
}

class _BackgroundDecoration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          left: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.accent.withOpacity(0.08),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.accentDark.withOpacity(0.06),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }
}
