import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  bool _isLoading = false;
  List<_MealMatch> _mealList = [];
  _Recipe? _recipe;
  String? _error;
  int _step = 0;

  static const Map<String, String> _translateToEn = {
    'курица': 'chicken',
    'говядина': 'beef',
    'свинина': 'pork',
    'рыба': 'fish',
    'лосось': 'salmon',
    'тунец': 'tuna',
    'картофель': 'potato',
    'картошка': 'potato',
    'помидор': 'tomato',
    'томат': 'tomato',
    'огурец': 'cucumber',
    'морковь': 'carrot',
    'лук': 'onion',
    'чеснок': 'garlic',
    'капуста': 'cabbage',
    'рис': 'rice',
    'макароны': 'pasta',
    'яйцо': 'egg',
    'яйца': 'egg',
    'молоко': 'milk',
    'сыр': 'cheese',
    'масло': 'butter',
    'хлеб': 'bread',
    'мука': 'flour',
    'сахар': 'sugar',
    'соль': 'salt',
    'перец': 'pepper',
    'грибы': 'mushroom',
    'гриб': 'mushroom',
    'баклажан': 'aubergine',
    'кабачок': 'courgette',
    'шпинат': 'spinach',
    'салат': 'lettuce',
    'яблоко': 'apple',
    'банан': 'banana',
    'апельсин': 'orange',
    'лимон': 'lemon',
    'клубника': 'strawberry',
    'индейка': 'turkey',
    'утка': 'duck',
    'креветки': 'prawn',
    'креветка': 'prawn',
    'фасоль': 'beans',
    'горох': 'peas',
    'кукуруза': 'corn',
    'авокадо': 'avocado',
    'брокколи': 'broccoli',
    'имбирь': 'ginger',
    'мёд': 'honey',
    'мед': 'honey',
    'йогурт': 'yogurt',
    'сметана': 'sour cream',
    'творог': 'cottage cheese',
    'свёкла': 'beetroot',
    'свекла': 'beetroot',
    'баранина': 'lamb',
    'кролик': 'rabbit',
    'печень': 'liver',
    'колбаса': 'sausage',
    'ветчина': 'ham',
    'бекон': 'bacon',
    'тыква': 'pumpkin',
    'сливки': 'cream',
    'майонез': 'mayonnaise',
    'горчица': 'mustard',
    'уксус': 'vinegar',
    'оливки': 'olives',
    'орехи': 'nuts',
    'миндаль': 'almonds',
    'арахис': 'peanut',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _findRecipes());
  }

  Future<void> _findRecipes() async {
    final products = context.read<ProductProvider>().products;
    final t = context.read<ThemeProvider>();

    if (products.isEmpty) {
      setState(() {
        _error = t.getLocalizedString('fridge_empty_hint');
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _mealList = [];
      _recipe = null;
      _error = null;
      _step = 0;
    });

    final englishIngredients = products
        .map((p) {
          final word = p.name.split(' ').first.toLowerCase();
          return _translateToEn[word] ?? word;
        })
        .toSet()
        .toList();

    final Map<String, _MealMatch> mealMap = {};

    for (final ingredient in englishIngredients) {
      try {
        final url = Uri.parse(
          'https://www.themealdb.com/api/json/v1/1/filter.php?i=${Uri.encodeComponent(ingredient)}',
        );
        final res = await http.get(url);
        final data = json.decode(res.body);
        final meals = data['meals'];
        if (meals == null) continue;

        for (final m in meals) {
          final id = m['idMeal'] as String;
          if (mealMap.containsKey(id)) {
            mealMap[id] = mealMap[id]!.copyWithMatch(ingredient);
          } else {
            mealMap[id] = _MealMatch(
              id: id,
              name: m['strMeal'],
              thumb: m['strMealThumb'] ?? '',
              matchCount: 1,
              matchedIngredients: [ingredient],
            );
          }
        }
      } catch (_) {
        continue;
      }
    }

    if (mealMap.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = t
            .getLocalizedString('no_recipes_for_ingredient')
            .replaceAll('{ingredient}', products.map((p) => p.name).join(', '));
      });
      return;
    }

    final sorted = mealMap.values.toList()
      ..sort((a, b) => b.matchCount.compareTo(a.matchCount));

    setState(() {
      _mealList = sorted.take(15).toList();
      _isLoading = false;
    });
  }

  Future<void> _onMealSelected(String mealId) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _recipe = null;
    });

    try {
      final url = Uri.parse(
        'https://www.themealdb.com/api/json/v1/1/lookup.php?i=$mealId',
      );
      final res = await http.get(url);
      final data = json.decode(res.body);
      final meal = data['meals'][0];

      final ingredients = <String>[];
      for (int i = 1; i <= 20; i++) {
        final ing = meal['strIngredient$i'];
        final measure = meal['strMeasure$i'];
        if (ing != null && ing.toString().trim().isNotEmpty) {
          ingredients.add('${measure?.trim() ?? ''} ${ing.trim()}'.trim());
        }
      }

      final rawInstructions = meal['strInstructions'] ?? '';
      final steps = rawInstructions
          .toString()
          .split(RegExp(r'\r\n|\n|\. '))
          .map((s) => s.trim())
          .where((s) => s.length > 10)
          .take(8)
          .toList()
          .cast<String>();

      setState(() {
        _recipe = _Recipe(
          name: meal['strMeal'] ?? '',
          category: meal['strCategory'] ?? '',
          area: meal['strArea'] ?? '',
          thumb: meal['strMealThumb'] ?? '',
          ingredients: ingredients,
          steps: steps,
        );
        _isLoading = false;
        _step = 1;
      });
    } catch (_) {
      final t = context.read<ThemeProvider>();
      setState(() {
        _isLoading = false;
        _error = t.getLocalizedString('no_internet');
      });
    }
  }

  void _goBack() {
    HapticFeedback.lightImpact();
    setState(() {
      _error = null;
      _step = 0;
      _recipe = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          _BgDecor(),
          SafeArea(
            child: Column(
              children: [
                _Header(
                  step: _step,
                  onBack: _step > 0 ? _goBack : null,
                  onRefresh: _step == 0 ? _findRecipes : null,
                ),
                Expanded(
                  child: _isLoading
                      ? _LoadingView()
                      : _error != null
                          ? _ErrorView(
                              message: _error!,
                              onRetry: () {
                                setState(() => _error = null);
                                _findRecipes();
                              },
                            )
                          : _step == 0
                              ? _MealListView(
                                  meals: _mealList,
                                  onSelect: _onMealSelected,
                                )
                              : _RecipeView(recipe: _recipe!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Модели ───────────────────────────────────────────────────────────────────

class _MealMatch {
  final String id, name, thumb;
  final int matchCount;
  final List<String> matchedIngredients;

  const _MealMatch({
    required this.id,
    required this.name,
    required this.thumb,
    required this.matchCount,
    required this.matchedIngredients,
  });

  _MealMatch copyWithMatch(String ingredient) {
    return _MealMatch(
      id: id,
      name: name,
      thumb: thumb,
      matchCount: matchCount + 1,
      matchedIngredients: [...matchedIngredients, ingredient],
    );
  }
}

class _Recipe {
  final String name, category, area, thumb;
  final List<String> ingredients, steps;
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
  final int step;
  final VoidCallback? onBack;
  final VoidCallback? onRefresh;
  const _Header({required this.step, this.onBack, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack ?? () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).cardTheme.color,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Icon(Icons.arrow_back,
                  color: Theme.of(context).colorScheme.primary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step == 0
                    ? t.getLocalizedString('recipes')
                    : t.getLocalizedString('select_recipe'),
                style: GoogleFonts.exo2(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              Text(
                step == 0
                    ? t.getLocalizedString('recipes_from_fridge')
                    : t.getLocalizedString('cooking_steps_hint'),
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.6)),
              ),
            ],
          ),
          const Spacer(),
          if (onRefresh != null)
            GestureDetector(
              onTap: onRefresh,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.1),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.refresh_rounded,
                    color: AppColors.accent, size: 20),
              ),
            )
          else
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
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍳', style: TextStyle(fontSize: 56))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 800.ms,
              ),
          const SizedBox(height: 20),
          Text(
            t.getLocalizedString('finding_recipe'),
            style: GoogleFonts.exo2(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.getLocalizedString('recipes_from_fridge'),
            style: GoogleFonts.nunito(
                fontSize: 13,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}

class _MealListView extends StatelessWidget {
  final List<_MealMatch> meals;
  final void Function(String) onSelect;
  const _MealListView({required this.meals, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>();
    if (meals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              t.getLocalizedString('fridge_empty'),
              style: GoogleFonts.exo2(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        return GestureDetector(
          onTap: () => onSelect(meal.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                if (meal.thumb.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                    child: Image.network(
                      meal.thumb,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: Theme.of(context).dividerColor,
                        child: const Center(
                            child: Text('🍽️', style: TextStyle(fontSize: 28))),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.name,
                          style: GoogleFonts.exo2(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        if (meal.matchCount > 1) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '✓ ${meal.matchCount} ${t.getLocalizedString('ingredients_match')}',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      color: AppColors.textMuted, size: 14),
                ),
              ],
            ),
          )
              .animate(delay: Duration(milliseconds: index * 40))
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.1, end: 0),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(t.getLocalizedString('retry')),
          ),
        ],
      ),
    );
  }
}

class _RecipeView extends StatelessWidget {
  final _Recipe recipe;
  const _RecipeView({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>();
    // Используем цвета темы вместо AppColors константных
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ??
        Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color ??
        Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    final cardColor = Theme.of(context).cardTheme.color ??
        Theme.of(context).colorScheme.surface;
    final borderColor = Theme.of(context).dividerColor;

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
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                      child: Text('🍽️', style: TextStyle(fontSize: 48))),
                ),
              ),
            ).animate().fadeIn(duration: 500.ms),

          const SizedBox(height: 16),

          // Название
          Text(
            recipe.name,
            style: GoogleFonts.exo2(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
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
          ),

          const SizedBox(height: 24),

          // Заголовок ингредиентов
          Row(
            children: [
              const Text('🧂', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                t.getLocalizedString('ingredients'),
                style: GoogleFonts.exo2(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Список ингредиентов — карточки
          ...recipe.ingredients.asMap().entries.map(
                (e) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
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
                          e.value,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            // ← ГЛАВНОЕ ИСПРАВЛЕНИЕ: используем цвет темы
                            color: textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: Duration(milliseconds: 100 + e.key * 40)),
              ),

          const SizedBox(height: 24),

          // Заголовок приготовления
          Row(
            children: [
              const Text('👨‍🍳', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                t.getLocalizedString('cooking'),
                style: GoogleFonts.exo2(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Шаги приготовления
          ...recipe.steps.asMap().entries.map(
                (e) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.4)),
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: GoogleFonts.exo2(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          e.value,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            // ← ГЛАВНОЕ ИСПРАВЛЕНИЕ: используем цвет темы
                            color: textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: Duration(milliseconds: 200 + e.key * 50)),
              ),

          const SizedBox(height: 24),
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
