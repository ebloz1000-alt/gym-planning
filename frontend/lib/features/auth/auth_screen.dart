import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_fields.dart';
import '../../core/widgets/install_app_button.dart';
import '../../models/app_models.dart';
import '../../providers_or_bloc/app_state.dart';
import 'widgets/auth_components.dart';

enum _AuthMode {
  register,
  signIn,
  trainerLogin,
  adminLogin,
  forgot,
  otp,
  reset,
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _heroController = PageController();
  final _loginKey = GlobalKey<FormState>();
  final _registerKey = GlobalKey<FormState>();
  final _forgotKey = GlobalKey<FormState>();
  final _otpKey = GlobalKey<FormState>();
  final _resetKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _otp = TextEditingController();
  final _resetPassword = TextEditingController();
  final _resetConfirm = TextEditingController();

  Timer? _carouselTimer;
  _AuthMode _mode = _AuthMode.register;
  _AuthMode _recoveryReturnMode = _AuthMode.signIn;
  bool _remember = true;
  bool _busy = false;
  int _heroPage = 0;

  final _slides = const [
    _HeroSlide(
      icon: Icons.local_fire_department_rounded,
      title: 'Member training, simplified',
      message:
          'Create a member account in seconds, then book equipment, trainers, and payments from one clean session flow.',
      metric: '3 min',
      metricLabel: 'average signup',
    ),
    _HeroSlide(
      icon: Icons.lock_person_outlined,
      title: 'Secure staff portals',
      message:
          'Trainer and admin workspaces stay separate from public signup with dedicated access screens.',
      metric: '24/7',
      metricLabel: 'protected access',
    ),
    _HeroSlide(
      icon: Icons.fitness_center_rounded,
      title: 'Luxury gym operations',
      message:
          'A polished Material 3 experience for bookings, schedules, notifications, and member care.',
      metric: '4.9',
      metricLabel: 'member rating',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _password.addListener(_refresh);
    _resetPassword.addListener(_refresh);
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_heroController.hasClients) return;
      final next = (_heroPage + 1) % _slides.length;
      _heroController.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _heroController.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _otp.dispose();
    _resetPassword.dispose();
    _resetConfirm.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.watch(context);
    final brand = FitnessBrandTheme.of(context);
    final busy = _busy || state.isRefreshingSession;

    return Scaffold(
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 960;
                if (isWide) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 11,
                        child: _HeroSection(
                          controller: _heroController,
                          slides: _slides,
                          page: _heroPage,
                          onPageChanged: (value) =>
                              setState(() => _heroPage = value),
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: SafeArea(
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _loginPageHeader(state),
                                  const SizedBox(height: 18),
                                  _authCard(state),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                    children: [
                      SizedBox(
                        height: constraints.maxHeight < 720 ? 292 : 344,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(brand.radiusLg),
                          child: _HeroSection(
                            controller: _heroController,
                            slides: _slides,
                            page: _heroPage,
                            compact: true,
                            onPageChanged: (value) =>
                                setState(() => _heroPage = value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _loginPageHeader(state),
                      const SizedBox(height: 18),
                      _authCard(state),
                    ],
                  ),
                );
              },
            ),
          ),
          LoadingOverlay(visible: busy, message: _loadingMessage),
        ],
      ),
    );
  }

  Widget _authCard(AppState state) {
    return PremiumAuthCard(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: Column(
            key: ValueKey(_mode),
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _cardHeader(state),
              const SizedBox(height: 22),
              if (_mode == _AuthMode.register) _registrationForm(state),
              if (_isLoginMode) _loginForm(state),
              if (_mode == _AuthMode.forgot) _forgotPasswordForm(),
              if (_mode == _AuthMode.otp) _otpForm(),
              if (_mode == _AuthMode.reset) _resetPasswordForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loginPageHeader(AppState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Welcome to FitFlow Elite',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text('Install the app for faster access and offline support.'),
          ],
        ),
        const InstallAppButton(),
      ],
    );
  }

  Widget _cardHeader(AppState state) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: AnimatedBrandMark(size: 46)),
            IconButton.filledTonal(
              tooltip: state.themeMode == ThemeMode.dark
                  ? 'Use light mode'
                  : 'Use dark mode',
              onPressed: () => state.setThemeMode(
                state.themeMode == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark,
              ),
              icon: Icon(
                state.themeMode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Column(
            key: ValueKey('header-$_mode'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titleForMode,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _subtitleForMode,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _registrationForm(AppState state) {
    return AutofillGroup(
      child: Form(
        key: _registerKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _memberOnlyNotice(),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Full Name',
              controller: _name,
              icon: Icons.badge_outlined,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              validator: _validateName,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Email Address',
              hint: 'you@example.com',
              controller: _email,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Phone Number',
              hint: '+254 700 000 000',
              controller: _phone,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              textInputAction: TextInputAction.next,
              validator: _validatePhone,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Password',
              controller: _password,
              icon: Icons.lock_outline,
              obscure: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              validator: _validateStrongPassword,
            ),
            const SizedBox(height: 12),
            PasswordStrengthMeter(password: _password.text),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Confirm Password',
              controller: _confirmPassword,
              icon: Icons.verified_user_outlined,
              obscure: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              validator: _validatePasswordConfirmation,
              onFieldSubmitted: (_) => _submitRegistration(state),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Create Member Account',
              icon: Icons.arrow_forward_rounded,
              expand: true,
              isLoading: _busy,
              onPressed: () => _submitRegistration(state),
            ),
            const SizedBox(height: 18),
            _alreadyAccountPrompt(),
            const SizedBox(height: 20),
            _workspaceCards(),
          ],
        ),
      ),
    );
  }

  Widget _loginForm(AppState state) {
    final role = _loginRole;
    final isPortal = role != UserRole.member;
    return AutofillGroup(
      child: Form(
        key: _loginKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _loginNotice(role),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Email',
              hint: role == UserRole.member
                  ? 'you@example.com'
                  : '${role.label.toLowerCase()}@fitflow.com',
              controller: _email,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Password',
              controller: _password,
              icon: Icons.lock_outline,
              obscure: true,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              validator: _validateLoginPassword,
              onFieldSubmitted: (_) => _submitLogin(state),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (!isPortal)
                  Expanded(
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _remember,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) =>
                          setState(() => _remember = value ?? false),
                      title: const Text('Remember me'),
                    ),
                  )
                else
                  const Spacer(),
                TextButton(
                  onPressed: _openForgotPassword,
                  child: const Text('Forgot Password'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              label: role == UserRole.member
                  ? 'Sign In'
                  : '${role.label} Login',
              icon: Icons.lock_open_rounded,
              expand: true,
              isLoading: state.isRefreshingSession,
              onPressed: () => _submitLogin(state),
            ),
            const SizedBox(height: 16),
            _loginFooter(role),
          ],
        ),
      ),
    );
  }

  Widget _forgotPasswordForm() {
    return AutofillGroup(
      child: Form(
        key: _forgotKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            AppTextField(
              label: 'Account Email',
              hint: 'you@example.com',
              controller: _email,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Send Email OTP',
              icon: Icons.mark_email_read_rounded,
              expand: true,
              isLoading: _busy,
              onPressed: _sendOtp,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => setState(() => _mode = _recoveryReturnMode),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text('Back to ${_loginTitleFor(_recoveryReturnMode)}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _otpForm() {
    return Form(
      key: _otpKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          OtpCodeField(
            controller: _otp,
            validator: (value) {
              if (value == null || value.length != 6) {
                return 'Enter the 6-digit code sent to your email.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Resend',
                  icon: Icons.refresh_rounded,
                  variant: AppButtonVariant.outline,
                  onPressed: _sendOtp,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Verify',
                  icon: Icons.verified_rounded,
                  onPressed: _verifyOtp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resetPasswordForm() {
    return AutofillGroup(
      child: Form(
        key: _resetKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            AppTextField(
              label: 'New Password',
              controller: _resetPassword,
              icon: Icons.lock_reset_rounded,
              obscure: true,
              autofillHints: const [AutofillHints.newPassword],
              validator: _validateResetPassword,
            ),
            const SizedBox(height: 12),
            PasswordStrengthMeter(password: _resetPassword.text),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Confirm New Password',
              controller: _resetConfirm,
              icon: Icons.verified_outlined,
              obscure: true,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) {
                if (value != _resetPassword.text) {
                  return 'Passwords do not match.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Reset Password',
              icon: Icons.check_circle_rounded,
              expand: true,
              isLoading: _busy,
              onPressed: _submitResetPassword,
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberOnlyNotice() {
    final scheme = Theme.of(context).colorScheme;
    final brand = FitnessBrandTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(.1),
        borderRadius: BorderRadius.circular(brand.radiusMd),
        border: Border.all(color: scheme.primary.withOpacity(.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'All new accounts are created as Member accounts.',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginNotice(UserRole role) {
    final scheme = Theme.of(context).colorScheme;
    final brand = FitnessBrandTheme.of(context);
    final isPortal = role != UserRole.member;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPortal
            ? scheme.secondaryContainer.withOpacity(.42)
            : scheme.primary.withOpacity(.1),
        borderRadius: BorderRadius.circular(brand.radiusMd),
        border: Border.all(
          color: isPortal
              ? scheme.secondary.withOpacity(.24)
              : scheme.primary.withOpacity(.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPortal ? Icons.lock_person_outlined : Icons.person_outline,
            color: isPortal ? scheme.secondary : scheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isPortal
                  ? '${role.label} Access is a separate secure portal.'
                  : 'Member sign in opens your dashboard, bookings, and profile.',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _alreadyAccountPrompt() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Already have an account?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        TextButton.icon(
          onPressed: () => setState(() => _mode = _AuthMode.signIn),
          icon: const Icon(Icons.login_rounded),
          label: const Text('Sign In'),
        ),
      ],
    );
  }

  Widget _workspaceCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Workspace',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 460;
            final cards = [
              _WorkspaceCard(
                title: 'Member',
                action: 'Join Now',
                icon: Icons.check_circle_outline,
                selected: true,
                locked: false,
                onTap: () => setState(() => _mode = _AuthMode.register),
              ),
              _WorkspaceCard(
                title: 'Trainer Access',
                action: 'Trainer Login',
                icon: Icons.sports_gymnastics_outlined,
                selected: false,
                locked: true,
                onTap: () => setState(() => _mode = _AuthMode.trainerLogin),
              ),
              _WorkspaceCard(
                title: 'Admin Portal',
                action: 'Admin Login',
                icon: Icons.admin_panel_settings_outlined,
                selected: false,
                locked: true,
                onTap: () => setState(() => _mode = _AuthMode.adminLogin),
              ),
            ];

            if (!isWide) {
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    if (card != cards.last) const SizedBox(height: 10),
                  ],
                ],
              );
            }

            return Row(
              children: [
                for (final card in cards) ...[
                  Expanded(child: card),
                  if (card != cards.last) const SizedBox(width: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _loginFooter(UserRole role) {
    if (role == UserRole.member) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'New to FitFlow?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _mode = _AuthMode.register),
            icon: const Icon(Icons.person_add_alt_rounded),
            label: const Text('Create Account'),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _mode = _AuthMode.signIn),
                icon: const Icon(Icons.person_outline),
                label: const Text('Member Sign In'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _mode = _AuthMode.register),
                icon: const Icon(Icons.person_add_alt_rounded),
                label: const Text('Join as Member'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () => setState(
            () => _mode = role == UserRole.trainer
                ? _AuthMode.adminLogin
                : _AuthMode.trainerLogin,
          ),
          icon: const Icon(Icons.sync_alt_rounded),
          label: Text(
            role == UserRole.trainer ? 'Admin Login' : 'Trainer Login',
          ),
        ),
      ],
    );
  }

  Future<void> _submitLogin(AppState state) async {
    if (!(_loginKey.currentState?.validate() ?? false)) return;
    final role = _loginRole;
    await state.login(role, remember: role == UserRole.member && _remember);
  }

  Future<void> _submitRegistration(AppState state) async {
    if (!(_registerKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    await state.register(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<void> _sendOtp() async {
    if (!(_forgotKey.currentState?.validate() ?? true)) return;
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _mode = _AuthMode.otp;
    });
    _showFeedback('A 6-digit OTP was sent to ${_email.text.trim()}.');
  }

  void _openForgotPassword() {
    setState(() {
      _recoveryReturnMode = _mode;
      _mode = _AuthMode.forgot;
    });
  }

  void _verifyOtp() {
    if (!(_otpKey.currentState?.validate() ?? false)) return;
    setState(() => _mode = _AuthMode.reset);
    _showFeedback('OTP verified. Create a new password.');
  }

  Future<void> _submitResetPassword() async {
    if (!(_resetKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _mode = _recoveryReturnMode;
      _password.clear();
      _resetPassword.clear();
      _resetConfirm.clear();
      _otp.clear();
    });
    await _showSuccessDialog(
      title: 'Password Updated',
      message: 'Your account is ready for secure sign in.',
    );
  }

  Future<void> _showSuccessDialog({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const SuccessPulse(icon: Icons.check_rounded),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().length < 2) {
      return 'Enter your full name.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!valid) return 'Enter a valid email address.';
    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    final valid = RegExp(r'^\+?[0-9\s-]{9,18}$').hasMatch(phone);
    if (!valid) return 'Enter a valid phone number.';
    return null;
  }

  String? _validateLoginPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Enter your password.';
    return null;
  }

  String? _validateStrongPassword(String? value) {
    final details = evaluatePasswordStrength(value ?? '');
    if (details.score < 3) {
      return 'Use a stronger password before continuing.';
    }
    return null;
  }

  String? _validatePasswordConfirmation(String? value) {
    if (value != _password.text) return 'Passwords do not match.';
    return null;
  }

  String? _validateResetPassword(String? value) {
    final details = evaluatePasswordStrength(value ?? '');
    if (details.score < 3) return 'Use a stronger new password.';
    return null;
  }

  bool get _isLoginMode =>
      _mode == _AuthMode.signIn ||
      _mode == _AuthMode.trainerLogin ||
      _mode == _AuthMode.adminLogin;

  UserRole get _loginRole {
    return switch (_mode) {
      _AuthMode.trainerLogin => UserRole.trainer,
      _AuthMode.adminLogin => UserRole.admin,
      _ => UserRole.member,
    };
  }

  String _loginTitleFor(_AuthMode mode) {
    return switch (mode) {
      _AuthMode.trainerLogin => 'Trainer Login',
      _AuthMode.adminLogin => 'Admin Login',
      _ => 'Sign In',
    };
  }

  String get _loadingMessage {
    return switch (_mode) {
      _AuthMode.register => 'Creating your member account',
      _AuthMode.trainerLogin => 'Opening trainer portal',
      _AuthMode.adminLogin => 'Opening admin portal',
      _AuthMode.signIn => 'Securing your member session',
      _ => 'Processing securely',
    };
  }

  String get _titleForMode {
    return switch (_mode) {
      _AuthMode.register => 'Create Your FitFlow Account',
      _AuthMode.signIn => 'Member Sign In',
      _AuthMode.trainerLogin => 'Trainer Login',
      _AuthMode.adminLogin => 'Admin Login',
      _AuthMode.forgot => 'Recover Access',
      _AuthMode.otp => 'Verify Your Email',
      _AuthMode.reset => 'Set a New Password',
    };
  }

  String get _subtitleForMode {
    return switch (_mode) {
      _AuthMode.register =>
        'Fast member signup for bookings, sessions, notifications, and profile access.',
      _AuthMode.signIn =>
        'Access your member dashboard, session bookings, alerts, and profile.',
      _AuthMode.trainerLogin =>
        'Secure access for trainer schedules, sessions, and client updates.',
      _AuthMode.adminLogin =>
        'Secure admin portal for operations, reports, users, and controls.',
      _AuthMode.forgot =>
        'We will send a one-time passcode to your verified email.',
      _AuthMode.otp => 'Enter the one-time passcode before it expires.',
      _AuthMode.reset =>
        'Choose a strong password to complete account recovery.',
    };
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({
    required this.title,
    required this.action,
    required this.icon,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final String title;
  final String action;
  final IconData icon;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = FitnessBrandTheme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$title $action',
      child: InkWell(
        borderRadius: BorderRadius.circular(brand.radiusMd),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withOpacity(.14)
                : scheme.surface.withOpacity(.48),
            borderRadius: BorderRadius.circular(brand.radiusMd),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 21, color: selected ? scheme.primary : null),
                  const Spacer(),
                  if (locked)
                    Icon(Icons.lock_outline, size: 18, color: scheme.secondary)
                  else
                    Icon(Icons.check_rounded, size: 18, color: scheme.primary),
                ],
              ),
              const SizedBox(height: 14),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 3),
              Text(
                action,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.controller,
    required this.slides,
    required this.page,
    required this.onPageChanged,
    this.compact = false,
  });

  final PageController controller;
  final List<_HeroSlide> slides;
  final int page;
  final ValueChanged<int> onPageChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brand = FitnessBrandTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: brand.heroGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(compact ? 22 : 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        onSurface: Colors.white,
                        primary: Colors.white,
                      ),
                    ),
                    child: AnimatedBrandMark(
                      size: compact ? 48 : 66,
                      showWordmark: !compact,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: compact ? 164 : 250,
                    child: PageView.builder(
                      controller: controller,
                      onPageChanged: onPageChanged,
                      itemCount: slides.length,
                      itemBuilder: (context, index) {
                        final slide = slides[index];
                        return _HeroSlideView(slide: slide, compact: compact);
                      },
                    ),
                  ),
                  SizedBox(height: compact ? 18 : 28),
                  Row(
                    children: [
                      for (var i = 0; i < slides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: page == i ? 34 : 9,
                          height: 9,
                          margin: const EdgeInsets.only(right: 7),
                          decoration: BoxDecoration(
                            color: page == i
                                ? Colors.white
                                : Colors.white.withOpacity(.38),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                    ],
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 34),
                    const _TrustBar(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSlideView extends StatelessWidget {
  const _HeroSlideView({required this.slide, required this.compact});

  final _HeroSlide slide;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: compact ? 52 : 66,
          height: compact ? 52 : 66,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(.18)),
          ),
          child: Icon(slide.icon, color: Colors.white, size: compact ? 28 : 34),
        ),
        SizedBox(height: compact ? 12 : 22),
        Text(
          slide.title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          slide.message,
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.white.withOpacity(.82)),
        ),
        SizedBox(height: compact ? 14 : 22),
        _MetricPill(value: slide.metric, label: slide.metricLabel),
      ],
    );
  }
}

class _TrustBar extends StatelessWidget {
  const _TrustBar();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: const [
        _HeroBadge(icon: Icons.lock_outline, label: 'Portal-ready'),
        _HeroBadge(icon: Icons.verified_user_outlined, label: 'Member signup'),
        _HeroBadge(icon: Icons.fingerprint, label: 'Biometric-ready'),
      ],
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withOpacity(.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withOpacity(.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSlide {
  const _HeroSlide({
    required this.icon,
    required this.title,
    required this.message,
    required this.metric,
    required this.metricLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final String metric;
  final String metricLabel;
}
