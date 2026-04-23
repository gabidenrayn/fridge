import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _diceCtrl;
  bool _isLoading = false;
  _Recipe? _recipe;
  String? _error;

  @override
  void initState() {
    super.initState();
    _diceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _diceCtrl.dispose();
    super.dispose();
  }

  Future<void> _roll() async {
    if (_isLoading) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
      _recipe = null;
      _error = null;
    });

    // Анимация кубика
    _diceCtrl.reset();
    _diceCtrl.repeat();

    final products = context.read<ProductProvider>().products;

    // Берём случайный ингредиент из холодильника
    if (products.isEmpty) {
      _diceCtrl.stop();
      setState(() {
        _isLoading = false;
        _error = 'Холодильник пуст!\nДобавьте продукты чтобы получить рецепт.';
      });
      return;
    }

    final random = Random();
    final pick = products[random.nextInt(products.length)];
    // Берём первое слово имени продукта — так лучше ищется
    final ingredient = pick.name.split(' ').first.toLowerCase();

    try {
      final result = await _fetchRecipe(ingredient);
      _diceCtrl.stop();
      await _diceCtrl.forward();
      setState(() {
        _recipe = result;
        _isLoading = false;
      });
    } catch (e) {
      _diceCtrl.stop();
      setState(() {
        _isLoading = false;
        _error = 'Не удалось загрузить рецепт.\nПроверьте интернет-соединение.';
      });
    }
  }

  Future<_Recipe> _fetchRecipe(String ingredient) async {
    // Поиск блюд по ингредиенту
    final searchUrl = Uri.parse(
      'https://www.themealdb.com/api/json/v1/1/filter.php?i=$ingredient',
    );
    final searchRes = await http.get(searchUrl);
    if (searchRes.statusCode != 200) throw Exception('Search failed');

    final searchData = json.decode(searchRes.body);
    final meals = searchData['meals'];

    String mealId;
    if (meals == null || meals.isEmpty) {
      // Если по ингредиенту ничего — берём случайный рецепт
      final randomUrl = Uri.parse(
        'https://www.themealdb.com/api/json/v1/1/random.php',
      );
      final randomRes = await http.get(randomUrl);
      final randomData = json.decode(randomRes.body);
      mealId = randomData['meals'][0]['idMeal'];
    } else {
      final random = Random();
      mealId =
          meals[random.nextInt(meals.length > 5 ? 5 : meals.length)]['idMeal'];
    }

    // Детали рецепта
    final detailUrl = Uri.parse(
      'https://www.themealdb.com/api/json/v1/1/lookup.php?i=$mealId',
    );
    final detailRes = await http.get(detailUrl);
    final detailData = json.decode(detailRes.body);
    final meal = detailData['meals'][0];

    // Парсим ингредиенты
    final ingredients = <String>[];
    for (int i = 1; i <= 20; i++) {
      final ing = meal['strIngredient$i'];
      final measure = meal['strMeasure$i'];
      if (ing != null && ing.toString().trim().isNotEmpty) {
        ingredients.add('${measure?.trim() ?? ''} ${ing.trim()}'.trim());
      }
    }

    // Инструкции — разбиваем по предложениям для красоты
    final rawInstructions = meal['strInstructions'] ?? '';
    final steps = rawInstructions
        .toString()
        .split(RegExp(r'\r\n|\n|\. '))
        .map((s) => s.trim())
        .where((s) => s.length > 10)
        .take(6)
        .toList();

    return _Recipe(
      name: meal['strMeal'] ?? 'Рецепт',
      category: meal['strCategory'] ?? '',
      area: meal['strArea'] ?? '',
      thumb: meal['strMealThumb'] ?? '',
      ingredients: ingredients,
      steps: steps.cast<String>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Фон
          _BgDecor(),
          SafeArea(
            child: Column(
              children: [
                _Header(),
                Expanded(
                  child: _isLoading
                      ? _LoadingView(controller: _diceCtrl)
                      : _recipe != null
                          ? _RecipeView(recipe: _recipe!)
                          : _error != null
                              ? _ErrorView(message: _error!)
                              : _IdleView(),
                ),
                // Кнопка кубика
                _RollButton(isLoading: _isLoading, onTap: _roll),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Модель рецепта ───────────────────────────────────────────────────────────

class _Recipe {
  final String name;
  final String category;
  final String area;
  final String thumb;
  final List<String> ingredients;
  final List<String> steps;

  const _Recipe({
    required this.name,
    required this.category,
    required this.area,
    required this.thumb,
    required this.ingredients,
    required this.steps,
  });
}

// ─── Виджеты ─────────────────────────────────────────────────────────────────

class _BgDecor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -80,
      right: -80,
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            AppColors.accent.withValues(alpha: 0.07),
            Colors.transparent,
          ]),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Рецепты',
                style: GoogleFonts.exo2(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              Text(
                'Из продуктов в холодильнике',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.1),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: const Text('🍳', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0);
  }
}

class _IdleView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎲', style: TextStyle(fontSize: 64))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.08, 1.08),
                duration: 1200.ms,
              ),
          const SizedBox(height: 20),
          Text(
            'Нажмите кубик',
            style: GoogleFonts.exo2(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Подберём рецепт из ваших\nпродуктов в холодильнике',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}

class _LoadingView extends StatelessWidget {
  final AnimationController controller;
  const _LoadingView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) => Transform.rotate(
              angle: controller.value * 2 * pi,
              child: const Text('🎲', style: TextStyle(fontSize: 64)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ищем рецепт...',
            style: GoogleFonts.exo2(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 600.ms)
              .then()
              .fadeOut(duration: 600.ms),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _RecipeView extends StatelessWidget {
  final _Recipe recipe;
  const _RecipeView({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фото
          if (recipe.thumb.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                recipe.thumb,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text('🍽️', style: TextStyle(fontSize: 48)),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 500.ms).scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                ),

          const SizedBox(height: 16),

          // Название
          Text(
            recipe.name,
            style: GoogleFonts.exo2(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(
                begin: 0.2,
                end: 0,
              ),

          const SizedBox(height: 8),

          // Теги
          Row(
            children: [
              if (recipe.category.isNotEmpty) _Tag(recipe.category),
              if (recipe.area.isNotEmpty) ...[
                const SizedBox(width: 8),
                _Tag(recipe.area),
              ],
            ],
          ).animate(delay: 150.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 20),

          // Ингредиенты
          _SectionTitle('🧂 Ингредиенты'),
          const SizedBox(height: 10),
          ...recipe.ingredients.asMap().entries.map(
                (e) => _IngredientRow(
                  text: e.value,
                  index: e.key,
                ),
              ),

          const SizedBox(height: 20),

          // Шаги
          _SectionTitle('👨‍🍳 Приготовление'),
          const SizedBox(height: 10),
          ...recipe.steps.asMap().entries.map(
                (e) => _StepRow(
                  step: e.key + 1,
                  text: e.value,
                  index: e.key,
                ),
              ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.exo2(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.accent,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.exo2(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final String text;
  final int index;
  const _IngredientRow({required this.text, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 200 + index * 50))
        .fadeIn(duration: 300.ms)
        .slideX(begin: -0.1, end: 0);
  }
}

class _StepRow extends StatelessWidget {
  final int step;
  final String text;
  final int index;
  const _StepRow({
    required this.step,
    required this.text,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                '$step',
                style: GoogleFonts.exo2(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 300 + index * 60))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

class _RollButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _RollButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isLoading
                ? AppColors.accent.withValues(alpha: 0.5)
                : AppColors.accent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.casino_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                isLoading ? 'Ищем рецепт...' : 'Подобрать рецепт',
                style: GoogleFonts.exo2(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
  }
}
