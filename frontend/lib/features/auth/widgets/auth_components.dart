import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

class AnimatedBrandMark extends StatefulWidget {
  const AnimatedBrandMark({
    super.key,
    this.size = 76,
    this.showWordmark = true,
  });

  final double size;
  final bool showWordmark;

  @override
  State<AnimatedBrandMark> createState() => _AnimatedBrandMarkState();
}

class _AnimatedBrandMarkState extends State<AnimatedBrandMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = FitnessBrandTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'FitFlow Elite brand',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final lift = math.sin(_controller.value * math.pi) * 6;
              return Transform.translate(
                offset: Offset(0, -lift),
                child: Transform.rotate(
                  angle: (_controller.value - .5) * .12,
                  child: child,
                ),
              );
            },
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: brand.accentGradient,
                borderRadius: BorderRadius.circular(widget.size * .28),
                boxShadow: brand.premiumShadow,
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                color: Colors.white,
                size: widget.size * .48,
              ),
            ),
          ),
          if (widget.showWordmark) ...[
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FitFlow',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'ELITE TRAINING CLUB',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class PremiumAuthCard extends StatelessWidget {
  const PremiumAuthCard({super.key, required this.child, this.maxWidth = 520});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final brand = FitnessBrandTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: brand.cardGradient,
            borderRadius: BorderRadius.circular(brand.radiusLg),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(.08)
                  : Colors.black.withOpacity(.06),
            ),
            boxShadow: brand.premiumShadow,
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: scheme.onSurface),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AuthModeSegment extends StatelessWidget {
  const AuthModeSegment({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = FitnessBrandTheme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(brand.radiusMd),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withOpacity(.14)
                : scheme.surface.withOpacity(.38),
            borderRadius: BorderRadius.circular(brand.radiusMd),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? scheme.primary : null),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? scheme.primary : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegistrationProgress extends StatelessWidget {
  const RegistrationProgress({
    super.key,
    required this.currentStep,
    required this.labels,
  });

  final int currentStep;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= currentStep
                        ? scheme.primary
                        : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[i],
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: i == currentStep
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (i != labels.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 10),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final details = evaluatePasswordStrength(password);
    final scheme = Theme.of(context).colorScheme;
    final brand = FitnessBrandTheme.of(context);
    final color = switch (details.score) {
      <= 1 => scheme.error,
      2 => brand.warning,
      3 => brand.info,
      _ => brand.success,
    };

    return Semantics(
      label: 'Password strength ${details.label}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: details.score / 4,
              backgroundColor: scheme.outlineVariant.withOpacity(.55),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(details.icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  details.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PasswordStrengthDetails {
  const PasswordStrengthDetails({
    required this.score,
    required this.label,
    required this.icon,
  });

  final int score;
  final String label;
  final IconData icon;
}

PasswordStrengthDetails evaluatePasswordStrength(String value) {
  var score = 0;
  if (value.length >= 8) score++;
  if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) {
    score++;
  }
  if (RegExp(r'\d').hasMatch(value)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(value) || value.length >= 12) {
    score++;
  }

  return switch (score) {
    0 || 1 => const PasswordStrengthDetails(
      score: 1,
      label: 'Weak password: use 8+ characters with mixed case and a number.',
      icon: Icons.error_outline,
    ),
    2 => const PasswordStrengthDetails(
      score: 2,
      label: 'Fair password: add a symbol or make it longer.',
      icon: Icons.shield_outlined,
    ),
    3 => const PasswordStrengthDetails(
      score: 3,
      label: 'Strong password: suitable for everyday account access.',
      icon: Icons.verified_user_outlined,
    ),
    _ => const PasswordStrengthDetails(
      score: 4,
      label: 'Elite password: excellent strength for secure access.',
      icon: Icons.workspace_premium_outlined,
    ),
  };
}

class OtpCodeField extends StatelessWidget {
  const OtpCodeField({super.key, required this.controller, this.validator});

  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      textAlign: TextAlign.center,
      maxLength: 6,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 10,
      ),
      decoration: const InputDecoration(
        labelText: '6-digit email OTP',
        counterText: '',
        prefixIcon: Icon(Icons.pin_outlined),
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.visible,
    required this.message,
  });

  final bool visible;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = FitnessBrandTheme.of(context);
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: ColoredBox(
          color: Colors.black.withOpacity(.46),
          child: Center(
            child: Container(
              width: 230,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(brand.radiusLg),
                boxShadow: brand.premiumShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox.square(
                    dimension: 34,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SuccessPulse extends StatelessWidget {
  const SuccessPulse({super.key, required this.icon, this.size = 76});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final brand = FitnessBrandTheme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .82, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: brand.accentGradient,
          shape: BoxShape.circle,
          boxShadow: brand.premiumShadow,
        ),
        child: Icon(icon, color: Colors.white, size: size * .48),
      ),
    );
  }
}
