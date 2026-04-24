import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home_screen.dart';

/// Анимированный холодильник с разделением на секции
class FridgeWidget extends StatefulWidget {
  final StorageSection? openSection;
  final Function(StorageSection?) onSectionTap;
  final int fridgeItems;
  final int freezerItems;
  final int fridgeExpiring;
  final int freezerExpiring;
  final double width;
  final double height;

  const FridgeWidget({
    super.key,
    required this.openSection,
    required this.onSectionTap,
    this.fridgeItems = 0,
    this.freezerItems = 0,
    this.fridgeExpiring = 0,
    this.freezerExpiring = 0,
    this.width = 240,
    this.height = 480,
  });

  @override
  State<FridgeWidget> createState() => _FridgeWidgetState();
}

// FIX: TickerProviderStateMixin вместо SingleTickerProviderStateMixin
class _FridgeWidgetState extends State<FridgeWidget>
    with TickerProviderStateMixin {
  late AnimationController _fridgeDoorCtrl;
  late AnimationController _freezerDoorCtrl;
  late Animation<double> _fridgeDoorAngle;
  late Animation<double> _freezerDoorAngle;

  @override
  void initState() {
    super.initState();
    _fridgeDoorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _freezerDoorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fridgeDoorAngle = Tween<double>(begin: 0, end: -1.4).animate(
      CurvedAnimation(parent: _fridgeDoorCtrl, curve: Curves.easeInOut),
    );
    _freezerDoorAngle = Tween<double>(begin: 0, end: -1.4).animate(
      CurvedAnimation(parent: _freezerDoorCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(FridgeWidget old) {
    super.didUpdateWidget(old);
    if (widget.openSection != old.openSection) {
      if (widget.openSection == StorageSection.fridge) {
        _fridgeDoorCtrl.forward();
        _freezerDoorCtrl.reverse();
      } else if (widget.openSection == StorageSection.freezer) {
        _freezerDoorCtrl.forward();
        _fridgeDoorCtrl.reverse();
      } else {
        _fridgeDoorCtrl.reverse();
        _freezerDoorCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _fridgeDoorCtrl.dispose();
    _freezerDoorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fridgeH = widget.height * 0.68;
    final freezerH = widget.height * 0.32;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Тело
          _FridgeBody(
            width: widget.width,
            fridgeH: fridgeH,
            freezerH: freezerH,
            openSection: widget.openSection,
            fridgeItems: widget.fridgeItems,
            freezerItems: widget.freezerItems,
            onFridgeTap: () => widget.onSectionTap(
              widget.openSection == StorageSection.fridge ? null : StorageSection.fridge,
            ),
            onFreezerTap: () => widget.onSectionTap(
              widget.openSection == StorageSection.freezer ? null : StorageSection.freezer,
            ),
            isDark: isDark,
          ),

          // Дверца холодильника
          Positioned(
            top: 0,
            left: 0,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _fridgeDoorAngle,
                builder: (context, _) => Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_fridgeDoorAngle.value),
                  child: _FridgeDoorSection(
                    width: widget.width,
                    height: fridgeH,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
          ),

          // Дверца морозильника
          Positioned(
            top: fridgeH,
            left: 0,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _freezerDoorAngle,
                builder: (context, _) => Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_freezerDoorAngle.value),
                  child: _FreezerDoorSection(
                    width: widget.width,
                    height: freezerH,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
          ),

          if (widget.fridgeExpiring > 0)
            Positioned(
              top: -8,
              right: -8,
              child: _ExpiryBadge(count: widget.fridgeExpiring),
            ),

          if (widget.freezerExpiring > 0)
            Positioned(
              bottom: -8,
              right: -8,
              child: _ExpiryBadge(count: widget.freezerExpiring),
            ),
        ],
      ),
    );
  }
}

class _ExpiryBadge extends StatelessWidget {
  final int count;
  const _ExpiryBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: AppColors.warning.withOpacity(0.4), blurRadius: 8)],
      ),
      child: Text(
        '$count',
        style: GoogleFonts.exo2(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 800.ms);
  }
}

class _FridgeBody extends StatelessWidget {
  final double width, fridgeH, freezerH;
  final StorageSection? openSection;
  final int fridgeItems, freezerItems;
  final VoidCallback onFridgeTap, onFreezerTap;
  final bool isDark;

  const _FridgeBody({
    required this.width, required this.fridgeH, required this.freezerH,
    required this.openSection, required this.fridgeItems, required this.freezerItems,
    required this.onFridgeTap, required this.onFreezerTap, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final rimColor = isDark ? AppColors.borderLight : const Color(0xFFBFDBFE);

    return Column(
      children: [
        // Холодильник (верхняя часть, 68%)
        GestureDetector(
          onTap: onFridgeTap,
          child: Container(
            width: width,
            height: fridgeH,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1A3A6B), const Color(0xFF0D1E38)]
                    : [const Color(0xFFEFF6FF), const Color(0xFFDCEAFF)],
              ),
              border: Border.all(color: rimColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                  blurRadius: 16, offset: const Offset(4, 8),
                ),
              ],
            ),
            child: openSection == StorageSection.fridge
                ? _FridgeInner(totalItems: fridgeItems, isDark: isDark)
                : _ClosedLabel(label: 'Холодильник', icon: Icons.kitchen_rounded, isDark: isDark),
          ),
        ),

        // Уплотнитель
        Container(
          width: width,
          height: 14,
          decoration: BoxDecoration(
            color: rimColor,
            border: Border.symmetric(
              horizontal: BorderSide(
                color: isDark ? Colors.black26 : Colors.white54, width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 4, height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.white70,
                shape: BoxShape.circle,
              ),
            )),
          ),
        ),

        // Морозильник (нижняя часть, 32% - 14px gasket)
        GestureDetector(
          onTap: onFreezerTap,
          child: Container(
            width: width,
            height: freezerH - 14,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1E1A35), const Color(0xFF0D1225)]
                    : [const Color(0xFFEDE9FE), const Color(0xFFDDD6FE)],
              ),
              border: Border.all(color: rimColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                  blurRadius: 16, offset: const Offset(4, 8),
                ),
              ],
            ),
            child: openSection == StorageSection.freezer
                ? _FreezerInner(totalItems: freezerItems, isDark: isDark)
                : _ClosedLabel(
                    label: 'Морозильник', icon: Icons.ac_unit_rounded,
                    isDark: isDark, isFreezer: true,
                  ),
          ),
        ),
      ],
    );
  }
}

class _ClosedLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final bool isFreezer;

  const _ClosedLabel({
    required this.label, required this.icon, required this.isDark, this.isFreezer = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark
        ? AppColors.accent
        : (isFreezer ? const Color(0xFF7C3AED) : const Color(0xFF2563EB));

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: accent.withOpacity(0.5), size: 26),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.exo2(
            color: accent.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600,
          )),
        ],
      ),
    );
  }
}

class _FridgeInner extends StatelessWidget {
  final int totalItems;
  final bool isDark;
  const _FridgeInner({required this.totalItems, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < 3; i++) ...[
            _FridgeShelf(index: i, isDark: isDark),
            if (i < 2) const SizedBox(height: 6),
          ],
          const Spacer(),
          Text('$totalItems продуктов', style: GoogleFonts.exo2(
            fontSize: 8, color: Theme.of(context).colorScheme.primary, letterSpacing: 0.8,
          )),
        ],
      ),
    );
  }
}

class _FreezerInner extends StatelessWidget {
  final int totalItems;
  final bool isDark;
  const _FreezerInner({required this.totalItems, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.6),
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          _FreezerShelf(isDark: isDark),
          const Spacer(),
          Text('$totalItems продуктов', style: GoogleFonts.exo2(
            fontSize: 7, color: Theme.of(context).colorScheme.primary, letterSpacing: 0.8,
          )),
        ],
      ),
    );
  }
}

class _FridgeShelf extends StatelessWidget {
  final int index;
  final bool isDark;
  const _FridgeShelf({required this.index, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final shelfColor = isDark ? const Color(0xFF2A5298) : const Color(0xFFBAD4F7);
    return Container(
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        border: Border.all(color: shelfColor.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (i) => _ShelfItem(
          color: [AppColors.fresh, AppColors.warning, AppColors.fresh, AppColors.accent]
              [(index * 4 + i) % 4],
        )),
      ),
    );
  }
}

class _FreezerShelf extends StatelessWidget {
  final bool isDark;
  const _FreezerShelf({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final shelfColor = isDark ? const Color(0xFF2A5298) : const Color(0xFFC4B5FD);
    return Container(
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        border: Border.all(color: shelfColor.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (i) => _ShelfItem(
          color: [AppColors.fresh, AppColors.warning, AppColors.accent][i % 3],
        )),
      ),
    );
  }
}

class _ShelfItem extends StatelessWidget {
  final Color color;
  const _ShelfItem({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16, height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: color.withOpacity(0.3),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
    );
  }
}

class _FridgeDoorSection extends StatelessWidget {
  final double width, height;
  final bool isDark;
  const _FridgeDoorSection({required this.width, required this.height, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rimColor = isDark ? AppColors.borderLight : const Color(0xFF93C5FD);
    final handleColor = isDark ? AppColors.fridgeHandle : const Color(0xFF93C5FD);
    final accentColor = isDark ? AppColors.accent : const Color(0xFF2563EB);

    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20), topRight: Radius.circular(20),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A5298), const Color(0xFF1A3A6B)]
              : [const Color(0xFFDCEAFF), const Color(0xFFBFDBFE)],
        ),
        border: Border.all(color: rimColor, width: 1.5),
      ),
      child: Stack(children: [
        Positioned(
          right: 14, top: 0, bottom: 0,
          child: Center(
            child: Container(
              width: 7, height: height * 0.38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: handleColor,
                boxShadow: [BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 6)],
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.1),
                  border: Border.all(color: accentColor.withOpacity(0.4)),
                ),
                child: Icon(Icons.kitchen_rounded, color: accentColor, size: 22),
              ),
              const SizedBox(height: 8),
              Text('Холодильник', style: GoogleFonts.exo2(
                fontSize: 11, color: accentColor.withOpacity(0.8), fontWeight: FontWeight.w600,
              )),
            ],
          ),
        ),
      ]),
    );
  }
}

class _FreezerDoorSection extends StatelessWidget {
  final double width, height;
  final bool isDark;
  const _FreezerDoorSection({required this.width, required this.height, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rimColor = isDark ? AppColors.borderLight : const Color(0xFFA78BFA);
    final handleColor = isDark ? AppColors.fridgeHandle : const Color(0xFFA78BFA);
    final accentColor = isDark ? AppColors.accent : const Color(0xFF7C3AED);

    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A5298), const Color(0xFF1A3A6B)]
              : [const Color(0xFFDDD6FE), const Color(0xFFC4B5FD)],
        ),
        border: Border.all(color: rimColor, width: 1.5),
      ),
      child: Stack(children: [
        Positioned(
          right: 14, top: 0, bottom: 0,
          child: Center(
            child: Container(
              width: 6, height: height * 0.4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: handleColor,
                boxShadow: [BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 4)],
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.1),
                  border: Border.all(color: accentColor.withOpacity(0.4)),
                ),
                child: Icon(Icons.ac_unit_rounded, color: accentColor, size: 16),
              ),
              const SizedBox(height: 4),
              Text('Морозильник', style: GoogleFonts.exo2(
                fontSize: 9, color: accentColor.withOpacity(0.8), fontWeight: FontWeight.w600,
              )),
            ],
          ),
        ),
      ]),
    );
  }
}
