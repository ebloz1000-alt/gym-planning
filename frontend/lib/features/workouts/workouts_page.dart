import 'package:flutter/material.dart';
import '../../core/utils/responsive_helper.dart';

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  final List<Workout> workouts = [
    Workout(
      id: '1',
      name: 'Upper Body Strength',
      duration: 45,
      level: 'Intermediate',
      calories: 320,
      image: '💪',
      description: 'Build muscle with effective exercises',
      isActive: true,
    ),
    Workout(
      id: '2',
      name: 'HIIT Cardio Blast',
      duration: 30,
      level: 'Advanced',
      calories: 400,
      image: '🔥',
      description: 'High-intensity interval training',
    ),
    Workout(
      id: '3',
      name: 'Yoga & Flexibility',
      duration: 50,
      level: 'Beginner',
      calories: 150,
      image: '🧘',
      description: 'Improve flexibility and balance',
    ),
    Workout(
      id: '4',
      name: 'Core Intensive',
      duration: 35,
      level: 'Intermediate',
      calories: 280,
      image: '⭐',
      description: 'Strengthen your core',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final gridCount = ResponsiveHelper.getGridCrossAxisCount(context);
    final padding = ResponsiveHelper.getResponsivePadding(context);

    return SingleChildScrollView(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Workouts', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 8),
            Text(
              'Choose from our premium workout collection',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridCount,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: workouts.length,
              itemBuilder: (context, index) =>
                  _WorkoutCard(workout: workouts[index]),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;

  const _WorkoutCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Starting ${workout.name}...')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(workout.image, style: const TextStyle(fontSize: 32)),
                  if (workout.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Popular',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                workout.name,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _InfoChip(icon: '⏱️', label: '${workout.duration} min'),
                  _InfoChip(icon: '🔥', label: '${workout.calories} cal'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Text(icon),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      side: BorderSide.none,
    );
  }
}

class Workout {
  final String id;
  final String name;
  final int duration;
  final String level;
  final int calories;
  final String image;
  final String description;
  final bool isActive;

  Workout({
    required this.id,
    required this.name,
    required this.duration,
    required this.level,
    required this.calories,
    required this.image,
    required this.description,
    this.isActive = false,
  });
}
