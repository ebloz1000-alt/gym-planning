import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_cards.dart';
import '../../core/widgets/pickers.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/app_models.dart';
import '../../providers_or_bloc/app_state.dart';

class TrainerModuleScreen extends StatefulWidget {
  const TrainerModuleScreen({super.key});

  @override
  State<TrainerModuleScreen> createState() => _TrainerModuleScreenState();
}

class _TrainerModuleScreenState extends State<TrainerModuleScreen> {
  String? _selectedTrainerId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    final state = AppScope.watch(context);
    if (state.currentRole == UserRole.trainer) {
      return _TrainerDashboard(
        selectedDate: _selectedDate,
        onDate: (date) {
          setState(() => _selectedDate = date);
        },
      );
    }
    final trainers = state.repository.trainers;
    return FeaturePage(
      title: 'Trainers',
      subtitle:
          'Profiles, ratings, availability, reviews, and trainer selection.',
      children: [
        ...trainers.map(
          (trainer) => TrainerCard(
            trainer: trainer,
            selected: trainer.id == _selectedTrainerId,
            onSelect: () => setState(() => _selectedTrainerId = trainer.id),
          ),
        ),
        if (_selectedTrainerId != null)
          AppButton(
            label: 'Continue with selected trainer',
            icon: Icons.arrow_forward_outlined,
            expand: true,
            onPressed: () {},
          ),
      ],
    );
  }
}

class _TrainerDashboard extends StatelessWidget {
  const _TrainerDashboard({required this.selectedDate, required this.onDate});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDate;

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: 'Trainer Dashboard',
      subtitle: 'Availability, profile, notifications, and reviews.',
      trailing: const StatusBadge(label: 'Available'),
      children: [
        ResponsiveGrid(
          children: const [
            StatCard(
              label: 'Today status',
              value: 'Open',
              icon: Icons.today_outlined,
              change: 'Active',
            ),
            StatCard(
              label: 'Weekly slots',
              value: '21',
              icon: Icons.calendar_month_outlined,
              change: 'Planned',
            ),
            StatCard(
              label: 'Rating',
              value: '4.9',
              icon: Icons.star_outline,
              change: 'Active',
            ),
            StatCard(
              label: 'Tomorrow edits',
              value: '3',
              icon: Icons.edit_calendar_outlined,
              change: 'Pending',
            ),
          ],
        ),
        const SectionHeader(title: 'Availability calendar'),
        DateChipPicker(
          selectedDate: selectedDate,
          onSelected: onDate,
          days: 14,
        ),
        const SectionHeader(title: 'Edit availability'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tomorrow: ${formatDate(DateTime.now().add(const Duration(days: 1)))}',
              ),
              const SizedBox(height: 10),
              const TimeSlotPicker(
                selectedSlot: '07:00',
                onSelected: _noopSlot,
                availableSlots: ['07:00', '12:00', '18:00'],
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Save Availability',
                icon: Icons.save_outlined,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Profile management'),
        const AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person_outline),
            title: Text('Trainer profile'),
            subtitle: Text(
              'Specialty, bio, availability, notifications, and reviews',
            ),
            trailing: Icon(Icons.chevron_right),
          ),
        ),
      ],
    );
  }
}

class TrainerSessionsScreen extends StatelessWidget {
  const TrainerSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.watch(context);
    final sessions = state.repository.bookings;
    final today = sessions.where((booking) {
      return DateUtils.isSameDay(booking.date, DateTime.now());
    }).toList();
    final upcoming = sessions.where((booking) {
      return booking.status != BookingStatus.completed &&
          !DateUtils.isSameDay(booking.date, DateTime.now());
    }).toList();

    return FeaturePage(
      title: 'My Sessions',
      subtitle: 'Client sessions, equipment assignments, and status tracking.',
      children: [
        ResponsiveGrid(
          children: [
            StatCard(
              label: 'Today',
              value: '${today.length}',
              icon: Icons.today_outlined,
              change: today.isEmpty ? 'Open' : 'Booked',
            ),
            StatCard(
              label: 'Upcoming',
              value: '${upcoming.length}',
              icon: Icons.event_note_outlined,
              change: 'Planned',
            ),
            const StatCard(
              label: 'Completion',
              value: '92%',
              icon: Icons.task_alt_outlined,
              change: 'Strong',
            ),
            const StatCard(
              label: 'Feedback',
              value: '4.9',
              icon: Icons.star_outline,
              change: 'Elite',
            ),
          ],
        ),
        const SectionHeader(title: 'Today'),
        if (today.isEmpty)
          const AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.event_available_outlined),
              title: Text('No sessions today'),
              subtitle: Text('Your schedule is open for new bookings.'),
            ),
          )
        else
          ...today.map(
            (booking) =>
                BookingTile(booking: booking, showPaymentStatus: false),
          ),
        const SectionHeader(title: 'Upcoming'),
        ...upcoming.map(
          (booking) => BookingTile(booking: booking, showPaymentStatus: false),
        ),
      ],
    );
  }
}

class TrainerScheduleScreen extends StatefulWidget {
  const TrainerScheduleScreen({super.key});

  @override
  State<TrainerScheduleScreen> createState() => _TrainerScheduleScreenState();
}

class _TrainerScheduleScreenState extends State<TrainerScheduleScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedSlot = '07:00';

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: 'Schedule',
      subtitle: 'Manage availability for member session booking.',
      trailing: const StatusBadge(label: 'Available'),
      children: [
        DateChipPicker(
          selectedDate: _selectedDate,
          onSelected: (date) => setState(() => _selectedDate = date),
          days: 14,
        ),
        const SectionHeader(title: 'Availability slots'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatDate(_selectedDate),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TimeSlotPicker(
                selectedSlot: _selectedSlot,
                onSelected: (value) => setState(() => _selectedSlot = value),
                availableSlots: const ['07:00', '12:00', '18:00'],
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Save Schedule',
                icon: Icons.save_outlined,
                expand: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _noopSlot(String value) {}
