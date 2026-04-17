import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/account_model.dart';
import '../core/constants/app_colors.dart';

/// Экран управления аккаунтом
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _familyNameController = TextEditingController();
  final _memberEmailController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _familyNameController.dispose();
    _memberEmailController.dispose();
    super.dispose();
  }

  Future<void> _createFamilyAccount() async {
    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.createFamilyAccount(
      _familyNameController.text.trim(),
    );

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      _familyNameController.clear();
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _addFamilyMember() async {
    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.addFamilyMember(
      _memberEmailController.text.trim(),
    );

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      _memberEmailController.clear();
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _removeFamilyMember(String memberId) async {
    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.removeFamilyMember(memberId);

    if (error != null) {
      setState(() => _errorMessage = error);
    }
  }

  Future<void> _reloadProfile() async {
    setState(() => _errorMessage = null);
    await context.read<AuthProvider>().reloadProfile();
  }

  Future<void> _signOut() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final account = authProvider.accountModel;
    final user = authProvider.userModel;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          themeProvider.getLocalizedString('account'),
          style:
              TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ],
      ),
      body: !authProvider.isReady
          ? const Center(child: CircularProgressIndicator())
          : account == null || user == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 56, color: AppColors.warning),
                        const SizedBox(height: 16),
                        Text(
                          themeProvider.getLocalizedString('error'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.exo2(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Попробуйте обновить данные или выйти и войти снова.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _reloadProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                          ),
                          child:
                              Text(themeProvider.getLocalizedString('retry')),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Аватар пользователя
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.accent.withOpacity(0.1),
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.exo2(
                            fontSize: 32,
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Информация о пользователе
                      Text(
                        user.name,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.7),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Информация об аккаунте
                      Card(
                        color: Theme.of(context).cardTheme.color,
                        elevation: Theme.of(context).cardTheme.elevation,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                themeProvider.getLocalizedString('account'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                  '${themeProvider.getLocalizedString('name')}: ${account.name}'),
                              Text(
                                '${themeProvider.getLocalizedString('type')}: ${account.type == AccountType.personal ? 'Личный' : 'Семейный'}',
                              ),
                              if (account.type == AccountType.family) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Владелец: ${account.ownerId == user.id ? 'Вы' : 'Другой'}',
                                ),
                                const SizedBox(height: 8),
                                const Text('Члены семьи:'),
                                ...account.memberIds.map(
                                  (memberId) => ListTile(
                                    title: Text(memberId),
                                    trailing: account.ownerId == user.id
                                        ? IconButton(
                                            icon: const Icon(Icons.remove),
                                            onPressed: () =>
                                                _removeFamilyMember(memberId),
                                          )
                                        : null,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Настройки
                      Card(
                        color: Theme.of(context).cardTheme.color,
                        elevation: Theme.of(context).cardTheme.elevation,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                themeProvider.getLocalizedString('settings'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),

                              // Тема
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(themeProvider
                                      .getLocalizedString('theme')),
                                  Row(
                                    children: [
                                      Text(
                                        themeProvider.isDarkMode
                                            ? themeProvider.getLocalizedString(
                                                'dark_theme')
                                            : themeProvider.getLocalizedString(
                                                'light_theme'),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Switch(
                                        value: themeProvider.isDarkMode,
                                        onChanged: (value) {
                                          themeProvider.setThemeMode(
                                            value
                                                ? ThemeMode.dark
                                                : ThemeMode.light,
                                          );
                                        },
                                        activeColor: AppColors.accent,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Язык
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(themeProvider
                                      .getLocalizedString('language')),
                                  DropdownButton<String>(
                                    value: themeProvider.language,
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        themeProvider.setLanguage(newValue);
                                      }
                                    },
                                    items: [
                                      DropdownMenuItem(
                                        value: 'ru',
                                        child: Text(themeProvider
                                            .getLocalizedString('russian')),
                                      ),
                                      DropdownMenuItem(
                                        value: 'en',
                                        child: Text(themeProvider
                                            .getLocalizedString('english')),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Создание семейного аккаунта
                      if (account.type == AccountType.personal) ...[
                        const SizedBox(height: 16),
                        Card(
                          color: Theme.of(context).cardTheme.color,
                          elevation: Theme.of(context).cardTheme.elevation,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Создать семейный аккаунт',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _familyNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Название семьи',
                                    border: const OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .inputDecorationTheme
                                        .fillColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _createFamilyAccount,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent,
                                    ),
                                    child: const Text('Создать'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Добавление члена семьи
                      if (account.type == AccountType.family &&
                          account.ownerId == user.id) ...[
                        const SizedBox(height: 16),
                        Card(
                          color: Theme.of(context).cardTheme.color,
                          elevation: Theme.of(context).cardTheme.elevation,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Добавить члена семьи',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _memberEmailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email члена семьи',
                                    border: const OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .inputDecorationTheme
                                        .fillColor,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _addFamilyMember,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent,
                                    ),
                                    child: const Text('Добавить'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
