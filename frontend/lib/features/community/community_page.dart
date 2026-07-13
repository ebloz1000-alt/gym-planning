import 'package:flutter/material.dart';
import '../../core/utils/responsive_helper.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final List<Challenge> challenges = [
    Challenge(
      id: '1',
      title: 'July Strength Challenge',
      description: 'Complete 10 strength workouts this month',
      participants: 342,
      progress: 0.65,
      reward: '🏅 Bronze Badge',
      isJoined: true,
    ),
    Challenge(
      id: '2',
      title: 'Cardio Warrior',
      description: 'Run or cycle 50km this month',
      participants: 512,
      progress: 0.42,
      reward: '🥈 Silver Badge',
      isJoined: false,
    ),
    Challenge(
      id: '3',
      title: 'Consistency Champion',
      description: 'Workout 25 days straight',
      participants: 189,
      progress: 0.88,
      reward: '🥇 Gold Badge',
      isJoined: true,
    ),
  ];

  final List<Member> topMembers = [
    Member(name: 'Alex Runner', points: 4520, avatar: '👨‍🦰', streak: 45),
    Member(name: 'Emma Strong', points: 4120, avatar: '👩‍🦱', streak: 38),
    Member(name: 'Mike Fitness', points: 3890, avatar: '👨‍🦱', streak: 32),
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
            Text('Community', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 8),
            Text(
              'Join challenges and compete with friends',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            // Leaderboard Section
            Text('Leaderboard', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topMembers.length,
              itemBuilder: (context, index) =>
                  _LeaderboardTile(member: topMembers[index], rank: index + 1),
            ),
            const SizedBox(height: 32),
            // Challenges Section
            Text(
              'Active Challenges',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: challenges.length,
              itemBuilder: (context, index) =>
                  _ChallengeCard(challenge: challenges[index]),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final Member member;
  final int rank;

  const _LeaderboardTile({required this.member, required this.rank});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.amber[600], Colors.grey[400], Colors.orange[600]];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors[rank - 1],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(member.avatar, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '🔥 ${member.streak} day streak',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              '${member.points}pts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;

  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    challenge.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(challenge.reward, style: const TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              challenge.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: challenge.progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(challenge.progress * 100).toStringAsFixed(0)}% Complete',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '👥 ${challenge.participants} joined',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        challenge.isJoined
                            ? 'Already joined!'
                            : 'Joined ${challenge.title}!',
                      ),
                    ),
                  );
                },
                child: Text(challenge.isJoined ? 'Joined' : 'Join Challenge'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final int participants;
  final double progress;
  final String reward;
  final bool isJoined;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.participants,
    required this.progress,
    required this.reward,
    required this.isJoined,
  });
}

class Member {
  final String name;
  final int points;
  final String avatar;
  final int streak;

  Member({
    required this.name,
    required this.points,
    required this.avatar,
    required this.streak,
  });
}
