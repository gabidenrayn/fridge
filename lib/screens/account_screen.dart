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
    if (error != null) setState(() => _errorMessage = error);
  }

  Future<void> _reloadProfile() async {
    setState(() => _errorMessage = null);
    await context.read<AuthProvider>().reloadProfile();
  }

  Future<void> _signOut() async {
    await context.read<AuthProvider>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final account = authProvider.accountModel;
    final user = authProvider.userModel;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accent = isDark ? AppColors.accent : AppColors.lightAccent;
    final cardColor = isDark ? AppColors.surface : AppColors.lightCardBg;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          themeProvider.getLocalizedString('account'),
          style: GoogleFonts.exo2(
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ],
      ),
      body: !authProvider.isReady
          ? Center(child: CircularProgressIndicator(color: accent))
          : account == null || user == null
              ? _buildErrorState(themeProvider, accent)
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Аватар ──────────────────────────────────────────
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withOpacity(0.12),
                          border: Border.all(
                              color: accent.withOpacity(0.4), width: 2),
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.exo2(
                              fontSize: 36,
                              color: accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Имя и email ─────────────────────────────────────
                      Text(
                        user.name,
                        style: GoogleFonts.exo2(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color:
                              Theme.of(context).textTheme.headlineSmall?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.email_outlined,
                              size: 13, color: textMuted),
                          const SizedBox(width: 4),
                          Text(
                            user.email,
                            style: GoogleFonts.nunito(
                              color: textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),

                      // Тип аккаунта-бейдж
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accent.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              account.type == AccountType.family
                                  ? Icons.group_rounded
                                  : Icons.person_rounded,
                              size: 13,
                              color: accent,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              account.type == AccountType.personal
                                  ? 'Личный аккаунт'
                                  : 'Семейный аккаунт',
                              style: GoogleFonts.exo2(
                                fontSize: 11,
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Карточка аккаунта ────────────────────────────────
                      _SectionCard(
                        cardColor: cardColor,
                        borderColor: borderColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(
                              title:
                                  themeProvider.getLocalizedString('account'),
                              icon: Icons.account_circle_outlined,
                              accent: accent,
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: themeProvider.getLocalizedString('name'),
                              value: account.name,
                              textSecondary: textSecondary,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: themeProvider.getLocalizedString('type'),
                              value: account.type == AccountType.personal
                                  ? 'Личный'
                                  : 'Семейный',
                              textSecondary: textSecondary,
                              isDark: isDark,
                            ),
                            if (account.type == AccountType.family) ...[
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: 'Владелец',
                                value: account.ownerId == user.id
                                    ? 'Вы'
                                    : 'Другой',
                                textSecondary: textSecondary,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Члены семьи',
                                style: GoogleFonts.exo2(
                                  fontSize: 11,
                                  color: textMuted,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...account.memberIds.map(
                                (memberId) => _MemberTile(
                                  memberId: memberId,
                                  canRemove: account.ownerId == user.id,
                                  onRemove: () => _removeFamilyMember(memberId),
                                  cardColor: cardColor,
                                  borderColor: borderColor,
                                  accent: accent,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Настройки ────────────────────────────────────────
                      _SectionCard(
                        cardColor: cardColor,
                        borderColor: borderColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(
                              title:
                                  themeProvider.getLocalizedString('settings'),
                              icon: Icons.settings_outlined,
                              accent: accent,
                            ),
                            const SizedBox(height: 16),

                            // Тема
                            Row(
                              children: [
                                Icon(
                                  themeProvider.isDarkMode
                                      ? Icons.dark_mode_outlined
                                      : Icons.light_mode_outlined,
                                  size: 18,
                                  color: textMuted,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    themeProvider.getLocalizedString('theme'),
                                    style: GoogleFonts.nunito(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  themeProvider.isDarkMode
                                      ? themeProvider
                                          .getLocalizedString('dark_theme')
                                      : themeProvider
                                          .getLocalizedString('light_theme'),
                                  style: GoogleFonts.nunito(
                                      color: textMuted, fontSize: 13),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: themeProvider.isDarkMode,
                                  onChanged: (value) {
                                    themeProvider.setThemeMode(
                                      value ? ThemeMode.dark : ThemeMode.light,
                                    );
                                  },
                                  activeThumbColor: isDark
                                      ? AppColors.accent
                                      : AppColors.lightAccent,
                                ),
                              ],
                            ),

                            Divider(color: borderColor, height: 24),

                            // Язык
                            Row(
                              children: [
                                Icon(Icons.language_outlined,
                                    size: 18, color: textMuted),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    themeProvider
                                        .getLocalizedString('language'),
                                    style: GoogleFonts.nunito(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: themeProvider.language,
                                    dropdownColor: isDark
                                        ? AppColors.surface
                                        : AppColors.lightSurface,
                                    style: GoogleFonts.nunito(
                                      color: isDark
                                          ? AppColors.textPrimary
                                          : AppColors.lightTextPrimary,
                                      fontSize: 13,
                                    ),
                                    onChanged: (String? newValue) {
                                      if (newValue != null)
                                        themeProvider.setLanguage(newValue);
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
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Создать семейный аккаунт ─────────────────────────
                      if (account.type == AccountType.personal) ...[
                        const SizedBox(height: 12),
                        _SectionCard(
                          cardColor: cardColor,
                          borderColor: borderColor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(
                                title: 'Семейный аккаунт',
                                icon: Icons.group_add_outlined,
                                accent: accent,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _familyNameController,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Название семьи',
                                  hintText: 'Например: Семья Ивановых',
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _createFamilyAccount,
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Создать'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Добавить члена семьи ──────────────────────────────
                      if (account.type == AccountType.family &&
                          account.ownerId == user.id) ...[
                        const SizedBox(height: 12),
                        _SectionCard(
                          cardColor: cardColor,
                          borderColor: borderColor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(
                                title: 'Добавить участника',
                                icon: Icons.person_add_outlined,
                                accent: accent,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _memberEmailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Email участника',
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _addFamilyMember,
                                  icon: const Icon(Icons.person_add_rounded,
                                      size: 18),
                                  label: const Text('Добавить'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Ошибка ────────────────────────────────────────────
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState(ThemeProvider themeProvider, Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.warning),
            const SizedBox(height: 16),
            Text(
              themeProvider.getLocalizedString('error'),
              textAlign: TextAlign.center,
              style: GoogleFonts.exo2(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте обновить данные или выйти и войти снова.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _reloadProfile,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: Text(themeProvider.getLocalizedString('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Вспомогательные виджеты ────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  final Color cardColor;
  final Color borderColor;

  const _SectionCard({
    required this.child,
    required this.cardColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;

  const _SectionTitle(
      {required this.title, required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.exo2(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: accent,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textSecondary;
  final bool isDark;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label:',
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String memberId;
  final bool canRemove;
  final VoidCallback onRemove;
  final Color cardColor, borderColor, accent;
  final bool isDark;

  const _MemberTile({
    required this.memberId,
    required this.canRemove,
    required this.onRemove,
    required this.cardColor,
    required this.borderColor,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline_rounded, size: 15, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              memberId,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.lightTextSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (canRemove)
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.remove_circle_outline_rounded,
                  size: 18, color: AppColors.expired),
            ),
        ],
      ),
    );
  }
}
