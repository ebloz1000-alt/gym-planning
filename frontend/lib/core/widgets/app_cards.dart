import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../utils/formatters.dart';
import 'app_button.dart';
import 'status_badge.dart';

class FeaturePage extends StatelessWidget {
  const FeaturePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = 16});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.change,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? change;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer),
              ),
              const Spacer(),
              if (change != null) StatusBadge(label: change!, compact: true),
            ],
          ),
          const SizedBox(height: 14),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 180,
    this.gap = 12,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final count = (width / minItemWidth).floor().clamp(1, 4);
        return GridView.count(
          crossAxisCount: count,
          childAspectRatio: 1.05,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
          children: children,
        );
      },
    );
  }
}

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.label,
    this.radius = 22,
    this.icon,
  });

  final String label;
  final double radius;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.secondaryContainer,
      foregroundColor: scheme.onSecondaryContainer,
      child: icon == null
          ? Text(label, style: const TextStyle(fontWeight: FontWeight.w800))
          : Icon(icon),
    );
  }
}

class EquipmentCard extends StatelessWidget {
  const EquipmentCard({super.key, required this.item, required this.onBook});

  final EquipmentItem item;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(label: item.name.substring(0, 1), icon: item.imageIcon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('${item.category} - ${item.location}'),
                  ],
                ),
              ),
              StatusBadge(label: item.status.label),
            ],
          ),
          const SizedBox(height: 12),
          Text(item.description),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: item.capacity == 0 ? 0 : item.booked / item.capacity,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('${item.available}/${item.capacity} available'),
              ),
              AppButton(
                label: 'Book',
                icon: Icons.event_available_outlined,
                onPressed: item.status == EquipmentStatus.available
                    ? onBook
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TrainerCard extends StatelessWidget {
  const TrainerCard({
    super.key,
    required this.trainer,
    this.onSelect,
    this.selected = false,
  });

  final TrainerProfile trainer;
  final VoidCallback? onSelect;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(label: trainer.name.substring(0, 1)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trainer.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(trainer.specialty),
                  ],
                ),
              ),
              StatusBadge(label: trainer.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 20, color: Colors.amber),
              Text('${trainer.rating}'),
              const SizedBox(width: 16),
              Text('${trainer.sessionsToday} sessions today'),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: trainer.availableSlots
                .map((slot) => Chip(label: Text(slot)))
                .toList(),
          ),
          if (onSelect != null) ...[
            const SizedBox(height: 12),
            AppButton(
              label: selected ? 'Selected' : 'Select Trainer',
              icon: selected
                  ? Icons.check_circle_outline
                  : Icons.person_add_alt,
              variant: selected
                  ? AppButtonVariant.secondary
                  : AppButtonVariant.primary,
              onPressed: onSelect,
            ),
          ],
        ],
      ),
    );
  }
}

class BookingTile extends StatelessWidget {
  const BookingTile({
    super.key,
    required this.booking,
    this.onCancel,
    this.onTap,
    this.showPaymentStatus = true,
  });

  final Booking booking;
  final VoidCallback? onCancel;
  final VoidCallback? onTap;
  final bool showPaymentStatus;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: const AppAvatar(
          label: 'B',
          icon: Icons.event_available_outlined,
        ),
        title: Text(booking.equipmentName),
        subtitle: Text(
          '${formatDate(booking.date)} at ${booking.timeSlot}\nTrainer: ${booking.trainerName}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(label: booking.status.label, compact: true),
                if (showPaymentStatus) ...[
                  const SizedBox(height: 6),
                  StatusBadge(
                    label: booking.paymentStatus.label,
                    compact: true,
                  ),
                ],
              ],
            ),
            if (onCancel != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Cancel booking',
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
