import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_cards.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/app_models.dart';
import '../../providers_or_bloc/app_state.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'M-Pesa';
  PaymentStatus _previewStatus = PaymentStatus.pending;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.watch(context);
    final repo = state.repository;
    final pendingCash = repo.payments
        .where(
          (payment) =>
              payment.method == 'Cash' &&
              payment.status == PaymentStatus.pending,
        )
        .toList();
    return FeaturePage(
      title: 'Payments',
      subtitle:
          'M-Pesa STK Push, cash, Pay Later, retry, receipts, and history.',
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Payment options'),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'M-Pesa',
                    icon: Icon(Icons.phone_android),
                    label: Text('M-Pesa'),
                  ),
                  ButtonSegment(
                    value: 'Cash',
                    icon: Icon(Icons.payments_outlined),
                    label: Text('Cash'),
                  ),
                  ButtonSegment(
                    value: 'Pay Later',
                    icon: Icon(Icons.schedule_outlined),
                    label: Text('Later'),
                  ),
                ],
                selected: {_method},
                onSelectionChanged: (value) =>
                    setState(() => _method = value.first),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text('Booking balance ${formatMoney(1200)}'),
                subtitle: Text(
                  _method == 'M-Pesa'
                      ? 'STK Push expires in 04:59'
                      : _method == 'Cash'
                      ? 'Mark as pending until front desk confirms'
                      : 'Due before next booking',
                ),
                trailing: StatusBadge(label: _previewStatus.label),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  AppButton(
                    label: _method == 'M-Pesa'
                        ? 'Send STK Push'
                        : _method == 'Cash'
                        ? 'Submit Cash Approval'
                        : 'Use Pay Later',
                    icon: Icons.send_to_mobile_outlined,
                    onPressed: () => _recordPayment(state),
                  ),
                  AppButton(
                    label: 'Retry',
                    icon: Icons.refresh_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () =>
                        setState(() => _previewStatus = PaymentStatus.pending),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (state.currentRole == UserRole.admin) ...[
          const SectionHeader(title: 'Cash payment approvals'),
          if (pendingCash.isEmpty)
            const AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.fact_check_outlined),
                title: Text('No cash approvals pending'),
                subtitle: Text('New member cash payments will appear here.'),
              ),
            )
          else
            ...pendingCash.map(
              (payment) => AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.payments_outlined),
                      title: Text(formatMoney(payment.amount)),
                      subtitle: Text(
                        '${payment.reference}\n${formatDate(payment.createdAt)}',
                      ),
                      isThreeLine: true,
                      trailing: StatusBadge(
                        label: payment.status.label,
                        compact: true,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showCashApprovalDialog(context, state, payment),
                          icon: const Icon(Icons.verified_outlined),
                          label: const Text('Approve Plan'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            state.updatePayment(
                              payment.copyWith(status: PaymentStatus.failed),
                            );
                            _showSnack(context, 'Cash payment declined.');
                          },
                          icon: const Icon(Icons.block_outlined),
                          label: const Text('Decline'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SectionHeader(title: 'Payment history'),
        ...repo.payments.map(
          (payment) => AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.receipt_outlined),
              title: Text('${payment.method} - ${formatMoney(payment.amount)}'),
              subtitle: Text(
                '${payment.reference}\n${formatDate(payment.createdAt)}',
              ),
              isThreeLine: true,
              trailing: StatusBadge(label: payment.status.label, compact: true),
            ),
          ),
        ),
      ],
    );
  }

  void _recordPayment(AppState state) {
    final status = _method == 'M-Pesa'
        ? PaymentStatus.confirmed
        : _method == 'Pay Later'
        ? PaymentStatus.pending
        : PaymentStatus.pending;
    setState(() => _previewStatus = status);
    state.addPayment(
      PaymentRecord(
        id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
        method: _method,
        amount: 1200,
        status: status,
        createdAt: DateTime.now(),
        reference:
            '${_method == 'Cash'
                ? 'CASH'
                : _method == 'Pay Later'
                ? 'LATER'
                : 'TX'}-${DateTime.now().second}${DateTime.now().millisecond}',
      ),
    );
    final message = _method == 'Cash'
        ? 'Cash payment recorded for admin approval.'
        : _method == 'Pay Later'
        ? 'Pay Later balance recorded. Pay before the deadline.'
        : 'M-Pesa payment confirmed.';
    _showSnack(context, message);
  }

  void _showCashApprovalDialog(
    BuildContext context,
    AppState state,
    PaymentRecord payment,
  ) {
    var selectedPlan = state.repository.membershipPlans.first.name;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final plan = state.repository.membershipPlanByName(selectedPlan);
          return AlertDialog(
            title: const Text('Approve cash payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cash received: ${formatMoney(payment.amount)}'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedPlan,
                  decoration: const InputDecoration(
                    labelText: 'Activate membership plan',
                  ),
                  items: state.repository.membershipPlans
                      .map(
                        (plan) => DropdownMenuItem(
                          value: plan.name,
                          child: Text(
                            '${plan.name} - ${formatMoney(plan.price)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() {
                    if (value != null) selectedPlan = value;
                  }),
                ),
                const SizedBox(height: 8),
                Text('Duration: ${plan.durationDays} days'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  state.approveCashPaymentForMembership(
                    payment: payment,
                    plan: plan,
                    durationDays: plan.durationDays,
                  );
                  Navigator.of(dialogContext).pop();
                  _showSnack(
                    context,
                    '${plan.name} membership activated from cash payment.',
                  );
                },
                child: const Text('Approve'),
              ),
            ],
          );
        },
      ),
    );
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
