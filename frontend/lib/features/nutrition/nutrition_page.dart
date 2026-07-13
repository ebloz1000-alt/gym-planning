import 'package:flutter/material.dart';
import '../../core/utils/responsive_helper.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final List<MealEntry> meals = [
    MealEntry(
      id: '1',
      name: 'Breakfast',
      items: ['Oatmeal with berries', 'Greek yogurt'],
      calories: 450,
      protein: 18,
      carbs: 62,
      fat: 12,
      icon: '🍳',
    ),
    MealEntry(
      id: '2',
      name: 'Lunch',
      items: ['Grilled chicken', 'Brown rice', 'Vegetables'],
      calories: 620,
      protein: 42,
      carbs: 58,
      fat: 16,
      icon: '🥗',
    ),
    MealEntry(
      id: '3',
      name: 'Snack',
      items: ['Protein shake', 'Banana'],
      calories: 280,
      protein: 25,
      carbs: 32,
      fat: 8,
      icon: '🍌',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    int totalCalories = meals.fold(0, (sum, meal) => sum + meal.calories);
    int totalProtein = meals.fold(0, (sum, meal) => sum + meal.protein);
    int totalCarbs = meals.fold(0, (sum, meal) => sum + meal.carbs);
    int totalFat = meals.fold(0, (sum, meal) => sum + meal.fat);

    return SingleChildScrollView(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition Tracking',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Track your daily nutrition intake',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            // Daily Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Today\'s Summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        width: 150,
                        height: 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: totalCalories / 2500,
                                strokeWidth: 12,
                                valueColor: AlwaysStoppedAnimation(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$totalCalories',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '/ 2500 cal',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Macro breakdown
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _MacroCard(
                          label: 'Protein',
                          value: totalProtein,
                          unit: 'g',
                          icon: '🥚',
                          color: Colors.red,
                        ),
                        _MacroCard(
                          label: 'Carbs',
                          value: totalCarbs,
                          unit: 'g',
                          icon: '🍚',
                          color: Colors.blue,
                        ),
                        _MacroCard(
                          label: 'Fat',
                          value: totalFat,
                          unit: 'g',
                          icon: '🥑',
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Meals Log
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meals Log',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                FilledButton.tonal(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add meal functionality')),
                    );
                  },
                  child: const Text('+ Add Meal'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: meals.length,
              itemBuilder: (context, index) => _MealCard(meal: meals[index]),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final String icon;
  final Color color;

  const _MacroCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              '$value$unit',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealEntry meal;

  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(meal.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        meal.items.join(' • '),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${meal.calories} cal',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Row(
                  children: [
                    Expanded(
                      flex: meal.protein,
                      child: Container(color: Colors.red),
                    ),
                    Expanded(
                      flex: meal.carbs,
                      child: Container(color: Colors.blue),
                    ),
                    Expanded(
                      flex: meal.fat,
                      child: Container(color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MealEntry {
  final String id;
  final String name;
  final List<String> items;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String icon;

  MealEntry({
    required this.id,
    required this.name,
    required this.items,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.icon,
  });
}
