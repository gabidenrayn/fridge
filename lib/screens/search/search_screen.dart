import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/product_card.dart';
import '../product/product_form_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>();
    final provider = context.watch<ProductProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.getLocalizedString('search_title'),
                    style: GoogleFonts.exo2(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.surface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isDark
                              ? AppColors.border
                              : AppColors.lightBorder),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: GoogleFonts.nunito(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.lightTextPrimary),
                      decoration: InputDecoration(
                        hintText: t.getLocalizedString('search_placeholder'),
                        hintStyle: GoogleFonts.nunito(
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.lightTextMuted),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.lightTextMuted),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  provider.setSearch('');
                                },
                                child: Icon(Icons.close_rounded,
                                    color: isDark
                                        ? AppColors.textMuted
                                        : AppColors.lightTextMuted),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      onChanged: (q) {
                        setState(() {});
                        provider.setSearch(q);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TabBar(
                controller: _tabCtrl,
                indicatorColor: AppColors.accent,
                indicatorWeight: 2,
                labelColor: AppColors.accent,
                unselectedLabelColor:
                    isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                labelStyle: GoogleFonts.exo2(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8),
                tabs: [
                  Tab(text: t.getLocalizedString('tab_all')),
                  Tab(text: t.getLocalizedString('tab_expiring')),
                  Tab(text: t.getLocalizedString('tab_expired')),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _ProductList(
                    products: provider.products,
                    onTap: (p) => _openProduct(context, p),
                    onDelete: (p) => provider.deleteProduct(p),
                    emptyMessage: t.getLocalizedString('not_found'),
                  ),
                  _ProductList(
                    products: provider.warningProducts,
                    onTap: (p) => _openProduct(context, p),
                    onDelete: (p) => provider.deleteProduct(p),
                    emptyMessage: t.getLocalizedString('no_expiring'),
                  ),
                  _ProductList(
                    products: provider.expiredProducts,
                    onTap: (p) => _openProduct(context, p),
                    onDelete: (p) => provider.deleteProduct(p),
                    emptyMessage: t.getLocalizedString('no_expired'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProduct(BuildContext context, ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    ).then((_) => context.read<ProductProvider>().loadProducts());
  }
}

class _ProductList extends StatelessWidget {
  final List<ProductModel> products;
  final ValueChanged<ProductModel> onTap;
  final ValueChanged<ProductModel> onDelete;
  final String emptyMessage;

  const _ProductList({
    required this.products,
    required this.onTap,
    required this.onDelete,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: GoogleFonts.nunito(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textMuted
                  : AppColors.lightTextMuted,
              fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: products.length,
      itemBuilder: (ctx, i) => ProductCard(
        product: products[i],
        index: i,
        onTap: () => onTap(products[i]),
        onDelete: () => onDelete(products[i]),
      ),
    );
  }
}
