import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product;
  final String? initialName;
  final String? initialBrand;
  final String? barcode;
  final ProductCategory? initialCategory;

  const ProductFormScreen({
    super.key,
    this.product,
    this.initialName,
    this.initialBrand,
    this.barcode,
    this.initialCategory,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _noteCtrl;

  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  DateTime _purchaseDate = DateTime.now();
  String _unit = 'шт';
  ProductCategory _category = ProductCategory.other;
  String? _imagePath;

  bool get _isEditing => widget.product != null;

  static const List<String> _units = ['шт', 'г', 'кг', 'мл', 'л', 'уп'];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl =
        TextEditingController(text: p?.name ?? widget.initialName ?? '');
    _brandCtrl =
        TextEditingController(text: p?.brand ?? widget.initialBrand ?? '');
    _quantityCtrl = TextEditingController(text: (p?.quantity ?? 1).toString());
    _noteCtrl = TextEditingController(text: p?.note ?? '');
    if (p != null) {
      _expiryDate = p.expiryDate;
      _purchaseDate = p.purchaseDate;
      _unit = p.unit;
      _category = p.category;
    } else if (widget.initialCategory != null) {
      _category = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _quantityCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProductProvider>();
    final product = ProductModel(
      id: widget.product?.id,
      name: _nameCtrl.text.trim(),
      brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
      barcode: widget.barcode ?? widget.product?.barcode,
      expiryDate: _expiryDate,
      purchaseDate: _purchaseDate,
      quantity: double.tryParse(_quantityCtrl.text) ?? 1,
      unit: _unit,
      category: _category,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      imagePath: _imagePath,
      isFavorite: widget.product?.isFavorite ?? false,
    );

    if (_isEditing) {
      await provider.updateProduct(product);
    } else {
      await provider.addProduct(product);
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _pickDate(bool isExpiry) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: isExpiry ? _expiryDate : _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: isDark
            ? ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.accent,
                  surface: AppColors.surface,
                ),
              )
            : ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.lightAccent,
                  surface: AppColors.lightSurface,
                ),
              ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _purchaseDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _FormHeader(
              isEditing: _isEditing,
              onBack: () => Navigator.pop(context),
              onSave: _save,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название
                      _FieldLabel(t.getLocalizedString('product_name_label')),
                      _StyledTextField(
                        controller: _nameCtrl,
                        hint: t.getLocalizedString('product_name_hint'),
                        validator: (v) => v == null || v.isEmpty
                            ? t.getLocalizedString('product_name_required')
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Бренд
                      _FieldLabel(t.getLocalizedString('brand_label')),
                      _StyledTextField(
                        controller: _brandCtrl,
                        hint: t.getLocalizedString('brand_hint'),
                      ),
                      const SizedBox(height: 16),

                      // Количество + единицы
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FieldLabel(
                                    t.getLocalizedString('quantity_label')),
                                _StyledTextField(
                                  controller: _quantityCtrl,
                                  hint: '1',
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(t.getLocalizedString('unit_label')),
                              _UnitDropdown(
                                value: _unit,
                                units: _units,
                                onChanged: (v) => setState(() => _unit = v!),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Категория
                      _FieldLabel(t.getLocalizedString('category_label')),
                      _CategorySelector(
                        selected: _category,
                        onChanged: (c) => setState(() => _category = c),
                      ),
                      const SizedBox(height: 16),

                      // Даты
                      Row(
                        children: [
                          Expanded(
                            child: _DateButton(
                              label: t.getLocalizedString('purchase_date'),
                              date: _purchaseDate,
                              onTap: () => _pickDate(false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateButton(
                              label: t.getLocalizedString('expiry_date'),
                              date: _expiryDate,
                              onTap: () => _pickDate(true),
                              isExpiry: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Заметка
                      _FieldLabel(t.getLocalizedString('note_label')),
                      _StyledTextField(
                        controller: _noteCtrl,
                        hint: t.getLocalizedString('note_hint'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Вспомогательные виджеты формы ───────────────────────────────────

class _FormHeader extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onBack, onSave;

  const _FormHeader({
    required this.isEditing,
    required this.onBack,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textSecondaryColor =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textPrimaryColor =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final accentColor = isDark ? AppColors.accent : AppColors.lightAccent;
    final accentDarkColor =
        isDark ? AppColors.accentDark : AppColors.lightAccentDark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: textSecondaryColor, size: 16),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            isEditing
                ? t.getLocalizedString('edit_product')
                : t.getLocalizedString('new_product'),
            style: GoogleFonts.exo2(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimaryColor,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSave,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  accentColor,
                  accentDarkColor,
                ]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                t.getLocalizedString('save'),
                style: GoogleFonts.exo2(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMutedColor =
        isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.exo2(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textMutedColor,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textMutedColor =
        isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final surfaceColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final accentColor = isDark ? AppColors.accent : AppColors.lightAccent;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.nunito(color: textPrimaryColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(color: textMutedColor, fontSize: 14),
        filled: true,
        fillColor: surfaceColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor),
        ),
      ),
    );
  }
}

class _UnitDropdown extends StatelessWidget {
  final String value;
  final List<String> units;
  final ValueChanged<String?> onChanged;

  const _UnitDropdown({
    required this.value,
    required this.units,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textPrimaryColor =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: surfaceColor,
          style: GoogleFonts.exo2(color: textPrimaryColor, fontSize: 14),
          items: units
              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final ProductCategory selected;
  final ValueChanged<ProductCategory> onChanged;

  const _CategorySelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final accentColor = isDark ? AppColors.accent : AppColors.lightAccent;
    final textSecondaryColor =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final t = context.watch<ThemeProvider>();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ProductCategory.values.map((cat) {
        final isSelected = cat == selected;
        return GestureDetector(
          onTap: () => onChanged(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? accentColor.withOpacity(0.2) : surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? accentColor : borderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(cat.icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  t.getLocalizedString('cat_${cat.name}'),
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: isSelected ? accentColor : textSecondaryColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  final bool isExpiry;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
    this.isExpiry = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final accentColor = isDark ? AppColors.accent : AppColors.lightAccent;
    final textMutedColor =
        isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final textPrimaryColor =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final fmt = DateFormat('dd.MM.yyyy');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpiry ? accentColor.withOpacity(0.4) : borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.exo2(
                fontSize: 9,
                color: textMutedColor,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isExpiry
                      ? Icons.event_busy_rounded
                      : Icons.shopping_bag_outlined,
                  size: 14,
                  color: isExpiry ? accentColor : textMutedColor,
                ),
                const SizedBox(width: 6),
                Text(
                  fmt.format(date),
                  style: GoogleFonts.exo2(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
