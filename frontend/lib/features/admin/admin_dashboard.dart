import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/report_export.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_cards.dart';
import '../../core/widgets/app_charts.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/app_models.dart';
import '../../providers_or_bloc/app_state.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.watch(context);
    final repo = state.repository;
    final activeMembers = repo.users
        .where(
          (user) => user.role == UserRole.member && user.status == 'Active',
        )
        .length;
    final pendingPayments = repo.payments
        .where((payment) => payment.status == PaymentStatus.pending)
        .length;
    final hasAnyRecords = repo.users.isNotEmpty || repo.bookings.isNotEmpty || repo.payments.isNotEmpty || repo.equipment.isNotEmpty || repo.trainers.isNotEmpty;
    return FeaturePage(
      title: 'Admin Dashboard',
      subtitle:
          'Operations, revenue, bookings, users, equipment, trainers, and alerts.',
      children: [
        ResponsiveGrid(
          children: [
            StatCard(
              label: 'Members',
              value: '$activeMembers',
              icon: Icons.groups_outlined,
              change: 'Active',
            ),
            StatCard(
              label: 'Memberships',
              value: '${repo.membershipHistory.length}',
              icon: Icons.workspace_premium_outlined,
              change: repo.membershipHistory.isEmpty ? 'No records' : 'Tracked',
            ),
            StatCard(
              label: 'Revenue',
              value: formatMoney(repo.payments.fold<double>(0, (sum, payment) => sum + payment.amount)),
              icon: Icons.payments_outlined,
              change: repo.payments.isEmpty ? 'No payments' : 'Recorded',
            ),
            StatCard(
              label: 'Today bookings',
              value: '${repo.bookings.length}',
              icon: Icons.event_note_outlined,
              change: 'Confirmed',
            ),
            StatCard(
              label: 'Equipment usage',
              value: repo.equipment.isEmpty ? '0%' : '${(repo.equipment.where((item) => item.status == EquipmentStatus.available).length / (repo.equipment.isEmpty ? 1 : repo.equipment.length) * 100).round()}%',
              icon: Icons.fitness_center_outlined,
              change: repo.equipment.isEmpty ? 'No records' : 'Available',
            ),
            StatCard(
              label: 'Trainer score',
              value: repo.trainers.isEmpty ? '0.0' : '${repo.trainers.map((t) => t.rating).fold(0.0, (a, b) => a + b) / repo.trainers.length}',
              icon: Icons.star_outline,
              change: repo.trainers.isEmpty ? 'No records' : 'Average',
            ),
            StatCard(
              label: 'Pending payments',
              value: '$pendingPayments',
              icon: Icons.pending_actions_outlined,
              change: 'Pending',
            ),
            StatCard(
              label: 'Notifications',
              value: '${state.unreadNotifications}',
              icon: Icons.notifications_outlined,
              change: 'Pending',
            ),
          ],
        ),
        if (!hasAnyRecords)
          const EmptyStateView(
            title: 'No admin data yet',
            message: 'Revenue, equipment, trainer, and booking records will appear here once data exists.',
            icon: Icons.dashboard_outlined,
          )
        else ...[
          const SectionHeader(title: 'Revenue overview'),
          AppCard(child: AppLineChart(points: repo.revenueTrend)),
          const SectionHeader(title: 'Equipment usage'),
          AppCard(child: AppBarChart(points: repo.equipmentUsage)),
        ],
        const SectionHeader(title: 'Quick actions'),
        AppCard(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AppButton(
                label: 'Add Equipment',
                icon: Icons.add_box_outlined,
                onPressed: () => _showEquipmentEditor(context),
              ),
              AppButton(
                label: 'Assign Trainer',
                icon: Icons.person_add_alt,
                onPressed: () => _showQuickTrainerAssignment(context),
              ),
              AppButton(
                label: 'Export PDF',
                icon: Icons.picture_as_pdf_outlined,
                onPressed: () => _exportDashboardReport(context, 'PDF'),
              ),
              AppButton(
                label: 'Export Excel',
                icon: Icons.table_chart_outlined,
                onPressed: () => _exportDashboardReport(context, 'Excel'),
              ),
              AppButton(
                label: 'System Logs',
                icon: Icons.article_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () => _showSystemLogs(context),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Recent bookings'),
        if (repo.bookings.isEmpty)
          const EmptyStateView(
            title: 'No bookings yet',
            message: 'New bookings will show up here once members reserve sessions.',
            icon: Icons.event_note_outlined,
          )
        else
          ...repo.bookings
              .take(3)
              .map((booking) => BookingTile(booking: booking)),
      ],
    );
  }

  void _showEquipmentEditor(BuildContext context) {
    final state = AppScope.read(context);
    final parentContext = context;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _EquipmentEditorSheet(
        onSave: (item) {
          state.addEquipment(item);
          Navigator.of(sheetContext).pop();
          _showSnack(parentContext, '${item.name} added to inventory.');
        },
      ),
    );
  }

  void _showQuickTrainerAssignment(BuildContext context) {
    final state = AppScope.read(context);
    final bookings = state.repository.bookings;
    if (bookings.isEmpty) {
      _showSnack(context, 'No bookings are available for trainer assignment.');
      return;
    }
    final booking = bookings.firstWhere(
      (item) => item.status != BookingStatus.cancelled,
      orElse: () => bookings.first,
    );
    _showTrainerAssignmentSheet(context, state, booking);
  }

  Future<void> _exportDashboardReport(BuildContext context, String format) async {
    final repo = AppScope.read(context).repository;
    final readyRows = repo.reportRows
        .where((row) => row.status.toLowerCase() == 'ready')
        .length;
    final uri = Uri.parse('http://localhost:8000/api/exports/reports/?format=${format.toLowerCase()}&range=Dashboard');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        _showSnack(context, 'Export failed: ${resp.body}');
        return;
      }
      final docsDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${docsDir.path}/reports');
      if (!await exportDir.exists()) await exportDir.create(recursive: true);
      final extension = resp.headers['content-type']?.contains('pdf') == true ? 'pdf' : 'xlsx';
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final fileName = 'dashboard_$timestamp.$extension';
      final file = File('${exportDir.path}/$fileName');
      await file.writeAsBytes(resp.bodyBytes);
      await OpenFile.open(file.path);
      _showSnack(
        context,
        'Dashboard $format export saved with $readyRows ready sections.\n${file.path}',
      );
    } catch (e) {
      _showSnack(context, 'Export failed: $e');
    }
  }

  void _showSystemLogs(BuildContext context) {
    final repo = AppScope.read(context).repository;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Logs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payments pending approval: ${repo.payments.where((item) => item.status == PaymentStatus.pending).length}',
            ),
            const SizedBox(height: 8),
            Text('Bookings tracked: ${repo.bookings.length}'),
            const SizedBox(height: 8),
            Text('Equipment items: ${repo.equipment.length}'),
            const SizedBox(height: 8),
            Text('Last refresh: ${formatDate(DateTime.now())}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class AdminEquipmentManagementScreen extends StatefulWidget {
  const AdminEquipmentManagementScreen({super.key});

  @override
  State<AdminEquipmentManagementScreen> createState() =>
      _AdminEquipmentManagementScreenState();
}

class _AdminEquipmentManagementScreenState
    extends State<AdminEquipmentManagementScreen> {
  String _query = '';
  String _status = 'All';

  @override
  Widget build(BuildContext context) {
    final equipment = AppScope.watch(context).repository.equipment.where((
      item,
    ) {
      final matchesQuery =
          item.name.toLowerCase().contains(_query.toLowerCase()) ||
          item.category.toLowerCase().contains(_query.toLowerCase());
      final matchesStatus = _status == 'All' || item.status.label == _status;
      return matchesQuery && matchesStatus;
    }).toList();
    return FeaturePage(
      title: 'Equipment Management',
      subtitle:
          'CRUD operations, maintenance, categories, capacity, image upload, and filters.',
      children: [
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Search equipment',
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['All', 'Available', 'Full', 'Maintenance']
              .map(
                (status) => ChoiceChip(
                  label: Text(status),
                  selected: _status == status,
                  onSelected: (_) => setState(() => _status = status),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Add Equipment',
          icon: Icons.add_photo_alternate_outlined,
          expand: true,
          onPressed: () => _showEquipmentForm(context),
        ),
        const SectionHeader(title: 'Inventory'),
        ...equipment.map(
          (item) => AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(item.imageIcon),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    StatusBadge(label: item.status.label),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.category} - Capacity ${item.capacity} - ${item.location}',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showEquipmentForm(context, item: item),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _markMaintenance(context, item),
                      icon: const Icon(Icons.construction_outlined),
                      label: const Text('Maintenance'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _deleteEquipment(context, item),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEquipmentForm(BuildContext context, {EquipmentItem? item}) {
    final state = AppScope.read(context);
    final parentContext = context;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _EquipmentEditorSheet(
        item: item,
        onSave: (updated) {
          if (item == null) {
            state.addEquipment(updated);
          } else {
            state.updateEquipment(updated);
          }
          Navigator.of(sheetContext).pop();
          _showSnack(
            parentContext,
            item == null
                ? '${updated.name} added to inventory.'
                : '${updated.name} updated.',
          );
        },
      ),
    );
  }

  void _markMaintenance(BuildContext context, EquipmentItem item) {
    final nextStatus = item.status == EquipmentStatus.maintenance
        ? EquipmentStatus.available
        : EquipmentStatus.maintenance;
    AppScope.read(context).updateEquipment(item.copyWith(status: nextStatus));
    _showSnack(context, '${item.name} marked ${nextStatus.label}.');
  }

  void _deleteEquipment(BuildContext context, EquipmentItem item) {
    AppScope.read(context).deleteEquipment(item);
    _showSnack(context, '${item.name} removed from inventory.');
  }
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _query = '';
  UserRole? _role;

  @override
  Widget build(BuildContext context) {
    final users = AppScope.watch(context).repository.users.where((user) {
      final matchesQuery =
          user.name.toLowerCase().contains(_query.toLowerCase()) ||
          user.email.toLowerCase().contains(_query.toLowerCase());
      final matchesRole = _role == null || user.role == _role;
      return matchesQuery && matchesRole;
    }).toList();
    return FeaturePage(
      title: 'User Management',
      subtitle:
          'Members, trainers, admins, filters, role management, suspension, and details.',
      children: [
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Search users',
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _role == null,
              onSelected: (_) => setState(() => _role = null),
            ),
            ...UserRole.values.map(
              (role) => ChoiceChip(
                label: Text(role.label),
                selected: _role == role,
                onSelected: (_) => setState(() => _role = role),
              ),
            ),
          ],
        ),
        const SectionHeader(title: 'Users'),
        ...users.map(
          (user) => AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: AppAvatar(label: user.avatarLabel),
              title: Text(user.name),
              subtitle: Text('${user.role.label} - ${user.email}'),
              trailing: PopupMenuButton<String>(
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'details', child: Text('View details')),
                  PopupMenuItem(value: 'suspend', child: Text('Suspend')),
                  PopupMenuItem(value: 'activate', child: Text('Activate')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AdminBookingManagementScreen extends StatefulWidget {
  const AdminBookingManagementScreen({super.key});

  @override
  State<AdminBookingManagementScreen> createState() =>
      _AdminBookingManagementScreenState();
}

class _AdminBookingManagementScreenState
    extends State<AdminBookingManagementScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.watch(context);
    final bookings = state.repository.bookings.where((booking) {
      return _filter == 'All' || booking.status.label == _filter;
    }).toList();
    return FeaturePage(
      title: 'Booking Management',
      subtitle:
          'All bookings, overrides, cancellation, trainer reassignment, and conflicts.',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['All', 'Pending', 'Confirmed', 'Completed', 'Cancelled']
              .map(
                (status) => ChoiceChip(
                  label: Text(status),
                  selected: _filter == status,
                  onSelected: (_) => setState(() => _filter = status),
                ),
              )
              .toList(),
        ),
        const SectionHeader(title: 'Conflict viewer'),
        const AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.warning_amber_outlined),
            title: Text('Two bookings overlap at 18:00 in Cardio Zone A'),
            subtitle: Text(
              'Admin override or trainer reassignment recommended',
            ),
            trailing: StatusBadge(label: 'Pending', compact: true),
          ),
        ),
        const SectionHeader(title: 'All bookings'),
        ...bookings.map(
          (booking) => AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const AppAvatar(
                    label: 'B',
                    icon: Icons.event_available_outlined,
                  ),
                  title: Text(booking.equipmentName),
                  subtitle: Text(
                    '${formatDate(booking.date)} at ${booking.timeSlot}\nTrainer: ${booking.trainerName}',
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(label: booking.status.label, compact: true),
                      const SizedBox(height: 6),
                      StatusBadge(
                        label: booking.paymentStatus.label,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        state.overrideBooking(booking);
                        _showSnack(
                          context,
                          '${booking.equipmentName} override applied.',
                        );
                      },
                      icon: const Icon(Icons.sync_alt_outlined),
                      label: const Text('Override'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _showTrainerAssignmentSheet(context, state, booking),
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Assign Trainer'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => state.cancelBooking(booking),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

void _showTrainerAssignmentSheet(
  BuildContext context,
  AppState state,
  Booking booking,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Text(
          'Assign trainer',
          style: Theme.of(sheetContext).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '${booking.equipmentName} at ${booking.timeSlot}',
          style: Theme.of(sheetContext).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        ...state.repository.trainers.map(
          (trainer) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: AppAvatar(label: trainer.name.substring(0, 1)),
            title: Text(trainer.name),
            subtitle: Text('${trainer.specialty} - ${trainer.status}'),
            trailing: booking.trainerName == trainer.name
                ? const StatusBadge(label: 'Current', compact: true)
                : null,
            onTap: () {
              state.updateBooking(booking.copyWith(trainerName: trainer.name));
              Navigator.of(sheetContext).pop();
              _showSnack(context, '${trainer.name} assigned to booking.');
            },
          ),
        ),
      ],
    ),
  );
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _EquipmentEditorSheet extends StatefulWidget {
  const _EquipmentEditorSheet({required this.onSave, this.item});

  final EquipmentItem? item;
  final ValueChanged<EquipmentItem> onSave;

  @override
  State<_EquipmentEditorSheet> createState() => _EquipmentEditorSheetState();
}

class _EquipmentEditorSheetState extends State<_EquipmentEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _capacity;
  late final TextEditingController _location;
  late final TextEditingController _description;
  late EquipmentStatus _status;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    _category = TextEditingController(text: item?.category ?? '');
    _capacity = TextEditingController(text: '${item?.capacity ?? 1}');
    _location = TextEditingController(text: item?.location ?? 'Main Floor');
    _description = TextEditingController(text: item?.description ?? '');
    _status = item?.status ?? EquipmentStatus.available;
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _capacity.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            widget.item == null ? 'Add equipment' : 'Edit equipment',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Equipment name'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _capacity,
            decoration: const InputDecoration(labelText: 'Capacity'),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            decoration: const InputDecoration(labelText: 'Location'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<EquipmentStatus>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: EquipmentStatus.values
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.label),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() {
              if (value != null) _status = value;
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.image_outlined),
            title: Text('Upload image'),
            subtitle: Text('Uses the default equipment icon in this prototype'),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: widget.item == null ? 'Add Equipment' : 'Save Equipment',
            icon: Icons.save_outlined,
            expand: true,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  void _save() {
    final name = _name.text.trim();
    final category = _category.text.trim();
    if (name.isEmpty || category.isEmpty) {
      _showSnack(context, 'Enter an equipment name and category.');
      return;
    }
    final capacity = int.tryParse(_capacity.text.trim());
    if (capacity == null || capacity <= 0) {
      _showSnack(context, 'Enter a valid capacity.');
      return;
    }
    final currentBooked = widget.item?.booked ?? 0;
    final booked = currentBooked > capacity ? capacity : currentBooked;
    widget.onSave(
      EquipmentItem(
        id: widget.item?.id ?? 'eq-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        category: category,
        capacity: capacity,
        booked: booked,
        status: _status,
        location: _location.text.trim().isEmpty
            ? 'Main Floor'
            : _location.text.trim(),
        imageIcon: widget.item?.imageIcon ?? Icons.fitness_center_outlined,
        description: _description.text.trim().isEmpty
            ? '$category equipment ready for member booking.'
            : _description.text.trim(),
      ),
    );
  }
}
