import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import 'widgets/fridge_widget.dart';
import 'widgets/inventory_panel.dart';

enum StorageSection { fridge, freezer }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StorageSection? _openSection;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  void _onSectionTap(StorageSection? section) {
    setState(() {
      // Если нажали на уже открытую секцию — закрываем
      _openSection = _openSection == section ? null : section;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          _BackgroundDecoration(),
          SafeArea(
            child: Column(
              children: [
                _AppHeader(themeProvider),
                Expanded(
                  child: Center(
                    child: FridgeWidget(
                      openSection: _openSection,
                      onSectionTap: _onSectionTap,
                      fridgeItems: provider.fridgeProducts.length,
                      freezerItems: provider.freezerProducts.length,
                      fridgeExpiring: provider.fridgeProducts
                          .where((p) => p.freshnessStatus >= 1)
                          .length,
                      freezerExpiring: provider.freezerProducts
                          .where((p) => p.freshnessStatus >= 1)
                          .length,
                    ),
                  ),
                ),
                if (_openSection != null)
                  Expanded(
                    child: InventoryPanel(
                      isFreezer: _openSection == StorageSection.freezer,
                    ),
                  ),
                if (_openSection == null) _HintText(themeProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  final ThemeProvider themeProvider;
  const _AppHeader(this.themeProvider);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                themeProvider.getLocalizedString('app_title'),
                style: GoogleFonts.exo2(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              Text(
                themeProvider.getLocalizedString('manage_products'),
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardTheme.color,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }
}

class _HintText extends StatelessWidget {
  final ThemeProvider themeProvider;
  const _HintText(this.themeProvider);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Text(
          '↑ ${themeProvider.getLocalizedString('tap_to_open')}',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color:
                Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 1000.ms)
            .then(delay: 500.ms)
            .fadeOut(duration: 1000.ms),
        const SizedBox(height: 16),
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
                Theme.of(context).colorScheme.primary.withOpacity(0.08),
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
                Theme.of(context).colorScheme.primary.withOpacity(0.06),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }
}
