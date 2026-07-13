import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_cards.dart';
import '../../core/widgets/pickers.dart';
import '../../core/widgets/state_views.dart';
import '../../models/app_models.dart';
import '../../providers_or_bloc/app_state.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, this.onOpenMembership});

  final VoidCallback? onOpenMembership;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _step = 0;
  EquipmentItem? _equipment;
  TrainerProfile? _trainer;
  DateTime _date = DateTime.now();
  String? _slot;
  bool _success = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.watch(context);
    final repo = state.repository;
    if (!state.hasBookableMembership) {
      return _membershipRequiredView(state);
    }
    if (_success) {
      final membership = state.activeMembership;
      return FeaturePage(
        title: 'Booking Success',
        subtitle: membership?.paymentStatus == PaymentStatus.payLater
            ? 'Your session is booked. Pay before 12:00 PM to keep the slot.'
            : 'Your session is confirmed under your active membership.',
        children: [
          const EmptyStateView(
            title: 'Session booked',
            message:
                'Equipment, trainer, and schedule were saved in one session flow.',
            icon: Icons.check_circle_outline,
          ),
          AppButton(
            label: 'Book another session',
            icon: Icons.add,
            expand: true,
            onPressed: () => setState(_resetFlow),
          ),
          const SectionHeader(title: 'Upcoming bookings'),
          ...repo.bookings
              .take(3)
              .map(
                (booking) =>
                    BookingTile(booking: booking, showPaymentStatus: true),
              ),
        ],
      );
    }

    return FeaturePage(
      title: 'Book Session',
      subtitle: 'One flow for equipment, trainer, schedule, and confirmation.',
      children: [
        _membershipAccessCard(state),
        Stepper(
          currentStep: _step,
          onStepTapped: (value) {
            if (value <= _highestReachableStep) {
              setState(() => _step = value);
            }
          },
          controlsBuilder: (context, details) => const SizedBox.shrink(),
          steps: [
            Step(
              title: const Text('Select equipment'),
              isActive: _step >= 0,
              content: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: repo.equipment
                    .where((item) => item.status == EquipmentStatus.available)
                    .map(
                      (item) => ChoiceChip(
                        avatar: Icon(item.imageIcon, size: 18),
                        label: Text('${item.name} - ${item.available} free'),
                        selected: _equipment?.id == item.id,
                        onSelected: (_) => setState(() {
                          _equipment = item;
                          _slot = null;
                          _trainer = null;
                          _step = 1;
                        }),
                      ),
                    )
                    .toList(),
              ),
            ),
            Step(
              title: const Text('Choose date'),
              isActive: _step >= 1,
              content: DateChipPicker(
                selectedDate: _date,
                onSelected: (value) => setState(() {
                  _date = value;
                  _slot = null;
                  _trainer = null;
                  _step = 2;
                }),
              ),
            ),
            Step(
              title: const Text('Choose time slot'),
              isActive: _step >= 2,
              content: _timeSlotStep(repo.bookings),
            ),
            Step(
              title: const Text('Select trainer'),
              isActive: _step >= 3,
              content: _trainerStep(repo.trainers, repo.bookings),
            ),
            Step(
              title: const Text('Review and confirm'),
              isActive: _step >= 4,
              content: _reviewCard(state),
            ),
          ],
        ),
        const SectionHeader(title: 'Recent bookings'),
        ...repo.bookings
            .take(3)
            .map(
              (booking) => BookingTile(
                booking: booking,
                showPaymentStatus: true,
                onCancel: () => state.cancelBooking(booking),
              ),
            ),
      ],
    );
  }

  FeaturePage _membershipRequiredView(AppState state) {
    final current = state.repository.currentMembership;
    final status = current.isBookable ? current.status : 'Expired';
    return FeaturePage(
      title: 'Book Session',
      subtitle:
          'Membership must be active before booking equipment or trainers.',
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${current.plan} membership',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Chip(label: Text(status)),
                ],
              ),
              const SizedBox(height: 10),
              Text('Expires ${formatDate(current.expiresAt)}'),
              const SizedBox(height: 12),
              AppButton(
                label: 'Select or Renew Membership',
                icon: Icons.restart_alt_outlined,
                expand: true,
                onPressed: widget.onOpenMembership,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _membershipAccessCard(AppState state) {
    final membership = state.activeMembership!;
    final payLaterNote =
        membership.paymentStatus == PaymentStatus.payLater &&
        membership.paymentDueAt != null;
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.verified_user_outlined),
        title: Text('${membership.plan} membership active'),
        subtitle: Text(
          payLaterNote
              ? 'Pay Later due by 12:00 PM on ${formatDate(membership.paymentDueAt!)}. Unpaid bookings are released after the deadline.'
              : 'Booking is covered until ${formatDate(membership.expiresAt)}.',
        ),
        trailing: Chip(label: Text('${membership.daysRemaining} days')),
      ),
    );
  }

  Widget _timeSlotStep(List<Booking> bookings) {
    if (_equipment == null) {
      return const EmptyStateView(
        title: 'Select equipment first',
        message:
            'Time slots open after you choose an available equipment item.',
        icon: Icons.fitness_center_outlined,
      );
    }
    final slots = _availableSlots(bookings);
    if (slots.isEmpty) {
      return const EmptyStateView(
        title: 'No slots available',
        message: 'This equipment is full today. Choose another date or item.',
        icon: Icons.event_busy_outlined,
      );
    }
    return TimeSlotPicker(
      selectedSlot: _slot,
      availableSlots: slots,
      onSelected: (value) => setState(() {
        _slot = value;
        _trainer = null;
        _step = 3;
      }),
    );
  }

  Widget _trainerStep(List<TrainerProfile> trainers, List<Booking> bookings) {
    if (_slot == null) {
      return const EmptyStateView(
        title: 'Choose a slot first',
        message: 'Available trainers appear after the time slot is selected.',
        icon: Icons.schedule_outlined,
      );
    }
    final available = _availableTrainers(trainers, bookings);
    if (available.isEmpty) {
      return const EmptyStateView(
        title: 'No trainers free',
        message: 'Choose a different time slot to see available trainers.',
        icon: Icons.person_off_outlined,
      );
    }
    return Column(
      children: available
          .map(
            (trainer) => TrainerCard(
              trainer: trainer,
              selected: trainer.id == _trainer?.id,
              onSelect: () => setState(() {
                _trainer = trainer;
                _step = 4;
              }),
            ),
          )
          .toList(),
    );
  }

  List<String> _availableSlots(List<Booking> bookings) {
    if (_equipment == null) return const [];
    return AppConstants.timeSlots
        .where((slot) => _equipmentHasCapacity(bookings, slot))
        .toList();
  }

  bool _equipmentHasCapacity(List<Booking> bookings, String slot) {
    final matching = bookings.where((booking) {
      return booking.equipmentName == _equipment!.name &&
          DateUtils.isSameDay(booking.date, _date) &&
          booking.timeSlot == slot &&
          booking.status != BookingStatus.cancelled;
    }).length;
    return matching < _equipment!.capacity;
  }

  List<TrainerProfile> _availableTrainers(
    List<TrainerProfile> trainers,
    List<Booking> bookings,
  ) {
    return trainers.where((trainer) {
      final availableStatus = trainer.status.toLowerCase() == 'available';
      final hasSlot = trainer.availableSlots.contains(_slot);
      return availableStatus && hasSlot && _trainerIsFree(trainer, bookings);
    }).toList();
  }

  bool _trainerIsFree(TrainerProfile trainer, List<Booking> bookings) {
    return !bookings.any((booking) {
      return booking.trainerName == trainer.name &&
          DateUtils.isSameDay(booking.date, _date) &&
          booking.timeSlot == _slot &&
          booking.status != BookingStatus.cancelled;
    });
  }

  int get _highestReachableStep {
    if (_equipment == null) return 0;
    if (_slot == null) return 2;
    if (_trainer == null) return 3;
    return 4;
  }

  Widget _reviewCard(AppState state) {
    final canConfirm = _equipment != null && _trainer != null && _slot != null;
    final membership = state.activeMembership;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewLine(
            icon: Icons.fitness_center_outlined,
            label: 'Equipment',
            value: _equipment?.name ?? 'No equipment selected',
          ),
          _ReviewLine(
            icon: Icons.calendar_month_outlined,
            label: 'Date',
            value: formatDate(_date),
          ),
          _ReviewLine(
            icon: Icons.schedule_outlined,
            label: 'Time',
            value: _slot ?? 'No slot selected',
          ),
          _ReviewLine(
            icon: Icons.sports_gymnastics_outlined,
            label: 'Trainer',
            value: _trainer?.name ?? 'No trainer selected',
          ),
          _ReviewLine(
            icon: Icons.workspace_premium_outlined,
            label: 'Membership',
            value: membership == null
                ? 'No active membership'
                : '${membership.plan} - ${membership.daysRemaining} days left',
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Confirm Session',
            icon: Icons.check_circle_outline,
            expand: true,
            onPressed: canConfirm ? () => _confirmBooking(state) : null,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Cancel Booking Flow',
            icon: Icons.close_outlined,
            variant: AppButtonVariant.outline,
            expand: true,
            onPressed: () => setState(_resetFlow),
          ),
        ],
      ),
    );
  }

  void _confirmBooking(AppState state) {
    final booking = Booking(
      id: 'bk-${DateTime.now().millisecondsSinceEpoch}',
      equipmentName: _equipment!.name,
      trainerName: _trainer!.name,
      date: _date,
      timeSlot: _slot ?? AppConstants.timeSlots.first,
      status: BookingStatus.confirmed,
      paymentStatus:
          state.activeMembership?.paymentStatus == PaymentStatus.payLater
          ? PaymentStatus.payLater
          : PaymentStatus.confirmed,
    );
    state.addBooking(booking);
    setState(() => _success = true);
  }

  void _resetFlow() {
    _success = false;
    _step = 0;
    _equipment = null;
    _trainer = null;
    _date = DateTime.now();
    _slot = null;
  }
}

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.watch(context);
    final bookings = state.repository.bookings;
    final upcoming = bookings
        .where((booking) => booking.status != BookingStatus.completed)
        .toList();
    final completed = bookings
        .where((booking) => booking.status == BookingStatus.completed)
        .toList();

    if (bookings.isEmpty) {
      return const FeaturePage(
        title: 'My Bookings',
        subtitle: 'Your confirmed sessions will appear here.',
        children: [
          EmptyStateView(
            title: 'No bookings yet',
            message: 'Book a session to see your schedule and payment status.',
            icon: Icons.event_busy_outlined,
          ),
        ],
      );
    }

    return FeaturePage(
      title: 'My Bookings',
      subtitle: 'Track sessions, trainers, equipment, and cancellations.',
      children: [
        const SectionHeader(title: 'Upcoming sessions'),
        if (upcoming.isEmpty)
          const EmptyStateView(
            title: 'No upcoming sessions',
            message: 'Completed sessions are still available below.',
            icon: Icons.event_available_outlined,
          )
        else
          ...upcoming.map(
            (booking) => BookingTile(
              booking: booking,
              showPaymentStatus: true,
              onCancel: () => state.cancelBooking(booking),
            ),
          ),
        const SectionHeader(title: 'Completed sessions'),
        if (completed.isEmpty)
          const EmptyStateView(
            title: 'No completed sessions yet',
            message: 'Your history will build as you train.',
            icon: Icons.history_outlined,
          )
        else
          ...completed.map(
            (booking) => BookingTile(booking: booking, showPaymentStatus: true),
          ),
      ],
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
