import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/account_model.dart';
import '../core/constants/app_colors.dart';
import 'family/family_management_screen.dart';
import 'family/family_request_screen.dart';

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
    final error = await context
        .read<AuthProvider>()
        .createFamilyAccount(_familyNameController.text.trim());
    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      _familyNameController.clear();
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _addFamilyMember() async {
    final error = await context
        .read<AuthProvider>()
        .addFamilyMember(_memberEmailController.text.trim());
    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      _memberEmailController.clear();
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _removeFamilyMember(String memberId) async {
    final error =
        await context.read<AuthProvider>().removeFamilyMember(memberId);
    if (error != null) setState(() => _errorMessage = error);
  }

  Future<void> _reloadProfile() async {
    setState(() => _errorMessage = null);
    await context.read<AuthProvider>().reloadProfile();
  }

  Future<void> _signOut() async {
    await context.read<AuthProvider>().signOut();
  }

  Future<void> _leaveFamily() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.read<ThemeProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t.getLocalizedString('leave_family_title'),
          style: GoogleFonts.exo2(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          t.getLocalizedString('leave_family_body'),
          style: GoogleFonts.nunito(
            fontSize: 14,
            color:
                isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              t.getLocalizedString('cancel'),
              style: TextStyle(
                  color:
                      isDark ? AppColors.textMuted : AppColors.lightTextMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              t.getLocalizedString('leave_family'),
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final error = await context.read<AuthProvider>().leaveFamily();
      if (error != null) setState(() => _errorMessage = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final t = context.watch<ThemeProvider>();
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
          t.getLocalizedString('account'),
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
              ? _buildErrorState(t, accent)
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Аватар ──────────────────────────────────
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

                      // ── Имя ────────────────────────────────────
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
                          Text(user.email,
                              style: GoogleFonts.nunito(
                                  color: textMuted, fontSize: 13)),
                        ],
                      ),

                      // ── Бейдж типа аккаунта ─────────────────────
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
                                  ? t.getLocalizedString('personal_account')
                                  : t.getLocalizedString('family_account'),
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

                      // ── Карточка аккаунта ───────────────────────
                      _SectionCard(
                        cardColor: cardColor,
                        borderColor: borderColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _SectionTitle(
                                    title: t.getLocalizedString('account'),
                                    icon: Icons.account_circle_outlined,
                                    accent: accent,
                                  ),
                                ),
                                if (account.type == AccountType.family)
                                  GestureDetector(
                                    onTap: _leaveFamily,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.red.withOpacity(0.4)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.logout_rounded,
                                              size: 13, color: Colors.red),
                                          const SizedBox(width: 4),
                                          Text(
                                            t.getLocalizedString(
                                                'leave_family'),
                                            style: GoogleFonts.exo2(
                                              fontSize: 11,
                                              color: Colors.red,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: t.getLocalizedString('name'),
                              value: account.name,
                              textSecondary: textSecondary,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: t.getLocalizedString('type'),
                              value: account.type == AccountType.personal
                                  ? t.getLocalizedString('personal_type')
                                  : t.getLocalizedString('family_type'),
                              textSecondary: textSecondary,
                              isDark: isDark,
                            ),
                            if (account.type == AccountType.family) ...[
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: t.getLocalizedString('owner'),
                                value: account.ownerId == user.id
                                    ? t.getLocalizedString('owner_you')
                                    : t.getLocalizedString('owner_other'),
                                textSecondary: textSecondary,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                t.getLocalizedString('family_members'),
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

                      // ── Настройки ───────────────────────────────
                      _SectionCard(
                        cardColor: cardColor,
                        borderColor: borderColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(
                              title: t.getLocalizedString('settings'),
                              icon: Icons.settings_outlined,
                              accent: accent,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  t.isDarkMode
                                      ? Icons.dark_mode_outlined
                                      : Icons.light_mode_outlined,
                                  size: 18,
                                  color: textMuted,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    t.getLocalizedString('theme'),
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
                                  t.isDarkMode
                                      ? t.getLocalizedString('dark_theme')
                                      : t.getLocalizedString('light_theme'),
                                  style: GoogleFonts.nunito(
                                      color: textMuted, fontSize: 13),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: t.isDarkMode,
                                  onChanged: (value) {
                                    t.setThemeMode(value
                                        ? ThemeMode.dark
                                        : ThemeMode.light);
                                  },
                                  activeThumbColor: isDark
                                      ? AppColors.accent
                                      : AppColors.lightAccent,
                                ),
                              ],
                            ),
                            Divider(color: borderColor, height: 24),
                            Row(
                              children: [
                                Icon(Icons.language_outlined,
                                    size: 18, color: textMuted),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    t.getLocalizedString('language'),
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
                                    value: t.language,
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
                                      if (newValue != null) {
                                        t.setLanguage(newValue);
                                      }
                                    },
                                    items: [
                                      DropdownMenuItem(
                                        value: 'ru',
                                        child: Text(
                                            t.getLocalizedString('russian')),
                                      ),
                                      DropdownMenuItem(
                                        value: 'en',
                                        child: Text(
                                            t.getLocalizedString('english')),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Создать семейный аккаунт ─────────────────
                      if (account.type == AccountType.personal) ...[
                        const SizedBox(height: 12),
                        _SectionCard(
                          cardColor: cardColor,
                          borderColor: borderColor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(
                                title: t
                                    .getLocalizedString('family_account_title'),
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
                                decoration: InputDecoration(
                                  labelText:
                                      t.getLocalizedString('family_name_label'),
                                  hintText:
                                      t.getLocalizedString('family_name_hint'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _createFamilyAccount,
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label:
                                      Text(t.getLocalizedString('create_btn')),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const FamilyRequestScreen(),
                                    ),
                                  ),
                                  icon: const Icon(Icons.search_rounded,
                                      size: 18),
                                  label:
                                      Text(t.getLocalizedString('join_family')),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    side: BorderSide(color: accent),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Добавить члена семьи ─────────────────────
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
                                title: t.getLocalizedString('add_member_title'),
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
                                decoration: InputDecoration(
                                  labelText: t
                                      .getLocalizedString('member_email_label'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _addFamilyMember,
                                  icon: const Icon(Icons.person_add_rounded,
                                      size: 18),
                                  label: Text(t.getLocalizedString('add')),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const FamilyManagementScreen(),
                                    ),
                                  ),
                                  icon: const Icon(
                                      Icons.manage_accounts_rounded,
                                      size: 18),
                                  label: Text(
                                      t.getLocalizedString('manage_requests')),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    side: BorderSide(color: accent),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Ошибка ──────────────────────────────────
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

  Widget _buildErrorState(ThemeProvider t, Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.warning),
            const SizedBox(height: 16),
            Text(
              t.getLocalizedString('error'),
              textAlign: TextAlign.center,
              style: GoogleFonts.exo2(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              t.getLocalizedString('leave_family_body'),
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _reloadProfile,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: Text(t.getLocalizedString('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Вспомогательные виджеты ───────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  final Color cardColor, borderColor;

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
  final String label, value;
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
        Text('$label:',
            style: GoogleFonts.nunito(fontSize: 13, color: textSecondary)),
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
