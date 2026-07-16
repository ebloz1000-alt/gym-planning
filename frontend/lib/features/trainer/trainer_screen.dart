import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_cards.dart';
import '../../core/widgets/pickers.dart';
import '../../core/widgets/state_views.dart';
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
        if (trainers.isEmpty)
          const EmptyStateView(
            title: 'No trainers added',
            message: 'Admins can add trainer accounts through the dashboard.',
            icon: Icons.person_search_outlined,
          )
        else
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

class _TrainerDashboard extends StatefulWidget {
  const _TrainerDashboard({required this.selectedDate, required this.onDate});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDate;

  @override
  State<_TrainerDashboard> createState() => _TrainerDashboardState();
}

class _TrainerDashboardState extends State<_TrainerDashboard> {
  String _selectedAvailabilitySlot = '07:00';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.watch(context);
    final trainer = state.currentTrainerProfile;

    return FeaturePage(
      title: 'Trainer Dashboard',
      subtitle: 'Availability, profile, notifications, and reviews.',
      trailing: const StatusBadge(label: 'Available'),
      children: [
        ResponsiveGrid(
          children: _buildTrainerStats(context),
        ),
        const SectionHeader(title: 'Availability calendar'),
        DateChipPicker(
          selectedDate: widget.selectedDate,
          onSelected: widget.onDate,
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
              TimeSlotPicker(
                selectedSlot: _selectedAvailabilitySlot,
                onSelected: (value) => setState(() => _selectedAvailabilitySlot = value),
                availableSlots: const ['07:00', '12:00', '18:00'],
              ),
              const SizedBox(height: 12),
              if (trainer != null && trainer.availableSlots.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: trainer.availableSlots
                      .map((slot) => Chip(label: Text(slot)))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Save Availability',
                      icon: Icons.save_outlined,
                      onPressed: trainer == null
                          ? null
                          : () {
                              final saved = state.saveTrainerAvailability(
                                trainerId: trainer.id,
                                slot: _selectedAvailabilitySlot,
                              );
                              final message = saved
                                  ? 'Availability saved for $_selectedAvailabilitySlot.'
                                  : 'Slot $_selectedAvailabilitySlot is already saved.';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Withdraw Availability',
                      icon: Icons.remove_circle_outline,
                      variant: AppButtonVariant.secondary,
                      onPressed: trainer == null
                          ? null
                          : () {
                              final withdrawn = state.withdrawTrainerAvailability(
                                trainerId: trainer.id,
                                slot: _selectedAvailabilitySlot,
                              );
                              final message = withdrawn
                                  ? 'Availability removed for $_selectedAvailabilitySlot.'
                                  : 'Slot $_selectedAvailabilitySlot was not active.';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            },
                    ),
                  ),
                ],
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

  List<Widget> _buildTrainerStats(BuildContext context) {
    final state = AppScope.watch(context);
    final sessions = state.repository.bookings;
    final today = sessions.where((b) => DateUtils.isSameDay(b.date, DateTime.now())).length;
    final upcoming = sessions.where((b) => !DateUtils.isSameDay(b.date, DateTime.now()) && b.status != BookingStatus.completed).length;
    final completed = sessions.where((b) => b.status == BookingStatus.completed).length;
    final total = sessions.length;
    final completion = total > 0 ? ((completed / total) * 100).round() : 0;
    final feedbacks = state.repository.feedback;
    final avgRating = feedbacks.isEmpty ? 0.0 : (feedbacks.map((f) => f.rating).reduce((a, b) => a + b) / feedbacks.length);

    return [
      StatCard(label: 'Today', value: '$today', icon: Icons.today_outlined, change: today == 0 ? 'Open' : 'Active'),
      StatCard(label: 'Upcoming', value: '$upcoming', icon: Icons.event_note_outlined, change: 'Planned'),
      StatCard(label: 'Completion', value: '$completion%', icon: Icons.task_alt_outlined, change: 'Recent'),
      StatCard(label: 'Feedback', value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '—', icon: Icons.star_outline, change: 'Live'),
    ];
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
            StatCard(
              label: 'Completion',
              value: sessions.isEmpty ? '0%' : '${((today.length / (sessions.isEmpty ? 1 : sessions.length)) * 100).round()}%',
              icon: Icons.task_alt_outlined,
              change: sessions.isEmpty ? 'No data' : 'Tracked',
            ),
            StatCard(
              label: 'Feedback',
              value: sessions.isEmpty ? '0.0' : (sessions.fold<double>(0, (sum, booking) => sum + (booking.status == BookingStatus.completed ? 1 : 0)) / sessions.length).toStringAsFixed(1),
              icon: Icons.star_outline,
              change: sessions.isEmpty ? 'No data' : 'Sessions',
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
    final state = AppScope.watch(context);
    final trainer = state.currentTrainerProfile;
    final savedSlots = trainer == null
        ? const <String>[]
        : state.repository.trainerScheduleFor(trainer.id, _selectedDate);

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
              if (savedSlots.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Saved slots:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: savedSlots
                      .map((slot) => Chip(label: Text(slot)))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ] else ...[
                const SizedBox(height: 8),
                const Text('No saved schedule slots for this date.'),
                const SizedBox(height: 12),
              ],
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
                onPressed: trainer == null
                    ? null
                    : () async {
                        final saved = AppScope.read(context).saveTrainerSchedule(
                          trainerId: trainer.id,
                          date: _selectedDate,
                          slot: _selectedSlot!,
                        );
                        final message = saved
                            ? 'Schedule saved for ${formatDate(_selectedDate)} at $_selectedSlot.'
                            : 'Schedule slot already exists for selected date.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                        await _downloadSchedulePdf(context, trainer);
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _downloadSchedulePdf(BuildContext context, TrainerProfile trainer) async {
    final state = AppScope.read(context);
    final selectedDate = _selectedDate;
    final savedSlots = state.repository.trainerScheduleFor(trainer.id, selectedDate);

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Trainer Schedule',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Trainer: ${trainer.name}', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Date: ${formatDate(selectedDate)}', style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 18),
              pw.Text('Scheduled slots', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              if (savedSlots.isEmpty)
                pw.Text('No scheduled slots for this date.')
              else
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: savedSlots
                      .map(
                        (slot) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Text('• $slot', style: pw.TextStyle(fontSize: 14)),
                        ),
                      )
                      .toList(),
                ),
              pw.Spacer(),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'Generated on ${formatDate(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFF777777)),
              ),
            ],
          ),
        ),
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'trainer-schedule-${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}.pdf',
    );
  }
}
