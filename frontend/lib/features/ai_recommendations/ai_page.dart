import 'package:flutter/material.dart';
import '../../core/utils/responsive_helper.dart';

class AIRecommendationsPage extends StatefulWidget {
  const AIRecommendationsPage({super.key});

  @override
  State<AIRecommendationsPage> createState() => _AIRecommendationsPageState();
}

class _AIRecommendationsPageState extends State<AIRecommendationsPage> {
  final List<Recommendation> recommendations = [
    Recommendation(
      id: '1',
      title: 'Back Day Focused',
      description:
          'Your form has improved on pull-ups. Time to increase intensity.',
      reason: 'Based on your last 5 workouts',
      icon: '🎯',
      confidence: 92,
    ),
    Recommendation(
      id: '2',
      title: 'Rest & Recovery',
      description:
          'You\'ve worked hard lately. A light recovery session recommended.',
      reason: 'Pattern analysis shows overtraining',
      icon: '😴',
      confidence: 85,
    ),
    Recommendation(
      id: '3',
      title: 'New Exercise: Deadlifts',
      description: 'Add deadlifts to complement your current routine.',
      reason: 'Completes your training balance',
      icon: '⛓️',
      confidence: 78,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);

    return SingleChildScrollView(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Recommendations',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Personalized workout recommendations powered by AI',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            // Stats Cards
            _StatsGrid(),
            const SizedBox(height: 32),
            // Recommendations List
            Text(
              'Your AI-Generated Plans',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recommendations.length,
              itemBuilder: (context, index) =>
                  _RecommendationCard(rec: recommendations[index]),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gridCount = ResponsiveHelper.isMobile(context) ? 2 : 4;

    return GridView.count(
      crossAxisCount: gridCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _StatCard(label: 'Consistency', value: '92%', icon: '📊'),
        _StatCard(label: 'Improvement', value: '+18%', icon: '📈'),
        _StatCard(label: 'Weekly Goal', value: '4/5', icon: '🎯'),
        _StatCard(label: 'AI Score', value: '8.7/10', icon: '⭐'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Recommendation rec;

  const _RecommendationCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Starting: ${rec.title}')));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(rec.icon, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          rec.reason,
                          style: Theme.of(context).textTheme.bodySmall,
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
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${rec.confidence}%',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                rec.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Start Workout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Recommendation {
  final String id;
  final String title;
  final String description;
  final String reason;
  final String icon;
  final int confidence;

  Recommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.reason,
    required this.icon,
    required this.confidence,
  });
}
