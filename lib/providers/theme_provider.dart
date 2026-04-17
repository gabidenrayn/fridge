import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Провайдер темы приложения
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language';

  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'ru'; // 'ru' или 'en'

  ThemeMode get themeMode => _themeMode;
  String get language => _language;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? 'dark';
    final languageString = prefs.getString(_languageKey) ?? 'ru';

    _themeMode = themeString == 'light' ? ThemeMode.light : ThemeMode.dark;
    _language = languageString;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _themeKey, mode == ThemeMode.light ? 'light' : 'dark');
  }

  Future<void> toggleTheme() async {
    await setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  /// Получить локализованную строку
  String getLocalizedString(String key) {
    final strings = _language == 'ru' ? _ruStrings : _enStrings;
    return strings[key] ?? key;
  }

  static const Map<String, String> _ruStrings = {
    'app_title': 'SmartFridge',
    'manage_products': 'Управление продуктами',
    'fridge': 'Холодильник',
    'freezer': 'Морозильник',
    'tap_to_open': 'Нажмите чтобы открыть',
    'products_count': 'продуктов',
    'account': 'Аккаунт',
    'settings': 'Настройки',
    'theme': 'Тема',
    'language': 'Язык',
    'light_theme': 'Светлая',
    'dark_theme': 'Темная',
    'russian': 'Русский',
    'english': 'English',
    'logout': 'Выйти',
    'login': 'Войти',
    'register': 'Регистрация',
    'name': 'Имя',
    'email': 'Email',
    'password': 'Пароль',
    'confirm_password': 'Подтвердите пароль',
    'create_account': 'Создать аккаунт',
    'no_account': 'Нет аккаунта? Зарегистрироваться',
    'loading': 'Загрузка...',
    'error': 'Ошибка',
    'retry': 'Повторить',
    'cancel': 'Отмена',
    'save': 'Сохранить',
    'delete': 'Удалить',
    'edit': 'Редактировать',
    'add': 'Добавить',
    'search': 'Поиск',
    'scan': 'Сканировать',
    'stats': 'Статистика',
    'home': 'Главная',
  };

  static const Map<String, String> _enStrings = {
    'app_title': 'SmartFridge',
    'manage_products': 'Product Management',
    'fridge': 'Fridge',
    'freezer': 'Freezer',
    'tap_to_open': 'Tap to open',
    'products_count': 'products',
    'account': 'Account',
    'settings': 'Settings',
    'theme': 'Theme',
    'language': 'Language',
    'light_theme': 'Light',
    'dark_theme': 'Dark',
    'russian': 'Русский',
    'english': 'English',
    'logout': 'Logout',
    'login': 'Login',
    'register': 'Register',
    'name': 'Name',
    'email': 'Email',
    'password': 'Password',
    'confirm_password': 'Confirm Password',
    'create_account': 'Create Account',
    'no_account': 'No account? Register',
    'loading': 'Loading...',
    'error': 'Error',
    'retry': 'Retry',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'add': 'Add',
    'search': 'Search',
    'scan': 'Scan',
    'stats': 'Statistics',
    'home': 'Home',
  };
}
