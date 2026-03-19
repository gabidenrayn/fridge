import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/product_model.dart';
import '../product/product_form_screen.dart';
import '../../providers/product_provider.dart';

/// Экран сканирования штрихкода
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scanCtrl = MobileScannerController();
  final ApiService _api = ApiService();
  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _isProcessing = true);
    await _scanCtrl.stop();

    final code = barcode!.rawValue!;
    _showLoadingSnack(code);

    // Запрос к Open Food Facts
    final food = await _api.getProductByBarcode(code);

    if (!mounted) return;

    // Переходим на форму добавления продукта
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(
          // Предзаполняем данные из API
          initialName: food?.name,
          initialBrand: food?.brand,
          barcode: code,
        ),
      ),
    );

    if (saved == true && mounted) {
      await context.read<ProductProvider>().loadProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.fresh,
          content: Text('Продукт добавлен!',
              style: GoogleFonts.nunito(color: Colors.black87)),
        ),
      );
    }

    setState(() => _isProcessing = false);
    await _scanCtrl.start();
  }

  void _showLoadingSnack(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Text('Поиск: $code',
                style: GoogleFonts.nunito(color: AppColors.textPrimary)),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ─── Камера ───
          MobileScanner(
            controller: _scanCtrl,
            onDetect: _onBarcodeDetected,
          ),

          // ─── Рамка сканирования ───
          _ScanOverlay(),

          // ─── UI элементы поверх камеры ───
          SafeArea(
            child: Column(
              children: [
                // Заголовок
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Text('СКАНЕР',
                          style: GoogleFonts.exo2(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 2,
                          )),
                      const Spacer(),
                      // Вспышка
                      GestureDetector(
                        onTap: () {
                          setState(() => _torchOn = !_torchOn);
                          _scanCtrl.toggleTorch();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Icon(
                            _torchOn
                                ? Icons.flashlight_on
                                : Icons.flashlight_off,
                            color:
                                _torchOn ? AppColors.warning : Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Подсказка
                Container(
                  margin: const EdgeInsets.all(20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Наведите камеру на штрихкод продукта',
                    style:
                        GoogleFonts.nunito(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Ручной ввод
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductFormScreen(),
                    ),
                  ).then((_) => context.read<ProductProvider>().loadProducts()),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.accent.withOpacity(0.5)),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded,
                              color: AppColors.accent, size: 16),
                          const SizedBox(width: 8),
                          Text('Добавить вручную',
                              style: GoogleFonts.exo2(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Полупрозрачный оверлей со рамкой сканирования
class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const frameSize = 240.0;

    return CustomPaint(
      size: size,
      painter: _OverlayPainter(frameSize: frameSize),
      child: Center(
        child: SizedBox(
          width: frameSize,
          height: frameSize,
          child: Stack(
            children: [
              // Угловые уголки рамки
              ..._corners(frameSize),
              // Анимированная линия сканирования
              _ScanLine(frameSize: frameSize),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _corners(double size) {
    const cornerSize = 24.0;
    const thickness = 3.0;
    final color = AppColors.accent;

    Widget corner({required bool top, required bool left}) {
      return Positioned(
        top: top ? 0 : null,
        bottom: top ? null : 0,
        left: left ? 0 : null,
        right: left ? null : 0,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: top
                  ? BorderSide(color: color, width: thickness)
                  : BorderSide.none,
              bottom: !top
                  ? BorderSide(color: color, width: thickness)
                  : BorderSide.none,
              left: left
                  ? BorderSide(color: color, width: thickness)
                  : BorderSide.none,
              right: !left
                  ? BorderSide(color: color, width: thickness)
                  : BorderSide.none,
            ),
          ),
        ),
      );
    }

    return [
      corner(top: true, left: true),
      corner(top: true, left: false),
      corner(top: false, left: true),
      corner(top: false, left: false),
    ];
  }
}

class _OverlayPainter extends CustomPainter {
  final double frameSize;
  const _OverlayPainter({required this.frameSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final cx = size.width / 2;
    final cy = size.height / 2;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy), width: frameSize, height: frameSize),
        const Radius.circular(8),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Анимированная линия сканирования
class _ScanLine extends StatelessWidget {
  final double frameSize;
  const _ScanLine({required this.frameSize});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        height: 2,
        width: frameSize,
        color: AppColors.accent.withOpacity(0.8),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
            begin: 0,
            end: frameSize - 4,
            duration: 1800.ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}
