import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';

/// Экран добавления / редактирования продукта
class ProductFormScreen extends StatefulWidget {
  final ProductModel? product;
  final String? initialName;
  final String? initialBrand;
  final String? barcode;

  const ProductFormScreen({
    super.key,
    this.product,
    this.initialName,
    this.initialBrand,
    this.barcode,
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
      _imagePath = p.imagePath;
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) setState(() => _imagePath = file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Шапка
            _FormHeader(
              isEditing: _isEditing,
              onBack: () => Navigator.pop(context),
              onSave: _save,
            ),

            // Форма
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название
                      const _FieldLabel('Название продукта'),
                      _StyledTextField(
                        controller: _nameCtrl,
                        hint: 'Введите название',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Укажите название' : null,
                      ),
                      const SizedBox(height: 16),

                      // Бренд
                      const _FieldLabel('Бренд (необязательно)'),
                      _StyledTextField(
                          controller: _brandCtrl, hint: 'Например: Danone'),
                      const SizedBox(height: 16),

                      // Количество + единицы
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('Количество'),
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
                              const _FieldLabel('Единица'),
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
                      const _FieldLabel('Категория'),
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
                              label: 'Дата покупки',
                              date: _purchaseDate,
                              onTap: () => _pickDate(false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateButton(
                              label: 'Срок годности',
                              date: _expiryDate,
                              onTap: () => _pickDate(true),
                              isExpiry: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Заметка
                      const _FieldLabel('Заметка (необязательно)'),
                      _StyledTextField(
                        controller: _noteCtrl,
                        hint: 'Любая дополнительная информация...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Фото
                      _PhotoPicker(
                        imagePath: _imagePath,
                        onPick: _pickImage,
                        onRemove: () => setState(() => _imagePath = null),
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
            isEditing ? 'Редактировать' : 'Новый продукт',
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
              child: Text('Сохранить',
                  style: GoogleFonts.exo2(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  )),
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
      child: Text(text,
          style: GoogleFonts.exo2(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textMutedColor,
            letterSpacing: 1,
          )),
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
              .map((u) => DropdownMenuItem(
                    value: u,
                    child: Text(u),
                  ))
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
                Text(cat.label,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: isSelected ? accentColor : textSecondaryColor,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                    )),
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
            Text(label,
                style: GoogleFonts.exo2(
                  fontSize: 9,
                  color: textMutedColor,
                  letterSpacing: 0.8,
                )),
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
                Text(fmt.format(date),
                    style: GoogleFonts.exo2(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimaryColor,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onPick, onRemove;

  const _PhotoPicker({
    required this.imagePath,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final accentColor = isDark ? AppColors.accent : AppColors.lightAccent;
    final textMutedColor =
        isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final expiredColor = isDark ? AppColors.expired : AppColors.lightExpired;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Фото (необязательно)'),
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                style: BorderStyle.solid,
              ),
            ),
            child: imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      children: [
                        // изображение из файла
                        Positioned.fill(
                          child: Icon(Icons.image_rounded,
                              color: accentColor, size: 32),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: onRemove,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: expiredColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            color: textMutedColor, size: 24),
                        const SizedBox(height: 4),
                        Text('Добавить фото',
                            style: GoogleFonts.nunito(
                              color: textMutedColor,
                              fontSize: 11,
                            )),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
