import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/theme_provider.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      _NavItem(
          icon: Icons.kitchen_rounded,
          label: themeProvider.getLocalizedString('home')),
      _NavItem(
          icon: Icons.qr_code_scanner_rounded,
          label: themeProvider.getLocalizedString('scan')),
      _NavItem(
          icon: Icons.search_rounded,
          label: themeProvider.getLocalizedString('search')),
      _NavItem(
          icon: Icons.bar_chart_rounded,
          label: themeProvider.getLocalizedString('stats')),
      _NavItem(
          icon: Icons.account_circle_rounded,
          label: themeProvider.getLocalizedString('account')),
      _NavItem(
          icon: Icons.restaurant_menu_rounded,
          label: themeProvider.getLocalizedString('recipes')),
    ];

    final bgColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final accentColor = isDark ? AppColors.accent : AppColors.lightAccent;
    final mutedColor = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final shadowColor = isDark
        ? AppColors.accent.withOpacity(0.06)
        : AppColors.lightAccent.withOpacity(0.08);

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isSelected = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      size: 22,
                      color: isSelected ? accentColor : mutedColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: GoogleFonts.exo2(
                      fontSize: 9,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? accentColor : mutedColor,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
