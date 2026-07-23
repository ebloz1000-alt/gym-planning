import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_cards.dart';
import '../../core/widgets/state_views.dart';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.read(context);
    if (state.currentRole == UserRole.admin && _method == 'M-Pesa') {
      _method = 'Cash';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.watch(context);
    final repo = state.repository;
    final isAdmin = state.currentRole == UserRole.admin;
    final availableMethods = isAdmin
        ? ['Cash', 'Pay Later']
        : ['M-Pesa', 'Cash', 'Pay Later'];
    final currentMethod = availableMethods.contains(_method)
        ? _method
        : availableMethods.first;
    final pendingApprovals = repo.payments
        .where((payment) =>
            payment.status == PaymentStatus.pending &&
            (payment.method == 'Cash' || payment.method == 'Pay Later'))
        .toList();
    return FeaturePage(
      title: 'Payments',
      subtitle:
          'Cash, Pay Later, receipts, and approval management.',
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Payment options'),
              SegmentedButton<String>(
                segments: availableMethods
                    .map(
                      (method) => ButtonSegment(
                        value: method,
                        icon: Icon(
                          method == 'M-Pesa'
                              ? Icons.phone_android
                              : method == 'Cash'
                                  ? Icons.payments_outlined
                                  : Icons.schedule_outlined,
                        ),
                        label: Text(method == 'Pay Later' ? 'Later' : method),
                      ),
                    )
                    .toList(),
                selected: {currentMethod},
                onSelectionChanged: (value) =>
                    setState(() => _method = value.first),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(
                  'Booking balance ${formatMoney(repo.payments.isEmpty ? 0 : repo.payments.fold<double>(0, (total, payment) => total + payment.amount))}',
                ),
                subtitle: Text(
                  currentMethod == 'M-Pesa'
                      ? 'STK Push expires in 04:59'
                      : currentMethod == 'Cash'
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
                    label: currentMethod == 'M-Pesa'
                        ? 'Send STK Push'
                        : currentMethod == 'Cash'
                            ? 'Submit Cash Approval'
                            : 'Use Pay Later',
                    icon: Icons.send_to_mobile_outlined,
                    onPressed: currentMethod == 'M-Pesa' && isAdmin
                        ? null
                        : () => _recordPayment(state, currentMethod),
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
          const SectionHeader(title: 'Pending payment approvals'),
          if (pendingApprovals.isEmpty)
            const AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.fact_check_outlined),
                title: Text('No approvals pending'),
                subtitle: Text('Cash or Pay Later approvals will appear here.'),
              ),
            )
          else
            ...pendingApprovals.map(
              (payment) => AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        payment.method == 'Pay Later'
                            ? Icons.schedule_outlined
                            : Icons.payments_outlined,
                      ),
                      title: Text('${payment.method} • ${formatMoney(payment.amount)}'),
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
                        if (payment.method == 'Cash')
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showCashApprovalDialog(context, state, payment),
                            icon: const Icon(Icons.verified_outlined),
                            label: const Text('Approve Plan'),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () {
                              state.updatePayment(
                                payment.copyWith(status: PaymentStatus.confirmed),
                              );
                              _showSnack(context, 'Pay Later approved.');
                            },
                            icon: const Icon(Icons.verified_outlined),
                            label: const Text('Approve'),
                          ),
                        OutlinedButton.icon(
                          onPressed: () {
                            state.updatePayment(
                              payment.copyWith(status: PaymentStatus.failed),
                            );
                            _showSnack(context, '${payment.method} payment declined.');
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
        if (repo.payments.isEmpty)
          const EmptyStateView(
            title: 'No payments yet',
            message: 'Payment history will appear here once transactions occur.',
            icon: Icons.receipt_long_outlined,
          )
        else
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

  void _recordPayment(AppState state, String method) {
    final status = method == 'M-Pesa'
        ? PaymentStatus.confirmed
        : method == 'Pay Later'
            ? PaymentStatus.pending
            : PaymentStatus.pending;
    setState(() => _previewStatus = status);
    state.addPayment(
      PaymentRecord(
        id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
        method: method,
        amount: 1200,
        status: status,
        createdAt: DateTime.now(),
        reference:
            '${method == 'Cash'
                ? 'CASH'
                : method == 'Pay Later'
                    ? 'LATER'
                    : 'TX'}-${DateTime.now().second}${DateTime.now().millisecond}',
      ),
    );
    final message = method == 'Cash'
        ? 'Cash payment recorded for admin approval.'
        : method == 'Pay Later'
            ? 'Pay Later balance recorded. Pay before the deadline.'
            : 'M-Pesa payment confirmed.';
    _showSnack(context, message);
  }

  void _showCashApprovalDialog(
    BuildContext context,
    AppState state,
    PaymentRecord payment,
  ) {
    final availablePlans = state.repository.membershipPlans.isEmpty
        ? <MembershipPlan>[MembershipPlan.fallback]
        : state.repository.membershipPlans;
    var selectedPlan = availablePlans.first.name;
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
                  items: availablePlans
                      .map<DropdownMenuItem<String>>(
                        (plan) => DropdownMenuItem<String>(
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
