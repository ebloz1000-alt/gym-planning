import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

@immutable
class FitnessBrandTheme extends ThemeExtension<FitnessBrandTheme> {
  const FitnessBrandTheme({
    required this.heroGradient,
    required this.cardGradient,
    required this.accentGradient,
    required this.success,
    required this.warning,
    required this.info,
    required this.premiumShadow,
    required this.softShadow,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
  });

  final LinearGradient heroGradient;
  final LinearGradient cardGradient;
  final LinearGradient accentGradient;
  final Color success;
  final Color warning;
  final Color info;
  final List<BoxShadow> premiumShadow;
  final List<BoxShadow> softShadow;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;

  static FitnessBrandTheme of(BuildContext context) {
    return Theme.of(context).extension<FitnessBrandTheme>()!;
  }

  @override
  FitnessBrandTheme copyWith({
    LinearGradient? heroGradient,
    LinearGradient? cardGradient,
    LinearGradient? accentGradient,
    Color? success,
    Color? warning,
    Color? info,
    List<BoxShadow>? premiumShadow,
    List<BoxShadow>? softShadow,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
  }) {
    return FitnessBrandTheme(
      heroGradient: heroGradient ?? this.heroGradient,
      cardGradient: cardGradient ?? this.cardGradient,
      accentGradient: accentGradient ?? this.accentGradient,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      premiumShadow: premiumShadow ?? this.premiumShadow,
      softShadow: softShadow ?? this.softShadow,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
    );
  }

  @override
  FitnessBrandTheme lerp(ThemeExtension<FitnessBrandTheme>? other, double t) {
    if (other is! FitnessBrandTheme) return this;
    return FitnessBrandTheme(
      heroGradient:
          LinearGradient.lerp(heroGradient, other.heroGradient, t) ??
          heroGradient,
      cardGradient:
          LinearGradient.lerp(cardGradient, other.cardGradient, t) ??
          cardGradient,
      accentGradient:
          LinearGradient.lerp(accentGradient, other.accentGradient, t) ??
          accentGradient,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
      premiumShadow:
          BoxShadow.lerpList(premiumShadow, other.premiumShadow, t) ??
          premiumShadow,
      softShadow:
          BoxShadow.lerpList(softShadow, other.softShadow, t) ?? softShadow,
      radiusSm: _lerpDouble(radiusSm, other.radiusSm, t),
      radiusMd: _lerpDouble(radiusMd, other.radiusMd, t),
      radiusLg: _lerpDouble(radiusLg, other.radiusLg, t),
    );
  }
}

class AppTheme {
  const AppTheme._();

  static const _carbon = Color(0xFF0B0F14);
  static const _charcoal = Color(0xFF151A21);
  static const _paper = Color(0xFFF7F8FA);
  static const _electricMint = Color(0xFF11D7A3);
  static const _signalRed = Color(0xFFFF4D5E);
  static const _cobalt = Color(0xFF4F7CFF);
  static const _amber = Color(0xFFFFB84D);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _electricMint,
      brightness: Brightness.light,
      primary: const Color(0xFF007F68),
      secondary: _signalRed,
      tertiary: _cobalt,
      surface: _paper,
    );
    return _base(scheme, _lightBrand, isDark: false);
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _electricMint,
      brightness: Brightness.dark,
      primary: _electricMint,
      secondary: const Color(0xFFFF6D7A),
      tertiary: const Color(0xFF8EAAFF),
      surface: _carbon,
    );
    return _base(scheme, _darkBrand, isDark: true);
  }

  static final _lightBrand = FitnessBrandTheme(
    heroGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF091016),
        Color(0xFF123D37),
        Color(0xFF0FA784),
        Color(0xFFFF4D5E),
      ],
      stops: [0, .46, .78, 1],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, const Color(0xFFF0FFF9)],
    ),
    accentGradient: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [_electricMint, _cobalt],
    ),
    success: const Color(0xFF12B886),
    warning: _amber,
    info: _cobalt,
    premiumShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.12),
        blurRadius: 32,
        offset: const Offset(0, 18),
      ),
    ],
    softShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.08),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
    radiusSm: 10,
    radiusMd: 18,
    radiusLg: 28,
  );

  static final _darkBrand = FitnessBrandTheme(
    heroGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF020506),
        Color(0xFF101A20),
        Color(0xFF0C7E69),
        Color(0xFF522630),
      ],
      stops: [0, .48, .8, 1],
    ),
    cardGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A2028), Color(0xFF10171B)],
    ),
    accentGradient: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [_electricMint, Color(0xFF8EAAFF)],
    ),
    success: const Color(0xFF2FDC9C),
    warning: const Color(0xFFFFC66B),
    info: const Color(0xFF8EAAFF),
    premiumShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.34),
        blurRadius: 34,
        offset: const Offset(0, 20),
      ),
    ],
    softShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.22),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
    radiusSm: 10,
    radiusMd: 18,
    radiusLg: 28,
  );

  static ThemeData _base(
    ColorScheme scheme,
    FitnessBrandTheme brand, {
    required bool isDark,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      visualDensity: VisualDensity.standard,
    );
    final textTheme = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
        height: .98,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.42),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.42),
    );

    return base.copyWith(
      extensions: [brand],
      scaffoldBackgroundColor: isDark ? _carbon : _paper,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? _carbon : _paper,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? _charcoal : Colors.white,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(brand.radiusMd),
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(.08)
                : Colors.black.withOpacity(.06),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(.055)
            : Colors.white.withOpacity(.92),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        floatingLabelStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
        ),
        labelStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(.66)),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        errorMaxLines: 2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(brand.radiusMd),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(brand.radiusMd),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(.08)
                : Colors.black.withOpacity(.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(brand.radiusMd),
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(brand.radiusMd),
          borderSide: BorderSide(color: scheme.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(brand.radiusMd),
          borderSide: BorderSide(color: scheme.error, width: 1.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(brand.radiusMd),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(brand.radiusMd),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(brand.radiusSm),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? Colors.white.withOpacity(.06)
            : Colors.black.withOpacity(.04),
        selectedColor: scheme.primaryContainer,
        side: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(.08)
              : Colors.black.withOpacity(.08),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(brand.radiusSm),
        ),
        labelStyle: textTheme.labelMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: isDark ? _charcoal : Colors.white,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? _charcoal : Colors.white,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? _charcoal : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(brand.radiusLg),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withOpacity(.08)
            : Colors.black.withOpacity(.07),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: isDark ? Colors.white : _carbon,
        contentTextStyle: TextStyle(color: isDark ? _carbon : Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(brand.radiusMd),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
