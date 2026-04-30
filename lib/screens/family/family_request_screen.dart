import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class FamilyRequestScreen extends StatefulWidget {
  const FamilyRequestScreen({super.key});

  @override
  State<FamilyRequestScreen> createState() => _FamilyRequestScreenState();
}

class _FamilyRequestScreenState extends State<FamilyRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  String? _sendingId;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.trim();
    if (query.length >= 2) {
      _searchFamilies(query);
    } else {
      setState(() {
        _searchResults = [];
        _searchError = null;
      });
    }
  }

  Future<void> _searchFamilies(String query) async {
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      final q = query.toLowerCase();
      final snapshot = await FirebaseFirestore.instance
          .collection('accounts')
          .where('nameLower', isGreaterThanOrEqualTo: q)
          .where('nameLower', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(20)
          .get();

      final results = snapshot.docs
          .where((doc) => doc.data()['type'] == 'family')
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() {
        _isSearching = false;
        _searchError = 'error';
      });
    }
  }

  Future<void> _sendRequest(
      String familyId, String familyName, String sentLabel) async {
    setState(() => _sendingId = familyId);
    final error = await context.read<AuthProvider>().sendFamilyJoinRequest(
          familyId: familyId,
          message: _messageCtrl.text.trim(),
        );
    setState(() => _sendingId = null);
    if (!mounted) return;
    final t = context.read<ThemeProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            error ?? '${t.getLocalizedString('request_sent')} «$familyName»'),
        backgroundColor: error != null ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accent : AppColors.lightAccent;
    final cardColor = isDark ? AppColors.surface : AppColors.lightCardBg;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).appBarTheme.foregroundColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.getLocalizedString('join_family'),
          style: GoogleFonts.exo2(
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Tab Bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: textMuted,
                padding: const EdgeInsets.all(3),
                labelStyle:
                    GoogleFonts.exo2(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle:
                    GoogleFonts.exo2(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: [
                  Tab(text: t.getLocalizedString('tab_search')),
                  Tab(text: t.getLocalizedString('tab_my_requests')),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // ── TAB 1: Search ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    children: [
                      // Поле поиска
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          style: TextStyle(
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.lightTextPrimary),
                          decoration: InputDecoration(
                            hintText:
                                t.getLocalizedString('search_family_hint'),
                            hintStyle:
                                TextStyle(color: textMuted, fontSize: 14),
                            prefixIcon:
                                Icon(Icons.search_rounded, color: textMuted),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear_rounded,
                                        color: textMuted, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchResults = []);
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Поле сообщения
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          controller: _messageCtrl,
                          maxLines: 2,
                          style: TextStyle(
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.lightTextPrimary),
                          decoration: InputDecoration(
                            hintText: t.getLocalizedString('optional_message'),
                            hintStyle:
                                TextStyle(color: textMuted, fontSize: 13),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Icon(Icons.chat_bubble_outline_rounded,
                                  color: textMuted, size: 18),
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.fromLTRB(4, 14, 14, 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Результаты
                      Expanded(
                        child: _isSearching
                            ? Center(
                                child: CircularProgressIndicator(
                                    color: accent, strokeWidth: 2))
                            : _searchError != null
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.wifi_off_rounded,
                                            size: 48, color: textMuted),
                                        const SizedBox(height: 12),
                                        Text(
                                          t.getLocalizedString('search_error'),
                                          style: GoogleFonts.nunito(
                                              color: textMuted, fontSize: 13),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        TextButton(
                                          onPressed: () => _searchFamilies(
                                              _searchCtrl.text.trim()),
                                          child: Text(
                                            t.getLocalizedString('retry'),
                                            style: TextStyle(color: accent),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : _searchResults.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text('🔍',
                                                style: TextStyle(fontSize: 48)),
                                            const SizedBox(height: 12),
                                            Text(
                                              _searchCtrl.text.length < 2
                                                  ? t.getLocalizedString(
                                                      'search_min_chars')
                                                  : t.getLocalizedString(
                                                      'families_not_found'),
                                              style: GoogleFonts.nunito(
                                                  color: textMuted,
                                                  fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _searchResults.length,
                                        itemBuilder: (ctx, i) {
                                          final fam = _searchResults[i];
                                          final famId = fam['id'] as String;
                                          final famName =
                                              fam['name'] as String? ??
                                                  'Family';
                                          final memberCount =
                                              (fam['memberIds'] as List?)
                                                      ?.length ??
                                                  0;
                                          return Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 10),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: cardColor,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                  color: borderColor),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        accent.withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                      Icons.group_rounded,
                                                      color: accent,
                                                      size: 20),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        famName,
                                                        style: GoogleFonts.exo2(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: isDark
                                                              ? AppColors
                                                                  .textPrimary
                                                              : AppColors
                                                                  .lightTextPrimary,
                                                        ),
                                                      ),
                                                      Text(
                                                        '$memberCount ${t.getLocalizedString('members_count')}',
                                                        style:
                                                            GoogleFonts.nunito(
                                                          fontSize: 12,
                                                          color: textMuted,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                _sendingId == famId
                                                    ? SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: accent,
                                                        ),
                                                      )
                                                    : ElevatedButton(
                                                        onPressed: () => _sendRequest(
                                                            famId,
                                                            famName,
                                                            t.getLocalizedString(
                                                                'request_sent')),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              accent,
                                                          foregroundColor:
                                                              Colors.white,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      14,
                                                                  vertical: 8),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                          minimumSize:
                                                              Size.zero,
                                                          tapTargetSize:
                                                              MaterialTapTargetSize
                                                                  .shrinkWrap,
                                                        ),
                                                        child: Text(
                                                          t.getLocalizedString(
                                                              'join_btn'),
                                                          style:
                                                              GoogleFonts.exo2(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                      ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                      ),
                    ],
                  ),
                ),

                // ── TAB 2: My Requests ─────────────────────────
                _MyRequestsTab(accent: accent, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── My Requests Tab ────────────────────────────────────────────────────────

class _MyRequestsTab extends StatelessWidget {
  final Color accent;
  final bool isDark;

  const _MyRequestsTab({required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final userId = auth.userModel?.id;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final cardColor = isDark ? AppColors.surface : AppColors.lightCardBg;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;

    if (userId == null) {
      return Center(
        child: Text(
          t.getLocalizedString('not_authorized'),
          style: GoogleFonts.nunito(color: textMuted),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('familyRequests')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: accent, strokeWidth: 2));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📭', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  t.getLocalizedString('no_requests'),
                  style: GoogleFonts.nunito(color: textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final status = data['status'] as String? ?? 'pending';
            final familyName = data['familyName'] as String? ?? 'Family';

            Color statusColor;
            String statusLabel;
            IconData statusIcon;
            switch (status) {
              case 'accepted':
                statusColor = Colors.green;
                statusLabel = t.getLocalizedString('request_accepted');
                statusIcon = Icons.check_circle_outline;
                break;
              case 'rejected':
                statusColor = Colors.red;
                statusLabel = t.getLocalizedString('request_rejected');
                statusIcon = Icons.cancel_outlined;
                break;
              default:
                statusColor = accent;
                statusLabel = t.getLocalizedString('request_pending');
                statusIcon = Icons.hourglass_empty_rounded;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.group_rounded, color: accent, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          familyName,
                          style: GoogleFonts.exo2(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        if ((data['message'] as String?)?.isNotEmpty == true)
                          Text(
                            data['message'],
                            style: GoogleFonts.nunito(
                                fontSize: 12, color: textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: GoogleFonts.exo2(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
