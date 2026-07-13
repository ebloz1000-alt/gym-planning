import 'package:flutter/material.dart';
import '../../core/utils/responsive_helper.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  final List<PremiumFeature> features = [
    PremiumFeature(
      id: '1',
      title: 'Ad-Free Experience',
      description: 'Enjoy uninterrupted workouts without ads',
      icon: '🚫',
    ),
    PremiumFeature(
      id: '2',
      title: 'Exclusive Workouts',
      description: 'Access 500+ premium workout videos',
      icon: '🎬',
    ),
    PremiumFeature(
      id: '3',
      title: 'AI Personal Trainer',
      description: 'Get custom workout plans tailored to you',
      icon: '🤖',
    ),
    PremiumFeature(
      id: '4',
      title: 'Offline Downloads',
      description: 'Download workouts to watch anywhere',
      icon: '📥',
    ),
    PremiumFeature(
      id: '5',
      title: 'Priority Support',
      description: '24/7 priority customer support',
      icon: '⭐',
    ),
    PremiumFeature(
      id: '6',
      title: 'Advanced Analytics',
      description: 'Detailed workout statistics and insights',
      icon: '📊',
    ),
  ];

  final List<PremiumWorkout> premiumWorkouts = [
    PremiumWorkout(
      id: '1',
      title: 'Full Body Transformation',
      trainer: 'Alex Turner',
      duration: 60,
      level: 'Intermediate',
      rating: 4.9,
      reviews: 1240,
      image: '🏋️‍♂️',
      isNew: true,
    ),
    PremiumWorkout(
      id: '2',
      title: 'Core Strength Mastery',
      trainer: 'Sarah Liu',
      duration: 45,
      level: 'Advanced',
      rating: 4.8,
      reviews: 987,
      image: '💪',
    ),
    PremiumWorkout(
      id: '3',
      title: 'Yoga for Athletes',
      trainer: 'Maya Patel',
      duration: 50,
      level: 'Beginner',
      rating: 4.7,
      reviews: 2156,
      image: '🧘‍♀️',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final gridCount = ResponsiveHelper.getGridCrossAxisCount(context);
    final padding = ResponsiveHelper.getResponsivePadding(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            padding: padding + const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Text('✨', style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 16),
                Text(
                  'Premium Membership',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlock your full potential',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Free 7-Day Trial',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                // Pricing Cards
                _PricingSection(),
                const SizedBox(height: 48),
                // Features Grid
                Text(
                  'Premium Features',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridCount > 2 ? 3 : gridCount,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: features.length,
                  itemBuilder: (context, index) =>
                      _FeatureCard(feature: features[index]),
                ),
                const SizedBox(height: 48),
                // Premium Workouts
                Text(
                  'Premium Workouts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: premiumWorkouts.length,
                  itemBuilder: (context, index) =>
                      _PremiumWorkoutCard(workout: premiumWorkouts[index]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingSection extends StatefulWidget {
  @override
  State<_PricingSection> createState() => _PricingSectionState();
}

class _PricingSectionState extends State<_PricingSection> {
  int selectedPlan = 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Monthly'),
            const SizedBox(width: 16),
            Switch(
              value: selectedPlan != 0,
              onChanged: (value) {
                setState(() {
                  selectedPlan = value ? 2 : 0;
                });
              },
            ),
            const SizedBox(width: 16),
            Text('Yearly'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Save 40%',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: [
            _PricingCard(
              duration: 'Monthly',
              price: '\$9.99',
              description: 'per month',
              isPopular: false,
              onSelect: () {
                setState(() => selectedPlan = 0);
              },
              isSelected: selectedPlan == 0,
            ),
            _PricingCard(
              duration: '3 Months',
              price: '\$24.99',
              description: 'per 3 months',
              isPopular: true,
              onSelect: () {
                setState(() => selectedPlan = 1);
              },
              isSelected: selectedPlan == 1,
            ),
            _PricingCard(
              duration: 'Yearly',
              price: '\$59.99',
              description: 'per year',
              isPopular: false,
              onSelect: () {
                setState(() => selectedPlan = 2);
              },
              isSelected: selectedPlan == 2,
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Starting 7-day free trial of plan $selectedPlan...',
                  ),
                ),
              );
            },
            child: const Text('Start Free Trial'),
          ),
        ),
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String duration;
  final String price;
  final String description;
  final bool isPopular;
  final VoidCallback onSelect;
  final bool isSelected;

  const _PricingCard({
    required this.duration,
    required this.price,
    required this.description,
    required this.isPopular,
    required this.onSelect,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Card(
        elevation: isSelected ? 8 : 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'POPULAR',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const SizedBox(height: 20),
              const SizedBox(height: 8),
              Text(
                duration,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                price,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final PremiumFeature feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(feature.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              feature.title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              feature.description,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumWorkoutCard extends StatelessWidget {
  final PremiumWorkout workout;

  const _PremiumWorkoutCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(workout.image, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          workout.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (workout.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NEW',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    workout.trainer,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '⏱️ ${workout.duration}min',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '⭐ ${workout.rating}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '(${workout.reviews})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumFeature {
  final String id;
  final String title;
  final String description;
  final String icon;

  PremiumFeature({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class PremiumWorkout {
  final String id;
  final String title;
  final String trainer;
  final int duration;
  final String level;
  final double rating;
  final int reviews;
  final String image;
  final bool isNew;

  PremiumWorkout({
    required this.id,
    required this.title,
    required this.trainer,
    required this.duration,
    required this.level,
    required this.rating,
    required this.reviews,
    required this.image,
    this.isNew = false,
  });
}
