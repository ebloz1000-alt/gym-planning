import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../providers_or_bloc/app_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPageData(
      icon: Icons.bolt_rounded,
      title: 'Premium training access',
      message:
          'Book equipment, reserve trainer-led sessions, and see gym availability before you arrive.',
      stat: '12k+',
      statLabel: 'sessions managed',
    ),
    _OnboardingPageData(
      icon: Icons.workspace_premium_rounded,
      title: 'Memberships without friction',
      message:
          'Track plans, expiry windows, payment state, and renewal moments with a polished member experience.',
      stat: '4',
      statLabel: 'membership tiers',
    ),
    _OnboardingPageData(
      icon: Icons.insights_rounded,
      title: 'One command center',
      message:
          'Members, trainers, and admins get role-specific dashboards backed by the same business logic.',
      stat: '3',
      statLabel: 'secure workspaces',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = FitnessBrandTheme.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surface,
              scheme.primary.withValues(alpha: .08),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 920;
              final horizontalPadding = isWide ? 32.0 : 18.0;
              final compactHeroHeight = (constraints.maxHeight * .58)
                  .clamp(340.0, 430.0)
                  .toDouble();

              Widget buildHeader() {
                return Row(
                  children: [
                    _BrandLockup(compact: !isWide),
                    const Spacer(),
                    TextButton(
                      onPressed: AppScope.read(context).completeOnboarding,
                      child: const Text('Skip'),
                    ),
                  ],
                );
              }

              return Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: isWide
                    ? Column(
                        children: [
                          buildHeader(),
                          const SizedBox(height: 28),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 11,
                                  child: _OnboardingHero(
                                    controller: _controller,
                                    pages: _pages,
                                    page: _page,
                                    onPageChanged: (value) =>
                                        setState(() => _page = value),
                                  ),
                                ),
                                const SizedBox(width: 28),
                                Expanded(
                                  flex: 8,
                                  child: _OnboardingControls(
                                    pages: _pages,
                                    page: _page,
                                    brand: brand,
                                    controller: _controller,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight:
                                constraints.maxHeight - horizontalPadding * 2,
                          ),
                          child: Column(
                            children: [
                              buildHeader(),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: compactHeroHeight,
                                child: _OnboardingHero(
                                  controller: _controller,
                                  pages: _pages,
                                  page: _page,
                                  compact: true,
                                  onPageChanged: (value) =>
                                      setState(() => _page = value),
                                ),
                              ),
                              const SizedBox(height: 18),
                              _OnboardingControls(
                                pages: _pages,
                                page: _page,
                                brand: brand,
                                controller: _controller,
                                compact: true,
                              ),
                            ],
                          ),
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero({
    required this.controller,
    required this.pages,
    required this.page,
    required this.onPageChanged,
    this.compact = false,
  });

  final PageController controller;
  final List<_OnboardingPageData> pages;
  final int page;
  final ValueChanged<int> onPageChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brand = FitnessBrandTheme.of(context);
    final padding = compact ? 20.0 : 28.0;
    final iconSize = compact ? 58.0 : 74.0;
    final iconRadius = compact ? 18.0 : 22.0;
    final iconGlyphSize = compact ? 30.0 : 38.0;
    final titleStyle = compact
        ? Theme.of(context).textTheme.headlineSmall
        : Theme.of(context).textTheme.headlineLarge;
    final messageStyle = compact
        ? Theme.of(context).textTheme.bodyMedium
        : Theme.of(context).textTheme.bodyLarge;

    return ClipRRect(
      borderRadius: BorderRadius.circular(brand.radiusLg),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: brand.heroGradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: controller,
              onPageChanged: onPageChanged,
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final item = pages[index];
                return Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!compact) const Spacer(),
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(iconRadius),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .16),
                          ),
                        ),
                        child: Icon(
                          item.icon,
                          color: Colors.white,
                          size: iconGlyphSize,
                        ),
                      ),
                      SizedBox(height: compact ? 14 : 24),
                      Text(
                        item.title,
                        maxLines: compact ? 2 : null,
                        overflow: compact ? TextOverflow.ellipsis : null,
                        style: titleStyle?.copyWith(color: Colors.white),
                      ),
                      SizedBox(height: compact ? 8 : 12),
                      Text(
                        item.message,
                        maxLines: compact ? 3 : null,
                        overflow: compact ? TextOverflow.ellipsis : null,
                        style: messageStyle?.copyWith(
                          color: Colors.white.withValues(alpha: .82),
                        ),
                      ),
                      SizedBox(height: compact ? 16 : 22),
                      _OnboardingMetric(
                        value: item.stat,
                        label: item.statLabel,
                        compact: compact,
                      ),
                      if (!compact)
                        const Spacer()
                      else
                        const SizedBox(height: 18),
                      Row(
                        children: [
                          for (var i = 0; i < pages.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: page == i ? 34 : 9,
                              height: 9,
                              margin: const EdgeInsets.only(right: 7),
                              decoration: BoxDecoration(
                                color: page == i
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: .38),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingControls extends StatelessWidget {
  const _OnboardingControls({
    required this.pages,
    required this.page,
    required this.brand,
    required this.controller,
    this.compact = false,
  });

  final List<_OnboardingPageData> pages;
  final int page;
  final FitnessBrandTheme brand;
  final PageController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final current = pages[page];
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 28),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(brand.radiusLg),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .7)),
        boxShadow: brand.softShadow,
      ),
      child: Column(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) const Spacer(),
          Text(
            'Gym Equipment & Trainer Booking Management Mobile Application',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(current.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text(
            current.message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Member')),
              Chip(label: Text('Trainer')),
              Chip(label: Text('Admin')),
              Chip(label: Text('M-Pesa ready')),
            ],
          ),
          SizedBox(height: compact ? 20 : 28),
          AppButton(
            label: page == pages.length - 1 ? 'Get started' : 'Next',
            icon: page == pages.length - 1
                ? Icons.login_rounded
                : Icons.arrow_forward_rounded,
            expand: true,
            onPressed: () {
              if (page == pages.length - 1) {
                AppScope.read(context).completeOnboarding();
              } else {
                controller.nextPage(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                );
              }
            },
          ),
          if (!compact) const Spacer(),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brand = FitnessBrandTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: compact ? 42 : 50,
          height: compact ? 42 : 50,
          decoration: BoxDecoration(
            gradient: brand.accentGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.fitness_center_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          'Gym Equipment & Trainer Booking Management Mobile Application',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _OnboardingMetric extends StatelessWidget {
  const _OnboardingMetric({
    required this.value,
    required this.label,
    this.compact = false,
  });

  final String value;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style:
                (compact
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.headlineSmall)
                    ?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
          ),
          SizedBox(width: compact ? 8 : 10),
          Flexible(
            child: Text(
              label,
              maxLines: compact ? 1 : null,
              overflow: compact ? TextOverflow.ellipsis : null,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white.withValues(alpha: .78),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.message,
    required this.stat,
    required this.statLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final String stat;
  final String statLabel;
}
