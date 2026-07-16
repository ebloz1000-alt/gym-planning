import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_cards.dart';
import '../../core/widgets/app_fields.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/app_models.dart';
import '../../providers_or_bloc/app_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  final _paymentKey = GlobalKey<FormState>();
  final _mpesaPhone = TextEditingController();

  String _selectedPlan = 'Monthly';
  String _paymentMethod = 'M-Pesa';
  int _vipDuration = 45;
  bool _isRenewing = false;

  @override
  void dispose() {
    _mpesaPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.watch(context);
    final repo = state.repository;
    final current = repo.currentMembership;
    final currentStatus = current.isBookable ? current.status : 'Expired';
    final selectedPlan = repo.membershipPlanByName(_selectedPlan);
    final selectedPrice = _priceFor(selectedPlan);
    final selectedDuration = selectedPlan.name == 'VIP'
        ? _vipDuration
        : selectedPlan.durationDays;
    return FeaturePage(
      title: 'Membership',
      subtitle: 'Plans, renewals, countdowns, and membership history.',
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${current.plan} plan',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  StatusBadge(label: currentStatus),
                ],
              ),
              const SizedBox(height: 8),
              Text('Started ${formatDate(current.startedAt)}'),
              Text('Expires ${formatDate(current.expiresAt)}'),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: 0.6,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
              ),
              const SizedBox(height: 10),
              Text(formatCountdown(current.expiresAt)),
              if (current.paymentStatus != PaymentStatus.confirmed) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(label: current.paymentStatus.label),
                    if (current.paymentDueAt != null)
                      Chip(
                        label: Text(
                          'Due 12:00 PM, ${formatDate(current.paymentDueAt!)}',
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Booking access is unlocked only while this membership is active.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Choose a plan'),
        ...repo.membershipPlans.map((plan) {
          final selected = _selectedPlan == plan.name;
          final price = plan.name == 'VIP'
              ? plan.price * (_vipDuration / plan.durationDays)
              : plan.price;
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (plan.highlight) const StatusBadge(label: 'Popular'),
                    ChoiceChip(
                      label: Text(selected ? 'Selected' : 'Choose'),
                      selected: selected,
                      onSelected: (_) => _selectPlan(plan.name),
                    ),
                  ],
                ),
                Text('${plan.durationDays} days - ${formatMoney(price)}'),
                if (plan.name == 'Daily') ...[
                  const SizedBox(height: 6),
                  Text(
                    'Daily members may choose Pay Later and book sessions until the 12:00 PM payment deadline.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: plan.features
                      .map((feature) => Chip(label: Text(feature)))
                      .toList(),
                ),
                if (plan.name == 'VIP' && selected) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [35, 40, 45, 50, 60, 70, 80]
                        .map(
                          (days) => ChoiceChip(
                            label: Text('$days days'),
                            selected: _vipDuration == days,
                            onSelected: (_) =>
                                setState(() => _vipDuration = days),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          );
        }),
        AppCard(
          child: Form(
            key: _paymentKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Membership payment',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _paymentInstructions(selectedPlan),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                SegmentedButton<String>(
                  segments: [
                    const ButtonSegment(
                      value: 'M-Pesa',
                      icon: Icon(Icons.phone_android_outlined),
                      label: Text('M-Pesa'),
                    ),
                    const ButtonSegment(
                      value: 'Cash',
                      icon: Icon(Icons.payments_outlined),
                      label: Text('Cash'),
                    ),
                    if (selectedPlan.name == 'Daily')
                      const ButtonSegment(
                        value: 'Pay Later',
                        icon: Icon(Icons.schedule_outlined),
                        label: Text('Later'),
                      ),
                  ],
                  selected: {_paymentMethod},
                  onSelectionChanged: (value) =>
                      setState(() => _paymentMethod = value.first),
                ),
                if (_paymentMethod == 'M-Pesa') ...[
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'M-Pesa Phone Number',
                    hint: '07XXXXXXXX',
                    controller: _mpesaPhone,
                    icon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone,
                    validator: _validateMpesaPhone,
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$_selectedPlan - $selectedDuration days',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Text(
                      formatMoney(selectedPrice),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: _submitLabel,
                  icon: _paymentMethod == 'Pay Later'
                      ? Icons.schedule_outlined
                      : _paymentMethod == 'Cash'
                      ? Icons.payments_outlined
                      : Icons.workspace_premium_outlined,
                  expand: true,
                  isLoading: _isRenewing,
                  onPressed: () => _submitRenewal(state),
                ),
              ],
            ),
          ),
        ),
        const SectionHeader(title: 'Membership history'),
        ...repo.membershipHistory.map(
          (item) => AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_outlined),
              title: Text(item.plan),
              subtitle: Text(
                '${formatDate(item.startedAt)} - ${formatDate(item.expiresAt)}',
              ),
              trailing: StatusBadge(
                label: item.paymentStatus == PaymentStatus.confirmed
                    ? item.status
                    : item.paymentStatus.label,
                compact: true,
              ),
            ),
          ),
        ),
        const SectionHeader(title: 'Blocked and expired states'),
        const AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.block_outlined),
            title: Text('Blocked Membership Screen'),
            subtitle: Text(
              'Shown when admin suspends access or payment remains overdue.',
            ),
            trailing: StatusBadge(label: 'Blocked', compact: true),
          ),
        ),
        const AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.timer_off_outlined),
            title: Text('Expired Membership Screen'),
            subtitle: Text('Shown when membership countdown reaches zero.'),
            trailing: StatusBadge(label: 'Expired', compact: true),
          ),
        ),
      ],
    );
  }

  double _priceFor(MembershipPlan plan) {
    if (plan.name != 'VIP') return plan.price;
    return plan.price * (_vipDuration / plan.durationDays);
  }

  String _normalizeMpesaNumber(String input) {
    var phone = (input ?? '').trim().replaceAll(RegExp(r'[\s-]'), '');
    if (phone.startsWith('+')) phone = phone.substring(1);
    if (phone.startsWith('0')) {
      // convert 07xxxxxxxx -> 2547xxxxxxxx
      phone = '254' + phone.substring(1);
    } else if (phone.startsWith('7')) {
      phone = '254' + phone;
    }
    return phone;
  }

  Future<String?> _sendStkPush(String phone, double amount, String planName, int durationDays) async {
    final uri = Uri.parse('http://localhost:8000/api/mpesa/stk_push/');
    try {
      final normalized = _normalizeMpesaNumber(phone);
      const accountReference = '0799657075';
      final resp = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "phone": normalized,
          "amount": amount.toInt(),
          "plan_name": planName,
          "duration_days": durationDays,
          "account_reference": accountReference,
        }),
      ).timeout(const Duration(seconds: 15));
      final body = json.decode(resp.body);
      if (resp.statusCode == 200 && body['success'] == true) {
        return null;
      }
      return body['detail']?.toString() ?? 'STK push failed with status ${resp.statusCode}';
    } catch (error) {
      return 'STK push request failed: $error';
    }
  }

  void _selectPlan(String name) {
    setState(() {
      _selectedPlan = name;
      if (name != 'Daily' && _paymentMethod == 'Pay Later') {
        _paymentMethod = 'M-Pesa';
      }
    });
  }

  String _paymentInstructions(MembershipPlan plan) {
    if (_paymentMethod == 'Cash') {
      return 'Submit the ${plan.name} cash amount for admin approval. The admin activates the membership after confirming the cash payment.';
    }
    if (_paymentMethod == 'Pay Later') {
      return 'Daily Pay Later unlocks booking now. If payment is not made by 12:00 PM, booked sessions are removed and released.';
    }
    return 'Enter your M-Pesa number to receive an STK Push, then confirm with your PIN.';
  }

  String get _submitLabel {
    if (_paymentMethod == 'Cash') return 'Submit Cash for Admin Approval';
    if (_paymentMethod == 'Pay Later') return 'Activate Daily Pay Later';
    return 'Send STK & Renew $_selectedPlan';
  }

  String? _validateMpesaPhone(String? value) {
    final phone = (value ?? '').trim().replaceAll(RegExp(r'[\s-]'), '');
      // Accept 07XXXXXXXX format (10 digits starting with 07)
      final isValid = RegExp(r'^07\d{8}$').hasMatch(phone);
    if (!isValid) return 'Enter a valid M-Pesa number starting with 07';
    return null;
  }

  Future<void> _submitRenewal(AppState state) async {
    if (_paymentMethod == 'M-Pesa' &&
        !(_paymentKey.currentState?.validate() ?? false)) {
      return;
    }
    final plan = state.repository.membershipPlanByName(_selectedPlan);
    final durationDays = plan.name == 'VIP' ? _vipDuration : plan.durationDays;
    setState(() => _isRenewing = true);
    final amount = _priceFor(plan);
    if (_paymentMethod == 'Pay Later') {
      await state.activateDailyPayLater(
        plan: plan,
        durationDays: durationDays,
        amount: amount,
      );
    } else if (_paymentMethod == 'Cash') {
      state.submitCashMembershipPayment(plan: plan, amount: amount);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    } else {
      final error = await _sendStkPush(_mpesaPhone.text.trim(), amount, plan.name, durationDays);
      if (error != null) {
        if (!mounted) return;
        setState(() => _isRenewing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        return;
      }
      if (!mounted) return;
      setState(() => _isRenewing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('STK Push sent — enter your PIN on the phone.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isRenewing = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_successMessage)));
  }

  String get _successMessage {
    if (_paymentMethod == 'Cash') {
      return 'Cash payment submitted. Admin approval will activate your $_selectedPlan membership.';
    }
    if (_paymentMethod == 'Pay Later') {
      return 'Daily Pay Later is active. Pay before 12:00 PM to keep booked sessions.';
    }
    return 'STK confirmed. Your $_selectedPlan membership is active for booking.';
  }
}
