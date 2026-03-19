import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// Анимированный холодильник — центральный элемент главного экрана
class FridgeWidget extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onTap;
  final int totalItems;
  final int expiringCount;

  const FridgeWidget({
    super.key,
    required this.isOpen,
    required this.onTap,
    this.totalItems = 0,
    this.expiringCount = 0,
  });

  @override
  State<FridgeWidget> createState() => _FridgeWidgetState();
}

class _FridgeWidgetState extends State<FridgeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _doorCtrl;
  late Animation<double> _doorAngle;

  @override
  void initState() {
    super.initState();
    _doorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _doorAngle = Tween<double>(begin: 0, end: -1.4).animate(
      CurvedAnimation(parent: _doorCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(FridgeWidget old) {
    super.didUpdateWidget(old);
    if (widget.isOpen != old.isOpen) {
      widget.isOpen ? _doorCtrl.forward() : _doorCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _doorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 200,
        height: 280,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ─── Тело холодильника ───
            _FridgeBody(
              isOpen: widget.isOpen,
              totalItems: widget.totalItems,
            ),

            // ─── Дверца (3D-эффект поворота по Y) ───
            AnimatedBuilder(
              animation: _doorAngle,
              builder: (context, _) {
                return Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_doorAngle.value),
                  child: const _FridgeDoor(),
                );
              },
            ),

            // ─── Свечение при открытии ───
            if (widget.isOpen)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.35),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms),
              ),

            // ─── Бейдж с кол-вом истекающих ───
            if (widget.expiringCount > 0)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    '${widget.expiringCount}',
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
      ),
    );
  }
}

/// Тело холодильника (внутренность)
class _FridgeBody extends StatelessWidget {
  final bool isOpen;
  final int totalItems;

  const _FridgeBody({required this.isOpen, required this.totalItems});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A6B), Color(0xFF0D1E38)],
        ),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(5, 10),
          ),
        ],
      ),
      child:
          isOpen ? _FridgeInner(totalItems: totalItems) : const _FridgeClosed(),
    );
  }
}

/// Вид когда закрыт
class _FridgeClosed extends StatelessWidget {
  const _FridgeClosed();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.kitchen_rounded,
              size: 60, color: AppColors.accent.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            'Нажмите чтобы\nоткрыть',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Вид когда открыт — полки с индикаторами
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
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(colors: [
                AppColors.accent.withOpacity(0.8),
                AppColors.accent.withOpacity(0.2),
              ]),
            ),
          ),
          const SizedBox(height: 8),

          // Полки
          for (int i = 0; i < 3; i++) ...[
            _FridgeShelf(index: i),
            const SizedBox(height: 6),
          ],

          const Spacer(),
          // Надпись-подсказка
          Text(
            '$totalItems продуктов',
            style: GoogleFonts.exo2(
              fontSize: 10,
              color: AppColors.accent,
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
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: AppColors.accent.withOpacity(0.05),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.15),
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
    )
        .animate(delay: Duration(milliseconds: 300 + index * 100))
        .fadeIn()
        .slideY(begin: 0.2, end: 0);
  }
}

/// Маленький цветной блок-продукт на полке
class _ShelfItem extends StatelessWidget {
  final Color color;
  const _ShelfItem({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withOpacity(0.3),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
    );
  }
}

/// Дверца холодильника
class _FridgeDoor extends StatelessWidget {
  const _FridgeDoor();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 280,
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
            width: 8,
            height: 60,
            margin: const EdgeInsets.only(left: 160),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: AppColors.fridgeHandle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Логотип/иконка на дверце
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(0.1),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.4),
              ),
            ),
            child: Icon(
              Icons.kitchen_rounded,
              color: AppColors.accent,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}
