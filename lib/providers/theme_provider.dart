import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language';

  ThemeMode _themeMode = ThemeMode.light;
  String _language = 'ru';

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
    'dark_theme': 'Тёмная',
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
    'recipes': 'Рецепты',
    // Инвентарь
    'inventory': 'ИНВЕНТАРЬ',
    'items': 'предметов',
    'fridge_empty': 'Холодильник пуст',
    'add_via_scanner': 'Добавьте продукты через сканер\nили кнопку «+»',
    'delete_confirm': 'Удалить?',
    'delete_product': 'будет удалён.',
    'all': 'Все',
    'fresh': 'свежих',
    'expiring': 'скоро',
    'expired': 'просрочено',
    // Поиск
    'search_hint': 'Название продукта...',
    'search_results': 'Результаты',
    'not_found': 'Ничего не найдено',
    // Статистика
    'total_products': 'Всего продуктов',
    'expiring_soon': 'Скоро истекает',
    'expired_count': 'Просрочено',
    // Аккаунт
    'profile': 'Профиль',
    'notifications': 'Уведомления',
    // Рецепты
    'find_recipe': 'Подобрать рецепт',
    'finding_recipe': 'Ищем рецепт...',
    'roll_hint': 'Нажмите кубик',
    'roll_description': 'Подберём рецепт из ваших\nпродуктов в холодильнике',
    'another_recipe': 'Другой продукт',
    'today_cook': '🎲 СЕГОДНЯ ГОТОВИМ',
    'expiry_title': 'СРОКИ ИСТЕЧЕНИЯ',
    'fridge_empty_hint':
        'Холодильник пуст!\nДобавьте продукты чтобы получить рецепт.',
    'no_internet':
        'Не удалось загрузить рецепт.\nПроверьте интернет-соединение.',
    'ingredients': '🧂 Ингредиенты',
    'cooking': '👨‍🍳 Приготовление',
    'empty_fridge_timeline': '🧊 Холодильник пуст',
    // Семья
    'join_family': 'Войти в семью',
    'tab_search': 'Поиск',
    'tab_my_requests': 'Мои запросы',
    'search_family_hint': 'Введите название семьи...',
    'optional_message': 'Сообщение для владельца (необязательно)...',
    'search_min_chars': 'Введите минимум 2 символа',
    'families_not_found': 'Семьи не найдены',
    'search_error': 'Ошибка поиска. Проверьте соединение.',
    'join_btn': 'Вступить',
    'members_count': 'участников',
    'no_requests': 'Нет отправленных запросов',
    'request_pending': 'Ожидает',
    'request_accepted': 'Принят',
    'request_rejected': 'Отклонён',
    'request_sent': 'Запрос отправлен в',
    'not_authorized': 'Не авторизован',
    'leave_family': 'Выйти',
    'leave_family_title': 'Выйти из семьи?',
    'leave_family_body': 'Вы покинете семейный аккаунт и вернётесь к личному.',
    'type': 'Тип',
    'owner': 'Владелец',
    'owner_you': 'Вы',
    'owner_other': 'Другой',
    'family_members': 'Члены семьи',
    'personal_account': 'Личный аккаунт',
    'family_account': 'Семейный аккаунт',
    'personal_type': 'Личный',
    'family_type': 'Семейный',

    'family_account_title': 'Семейный аккаунт',
    'family_name_label': 'Название семьи',
    'family_name_hint': 'Напр., Семья Ивановых',
    'create_btn': 'Создать',
    'add_member_title': 'Добавить участника',
    'member_email_label': 'Email участника',
    'manage_requests': 'Управить запросами',

    'cat_dairy': 'Молочное',
    'cat_meat': 'Мясо',
    'cat_veggies': 'Овощи',
    'cat_drinks': 'Напитки',
    'cat_frozen': 'Заморозка',
    'cat_fruits': 'Фрукты',
    'cat_grains': 'Крупы',
    'cat_other': 'Другое',

    'products_word': 'продуктов',

    'new_product': 'Новый продукт',
    'edit_product': 'Редактировать',
    'product_name_label': 'Название продукта',
    'product_name_hint': 'Введите название',
    'brand_label': 'Бренд (необязательно)',
    'brand_hint': 'Например: Danone',
    'quantity_label': 'Количество',
    'unit_label': 'Единица',
    'category_label': 'Категория',
    'purchase_date': 'Дата покупки',
    'expiry_date': 'Срок годности',
    'note_label': 'Заметка (необязательно)',
    'note_hint': 'Любая дополнительная информация...',
    'validate_name': 'Укажите название',
    'product_added': 'Продукт добавлен!',

    'statistics': 'СТАТИСТИКА',
    'products_in_fridge': 'Продуктов\nв холодильнике',
    'fresh_label': 'Свежих',
    'warning_label': 'Скоро',
    'expired_label': 'Просроч.',
    'by_category': 'ПО КАТЕГОРИЯМ',
    'fill_indicator': 'ЗАПОЛНЕННОСТЬ',
    'fill_percent': '% свежих · % скоро · % просрочено',

    'scanner': 'СКАНЕР',
    'scan_hint': 'Наведите камеру на штрихкод продукта',
    'add_manually': 'Добавить вручную',
    'searching': 'Поиск',

    'search_title': 'ПОИСК',
    'search_placeholder': 'Поиск по названию...',
    'tab_all': 'ВСЕ',
    'tab_expiring': 'СКОРО',
    'tab_expired': 'ПРОСРОЧЕНО',
    'no_expiring': '✅ Нет продуктов с истекающим сроком',
    'no_expired': '✅ Просроченных продуктов нет',

    'recipes_from_fridge': 'из продуктов в холодильнике',
  };

  static const Map<String, String> _enStrings = {
    'new_product': 'New Product',
    'edit_product': 'Edit',
    'product_name_label': 'Product Name',
    'product_name_hint': 'Enter name',
    'brand_label': 'Brand (optional)',
    'brand_hint': 'e.g.: Danone',
    'quantity_label': 'Quantity',
    'unit_label': 'Unit',
    'category_label': 'Category',
    'purchase_date': 'Purchase Date',
    'expiry_date': 'Expiry Date',
    'note_label': 'Note (optional)',
    'note_hint': 'Any additional info...',
    'validate_name': 'Enter a name',
    'product_added': 'Product added!',

    'statistics': 'STATISTICS',
    'products_in_fridge': 'Products\nin fridge',
    'fresh_label': 'Fresh',
    'warning_label': 'Soon',
    'expired_label': 'Expired',
    'by_category': 'BY CATEGORY',
    'fill_indicator': 'FILL LEVEL',
    'fill_percent': '% fresh · % soon · % expired',

    'scanner': 'SCANNER',
    'scan_hint': 'Point camera at product barcode',
    'add_manually': 'Add manually',
    'searching': 'Searching',

    'search_title': 'SEARCH',
    'search_placeholder': 'Search by name...',
    'tab_all': 'ALL',
    'tab_expiring': 'SOON',
    'tab_expired': 'EXPIRED',
    'no_expiring': '✅ No products expiring soon',
    'no_expired': '✅ No expired products',

    'recipes_from_fridge': 'from fridge products',

    'products_word': 'products',
    'cat_dairy': 'Dairy',
    'cat_meat': 'Meat',
    'cat_veggies': 'Vegetables',
    'cat_drinks': 'Drinks',
    'cat_frozen': 'Frozen',
    'cat_fruits': 'Fruits',
    'cat_grains': 'Grains',
    'cat_other': 'Other',
    'family_account_title': 'Family Account',
    'family_name_label': 'Family Name',
    'family_name_hint': 'e.g., The Smith Family',
    'create_btn': 'Create',
    'add_member_title': 'Add Member',
    'member_email_label': 'Member Email',
    'manage_requests': 'Manage Requests',

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
    'recipes': 'Recipes',
    // Inventory
    'inventory': 'INVENTORY',
    'items': 'items',
    'fridge_empty': 'Fridge is empty',
    'add_via_scanner': 'Add products via scanner\nor the «+» button',
    'delete_confirm': 'Delete?',
    'delete_product': 'will be deleted.',
    'all': 'All',
    'fresh': 'fresh',
    'expiring': 'expiring',
    'expired': 'expired',
    // Search
    'search_hint': 'Product name...',
    'search_results': 'Results',
    'not_found': 'Nothing found',
    // Stats
    'total_products': 'Total products',
    'expiring_soon': 'Expiring soon',
    'expired_count': 'Expired',
    // Account
    'profile': 'Profile',
    'notifications': 'Notifications',
    // Recipes
    'find_recipe': 'Find a recipe',
    'finding_recipe': 'Finding recipe...',
    'roll_hint': 'Press the dice',
    'roll_description': 'We\'ll find a recipe from your\nfridge products',
    'another_recipe': 'Another product',
    'today_cook': '🎲 TODAY WE COOK',
    'expiry_title': 'EXPIRY TIMELINE',
    'fridge_empty_hint': 'Fridge is empty!\nAdd products to get a recipe.',
    'no_internet': 'Failed to load recipe.\nCheck your internet connection.',
    'ingredients': '🧂 Ingredients',
    'cooking': '👨‍🍳 Cooking steps',
    'empty_fridge_timeline': '🧊 Fridge is empty',
    // Family
    'join_family': 'Join Family',
    'tab_search': 'Search',
    'tab_my_requests': 'My Requests',
    'search_family_hint': 'Search family name...',
    'optional_message': 'Optional message to family owner...',
    'search_min_chars': 'Enter at least 2 characters',
    'families_not_found': 'No families found',
    'search_error': 'Search error. Check your connection.',
    'join_btn': 'Join',
    'members_count': 'members',
    'no_requests': 'No requests sent',
    'request_pending': 'Pending',
    'request_accepted': 'Accepted',
    'request_rejected': 'Rejected',
    'request_sent': 'Request sent to',
    'not_authorized': 'Not authorized',
    'leave_family': 'Leave',
    'leave_family_title': 'Leave family?',
    'leave_family_body':
        'You will leave the family account and return to a personal one.',
    'type': 'Type',
    'owner': 'Owner',
    'owner_you': 'You',
    'owner_other': 'Other',
    'family_members': 'Family members',
    'personal_account': 'Personal Account',
    'family_account': 'Family Account',
    'personal_type': 'Personal',
    'family_type': 'Family',
  };
}
