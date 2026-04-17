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
    this.height = 400,
  });

  @override
  State<FridgeWidget> createState() => _FridgeWidgetState();
}

class _FridgeWidgetState extends State<FridgeWidget>
    with SingleTickerProviderStateMixin {
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
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ─── Тело холодильника ───
          _FridgeBody(
            width: widget.width,
            height: widget.height,
            openSection: widget.openSection,
            fridgeItems: widget.fridgeItems,
            freezerItems: widget.freezerItems,
            onFridgeTap: () => widget.onSectionTap(
              widget.openSection == StorageSection.fridge
                  ? null
                  : StorageSection.fridge,
            ),
            onFreezerTap: () => widget.onSectionTap(
              widget.openSection == StorageSection.freezer
                  ? null
                  : StorageSection.freezer,
            ),
          ),

          // ─── Дверца холодильника ───
          Positioned(
            top: 0,
            left: 0,
            child: AnimatedBuilder(
              animation: _fridgeDoorAngle,
              builder: (context, _) {
                return Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_fridgeDoorAngle.value),
                  child: _FridgeDoorSection(
                    width: widget.width,
                    height: widget.height * 0.7,
                  ),
                );
              },
            ),
          ),

          // ─── Дверца морозильника ───
          Positioned(
            bottom: 0,
            left: 0,
            child: AnimatedBuilder(
              animation: _freezerDoorAngle,
              builder: (context, _) {
                return Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_freezerDoorAngle.value),
                  child: _FreezerDoorSection(
                    width: widget.width,
                    height: widget.height * 0.3,
                  ),
                );
              },
            ),
          ),

          // ─── Бейджи с кол-вом истекающих ───
          if (widget.fridgeExpiring > 0)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  '${widget.fridgeExpiring}',
                  style: GoogleFonts.exo2(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 800.ms),
            ),

          if (widget.freezerExpiring > 0)
            Positioned(
              bottom: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  '${widget.freezerExpiring}',
                  style: GoogleFonts.exo2(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 800.ms),
            ),
        ],
      ),
    );
  }
}

/// Тело холодильника с разделением на секции
class _FridgeBody extends StatelessWidget {
  final double width;
  final double height;
  final StorageSection? openSection;
  final int fridgeItems;
  final int freezerItems;
  final VoidCallback onFridgeTap;
  final VoidCallback onFreezerTap;

  const _FridgeBody({
    required this.width,
    required this.height,
    required this.openSection,
    required this.fridgeItems,
    required this.freezerItems,
    required this.onFridgeTap,
    required this.onFreezerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A6B), Color(0xFF0D1E38)],
        ),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(5, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Верхняя секция - холодильник
          GestureDetector(
            onTap: onFridgeTap,
            child: Container(
              height: height * 0.7,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                color: openSection == StorageSection.fridge
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
              ),
              child: openSection == StorageSection.fridge
                  ? _FridgeInner(totalItems: fridgeItems)
                  : const _FridgeSectionClosed(label: 'Холодильник'),
            ),
          ),

          // Разделитель
          Container(
            height: 2,
            color: Theme.of(context).dividerColor,
          ),

          // Нижняя секция - морозильник
          GestureDetector(
            onTap: onFreezerTap,
            child: Container(
              height: height * 0.3,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                color: openSection == StorageSection.freezer
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
              ),
              child: openSection == StorageSection.freezer
                  ? _FreezerInner(totalItems: freezerItems)
                  : const _FreezerSectionClosed(label: 'Морозильник'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Вид секции когда закрыта
class _FridgeSectionClosed extends StatelessWidget {
  final String label;

  const _FridgeSectionClosed({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: GoogleFonts.exo2(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          fontSize: 14,
        ),
      ),
    );
  }
}

/// Вид секции морозильника когда закрыта
class _FreezerSectionClosed extends StatelessWidget {
  final String label;

  const _FreezerSectionClosed({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: GoogleFonts.exo2(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Вид когда холодильник открыт — полки с индикаторами
class _FridgeInner extends StatelessWidget {
  final int totalItems;

  const _FridgeInner({required this.totalItems});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Внутренняя подсветка
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
          const SizedBox(height: 6),

          // Полки
          for (int i = 0; i < 2; i++) ...[
            _FridgeShelf(index: i),
            if (i < 1) const SizedBox(height: 4),
          ],

          const Spacer(),
          // Надпись-подсказка
          Text(
            '$totalItems продуктов',
            style: GoogleFonts.exo2(
              fontSize: 8,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Вид когда морозильник открыт
class _FreezerInner extends StatelessWidget {
  final int totalItems;

  const _FreezerInner({required this.totalItems});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Внутренняя подсветка
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
          const SizedBox(height: 4),

          // Полки
          _FreezerShelf(),

          const Spacer(),
          // Надпись-подсказка
          Text(
            '$totalItems продуктов',
            style: GoogleFonts.exo2(
              fontSize: 7,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Полочка внутри холодильника
class _FridgeShelf extends StatelessWidget {
  final int index;

  const _FridgeShelf({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
            4,
            (i) => _ShelfItem(
                  color: [
                    AppColors.fresh,
                    AppColors.warning,
                    AppColors.fresh,
                    AppColors.accent,
                  ][(index * 4 + i) % 4],
                )),
      ),
    );
  }
}

/// Полочка внутри морозильника
class _FreezerShelf extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
            3,
            (i) => _ShelfItem(
                  color: [
                    AppColors.fresh,
                    AppColors.warning,
                    AppColors.accent,
                  ][i % 3],
                )),
      ),
    );
  }
}

/// Маленький цветной блок-продукт на полке
class _ShelfItem extends StatelessWidget {
  final Color color;

  const _ShelfItem({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: color.withOpacity(0.3),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
    );
  }
}

/// Дверца холодильника
class _FridgeDoorSection extends StatelessWidget {
  final double width;
  final double height;

  const _FridgeDoorSection({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A5298), Color(0xFF1A3A6B)],
        ),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ручка
          Container(
            width: 6,
            height: 50,
            margin: EdgeInsets.only(left: width * 0.85),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: AppColors.fridgeHandle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Иконка холодильника
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(0.1),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.4),
              ),
            ),
            child: const Icon(
              Icons.kitchen_rounded,
              color: AppColors.accent,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// Дверца морозильника
class _FreezerDoorSection extends StatelessWidget {
  final double width;
  final double height;

  const _FreezerDoorSection({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A5298), Color(0xFF1A3A6B)],
        ),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ручка
          Container(
            width: 5,
            height: 30,
            margin: EdgeInsets.only(left: width * 0.85),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2.5),
              color: AppColors.fridgeHandle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Иконка морозильника
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(0.1),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.4),
              ),
            ),
            child: const Icon(
              Icons.ac_unit,
              color: AppColors.accent,
              size: 15,
            ),
          ),
        ],
      ),
    );
  }
}
