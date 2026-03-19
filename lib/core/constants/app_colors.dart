import 'package:flutter/material.dart';

/// Цветовая палитра приложения — ледяные, холодные оттенки
class AppColors {
  AppColors._();

  // Фоны
  static const Color background = Color(0xFF0A1628);
  static const Color surface = Color(0xFF0F2040);
  static const Color cardBg = Color(0xFF142850);
  static const Color panelBg = Color(0xFF0D1E38);

  // Акцент — холодный синий
  static const Color accent = Color(0xFF4FC3F7);
  static const Color accentDark = Color(0xFF0288D1);
  static const Color accentGlow = Color(0x554FC3F7);

  // Статусы свежести
  static const Color fresh = Color(0xFF69F0AE); // свежий
  static const Color warning = Color(0xFFFFD740); // скоро истекает
  static const Color expired = Color(0xFFFF5252); // просрочен

  static const Color freshBg = Color(0x1569F0AE);
  static const Color warningBg = Color(0x15FFD740);
  static const Color expiredBg = Color(0x15FF5252);

  // Текст
  static const Color textPrimary = Color(0xFFE8F4FD);
  static const Color textSecondary = Color(0xFF90CAF9);
  static const Color textMuted = Color(0xFF546E8A);

  // Границы
  static const Color border = Color(0xFF1E3A5F);
  static const Color borderLight = Color(0xFF2A5298);

  // Холодильник
  static const Color fridgeDoor = Color(0xFF1A3A6B);
  static const Color fridgeHandle = Color(0xFF4FC3F7);
  static const Color fridgeGlow = Color(0x3304B0FF);
  static const Color fridgeInner = Color(0xFF0D1E38);
}
