import 'package:flutter/material.dart';
import '../../core/utils/responsive_helper.dart';

class VirtualClassesPage extends StatefulWidget {
  const VirtualClassesPage({super.key});

  @override
  State<VirtualClassesPage> createState() => _VirtualClassesPageState();
}

class _VirtualClassesPageState extends State<VirtualClassesPage> {
  final List<VirtualClass> liveClasses = [
    VirtualClass(
      id: '1',
      title: 'Morning Yoga Flow',
      instructor: 'Emma Wellness',
      duration: 45,
      participantCount: 234,
      startTime: DateTime.now(),
      icon: '🧘‍♀️',
      isLive: true,
    ),
    VirtualClass(
      id: '2',
      title: 'HIIT Bootcamp',
      instructor: 'Coach Mike',
      duration: 30,
      participantCount: 189,
      startTime: DateTime.now().add(const Duration(hours: 1)),
      icon: '💪',
      isLive: false,
    ),
  ];

  final List<VirtualClass> upcomingClasses = [
    VirtualClass(
      id: '3',
      title: 'Pilates Core',
      instructor: 'Lisa Strong',
      duration: 50,
      participantCount: 156,
      startTime: DateTime.now().add(const Duration(hours: 3)),
      icon: '🤸‍♀️',
    ),
    VirtualClass(
      id: '4',
      title: 'Spinning Pulse',
      instructor: 'DJ Spin',
      duration: 45,
      participantCount: 312,
      startTime: DateTime.now().add(const Duration(hours: 5)),
      icon: '🚴‍♂️',
    ),
    VirtualClass(
      id: '5',
      title: 'Boxing Basics',
      instructor: 'Rocky Chen',
      duration: 40,
      participantCount: 98,
      startTime: DateTime.now().add(const Duration(hours: 7)),
      icon: '🥊',
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
            Text(
              'Virtual Classes',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Join live classes from anywhere',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            // Live Now Section
            if (liveClasses.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[400]!, Colors.red[600]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fiber_manual_record,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LIVE NOW - ${liveClasses[0].participantCount} watching',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCount,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: liveClasses.length,
                itemBuilder: (context, index) =>
                    _ClassCard(vClass: liveClasses[index], isLive: true),
              ),
              const SizedBox(height: 32),
            ],
            // Upcoming Section
            Text(
              'Upcoming Classes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcomingClasses.length,
              itemBuilder: (context, index) =>
                  _ClassListItem(vClass: upcomingClasses[index]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final VirtualClass vClass;
  final bool isLive;

  const _ClassCard({required this.vClass, this.isLive = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Joining ${vClass.title}...')));
        },
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(vClass.icon, style: const TextStyle(fontSize: 32)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vClass.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vClass.instructor,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.people, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${vClass.participantCount}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isLive)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

class _ClassListItem extends StatelessWidget {
  final VirtualClass vClass;

  const _ClassListItem({required this.vClass});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Text(vClass.icon, style: const TextStyle(fontSize: 28)),
        title: Text(vClass.title),
        subtitle: Text('${vClass.instructor} • ${vClass.duration} min'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(vClass.startTime),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '👥 ${vClass.participantCount}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Reserved: ${vClass.title}')));
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class VirtualClass {
  final String id;
  final String title;
  final String instructor;
  final int duration;
  final int participantCount;
  final DateTime startTime;
  final String icon;
  final bool isLive;

  VirtualClass({
    required this.id,
    required this.title,
    required this.instructor,
    required this.duration,
    required this.participantCount,
    required this.startTime,
    required this.icon,
    this.isLive = false,
  });
}
