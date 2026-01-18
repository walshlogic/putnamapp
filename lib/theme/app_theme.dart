import 'package:flutter/material.dart';

// IMPORTANT: ALL TEXT IN THE APP SHOULD BE DISPLAYED IN UPPERCASE
// When displaying text from data sources, always use .toUpperCase()
// Example: Text(booking.name.toUpperCase())

/// AppColors - Centralized color palette for the entire app
/// All colors should be referenced from this extension
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    // Base colors
    required this.white,
    required this.black,

    // Purple theme colors
    required this.primaryPurple,
    required this.lightPurple,
    required this.darkPurple,
    required this.purpleGradientStart,
    required this.purpleGradientEnd,

    // Background colors
    required this.scaffoldBackground,
    required this.cardBackground,

    // Text colors
    required this.textDark,
    required this.textMedium,
    required this.textLight,

    // Accent colors
    required this.accentPink,
    required this.accentPinkDark,
    required this.accentTeal,
    required this.accentTealDark,
    required this.accentOrange,
    required this.accentOrangeDark,

    // UI element colors
    required this.divider,
    required this.border,
    required this.iconBackground,

    // Weather gradient colors
    required this.weatherGradientStart,
    required this.weatherGradientEnd,
  });

  // Base colors
  final Color white;
  final Color black;

  // Purple theme colors
  final Color primaryPurple;
  final Color lightPurple;
  final Color darkPurple;
  final Color purpleGradientStart;
  final Color purpleGradientEnd;

  // Background colors
  final Color scaffoldBackground;
  final Color cardBackground;

  // Text colors
  final Color textDark;
  final Color textMedium;
  final Color textLight;

  // Accent colors
  final Color accentPink;
  final Color accentPinkDark;
  final Color accentTeal;
  final Color accentTealDark;
  final Color accentOrange;
  final Color accentOrangeDark;

  // UI element colors
  final Color divider;
  final Color border;
  final Color iconBackground;

  // Weather gradient colors
  final Color weatherGradientStart;
  final Color weatherGradientEnd;

  @override
  AppColors copyWith({
    Color? white,
    Color? black,
    Color? primaryPurple,
    Color? lightPurple,
    Color? darkPurple,
    Color? purpleGradientStart,
    Color? purpleGradientEnd,
    Color? scaffoldBackground,
    Color? cardBackground,
    Color? textDark,
    Color? textMedium,
    Color? textLight,
    Color? accentPink,
    Color? accentPinkDark,
    Color? accentTeal,
    Color? accentTealDark,
    Color? accentOrange,
    Color? accentOrangeDark,
    Color? divider,
    Color? border,
    Color? iconBackground,
    Color? weatherGradientStart,
    Color? weatherGradientEnd,
  }) {
    return AppColors(
      white: white ?? this.white,
      black: black ?? this.black,
      primaryPurple: primaryPurple ?? this.primaryPurple,
      lightPurple: lightPurple ?? this.lightPurple,
      darkPurple: darkPurple ?? this.darkPurple,
      purpleGradientStart: purpleGradientStart ?? this.purpleGradientStart,
      purpleGradientEnd: purpleGradientEnd ?? this.purpleGradientEnd,
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      textDark: textDark ?? this.textDark,
      textMedium: textMedium ?? this.textMedium,
      textLight: textLight ?? this.textLight,
      accentPink: accentPink ?? this.accentPink,
      accentPinkDark: accentPinkDark ?? this.accentPinkDark,
      accentTeal: accentTeal ?? this.accentTeal,
      accentTealDark: accentTealDark ?? this.accentTealDark,
      accentOrange: accentOrange ?? this.accentOrange,
      accentOrangeDark: accentOrangeDark ?? this.accentOrangeDark,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      iconBackground: iconBackground ?? this.iconBackground,
      weatherGradientStart: weatherGradientStart ?? this.weatherGradientStart,
      weatherGradientEnd: weatherGradientEnd ?? this.weatherGradientEnd,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      white: Color.lerp(white, other.white, t)!,
      black: Color.lerp(black, other.black, t)!,
      primaryPurple: Color.lerp(primaryPurple, other.primaryPurple, t)!,
      lightPurple: Color.lerp(lightPurple, other.lightPurple, t)!,
      darkPurple: Color.lerp(darkPurple, other.darkPurple, t)!,
      purpleGradientStart: Color.lerp(
        purpleGradientStart,
        other.purpleGradientStart,
        t,
      )!,
      purpleGradientEnd: Color.lerp(
        purpleGradientEnd,
        other.purpleGradientEnd,
        t,
      )!,
      scaffoldBackground: Color.lerp(
        scaffoldBackground,
        other.scaffoldBackground,
        t,
      )!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      textDark: Color.lerp(textDark, other.textDark, t)!,
      textMedium: Color.lerp(textMedium, other.textMedium, t)!,
      textLight: Color.lerp(textLight, other.textLight, t)!,
      accentPink: Color.lerp(accentPink, other.accentPink, t)!,
      accentPinkDark: Color.lerp(accentPinkDark, other.accentPinkDark, t)!,
      accentTeal: Color.lerp(accentTeal, other.accentTeal, t)!,
      accentTealDark: Color.lerp(accentTealDark, other.accentTealDark, t)!,
      accentOrange: Color.lerp(accentOrange, other.accentOrange, t)!,
      accentOrangeDark: Color.lerp(
        accentOrangeDark,
        other.accentOrangeDark,
        t,
      )!,
      divider: Color.lerp(divider, other.divider, t)!,
      border: Color.lerp(border, other.border, t)!,
      iconBackground: Color.lerp(iconBackground, other.iconBackground, t)!,
      weatherGradientStart: Color.lerp(
        weatherGradientStart,
        other.weatherGradientStart,
        t,
      )!,
      weatherGradientEnd: Color.lerp(
        weatherGradientEnd,
        other.weatherGradientEnd,
        t,
      )!,
    );
  }
}

@immutable
class FooterStyles extends ThemeExtension<FooterStyles> {
  const FooterStyles({required this.fontSize, required this.opacity});

  final double fontSize;
  final double opacity;

  @override
  FooterStyles copyWith({double? fontSize, double? opacity}) {
    return FooterStyles(
      fontSize: fontSize ?? this.fontSize,
      opacity: opacity ?? this.opacity,
    );
  }

  @override
  FooterStyles lerp(ThemeExtension<FooterStyles>? other, double t) {
    if (other is! FooterStyles) return this;
    return FooterStyles(
      fontSize: lerpDouble(fontSize, other.fontSize, t) ?? fontSize,
      opacity: lerpDouble(opacity, other.opacity, t) ?? opacity,
    );
  }
}

@immutable
class CardTextStyles extends ThemeExtension<CardTextStyles> {
  const CardTextStyles({required this.cardTitleSize});

  final double cardTitleSize;

  @override
  CardTextStyles copyWith({double? cardTitleSize}) {
    return CardTextStyles(cardTitleSize: cardTitleSize ?? this.cardTitleSize);
  }

  @override
  CardTextStyles lerp(ThemeExtension<CardTextStyles>? other, double t) {
    if (other is! CardTextStyles) return this;
    return CardTextStyles(
      cardTitleSize:
          lerpDouble(cardTitleSize, other.cardTitleSize, t) ?? cardTitleSize,
    );
  }
}

@immutable
class DetailScreenStyles extends ThemeExtension<DetailScreenStyles> {
  const DetailScreenStyles({
    required this.sectionTitleSize,
    required this.sectionIconSize,
    required this.personNameSize,
    required this.infoLabelSize,
    required this.infoValueSize,
    required this.chargeDetailLabelSize,
    required this.chargeDetailValueSize,
    required this.statisticNumberSize,
    required this.statisticLabelSize,
  });

  final double sectionTitleSize; // PERSONAL INFORMATION, BOOKING DETAILS, etc.
  final double sectionIconSize; // Icon size in section headers
  final double personNameSize; // Person's name (centered)
  final double
  infoLabelSize; // Labels in info rows (Age at Booking, Race, etc.)
  final double infoValueSize; // Values in info rows
  final double
  chargeDetailLabelSize; // Charge detail labels (Statute:, Bond:, etc.)
  final double chargeDetailValueSize; // Charge detail values
  final double statisticNumberSize; // Large numbers (# BOOKINGS, # CHARGES)
  final double statisticLabelSize; // Statistic labels

  @override
  DetailScreenStyles copyWith({
    double? sectionTitleSize,
    double? sectionIconSize,
    double? personNameSize,
    double? infoLabelSize,
    double? infoValueSize,
    double? chargeDetailLabelSize,
    double? chargeDetailValueSize,
    double? statisticNumberSize,
    double? statisticLabelSize,
  }) {
    return DetailScreenStyles(
      sectionTitleSize: sectionTitleSize ?? this.sectionTitleSize,
      sectionIconSize: sectionIconSize ?? this.sectionIconSize,
      personNameSize: personNameSize ?? this.personNameSize,
      infoLabelSize: infoLabelSize ?? this.infoLabelSize,
      infoValueSize: infoValueSize ?? this.infoValueSize,
      chargeDetailLabelSize:
          chargeDetailLabelSize ?? this.chargeDetailLabelSize,
      chargeDetailValueSize:
          chargeDetailValueSize ?? this.chargeDetailValueSize,
      statisticNumberSize: statisticNumberSize ?? this.statisticNumberSize,
      statisticLabelSize: statisticLabelSize ?? this.statisticLabelSize,
    );
  }

  @override
  DetailScreenStyles lerp(ThemeExtension<DetailScreenStyles>? other, double t) {
    if (other is! DetailScreenStyles) return this;
    return DetailScreenStyles(
      sectionTitleSize:
          lerpDouble(sectionTitleSize, other.sectionTitleSize, t) ??
          sectionTitleSize,
      sectionIconSize:
          lerpDouble(sectionIconSize, other.sectionIconSize, t) ??
          sectionIconSize,
      personNameSize:
          lerpDouble(personNameSize, other.personNameSize, t) ?? personNameSize,
      infoLabelSize:
          lerpDouble(infoLabelSize, other.infoLabelSize, t) ?? infoLabelSize,
      infoValueSize:
          lerpDouble(infoValueSize, other.infoValueSize, t) ?? infoValueSize,
      chargeDetailLabelSize:
          lerpDouble(chargeDetailLabelSize, other.chargeDetailLabelSize, t) ??
          chargeDetailLabelSize,
      chargeDetailValueSize:
          lerpDouble(chargeDetailValueSize, other.chargeDetailValueSize, t) ??
          chargeDetailValueSize,
      statisticNumberSize:
          lerpDouble(statisticNumberSize, other.statisticNumberSize, t) ??
          statisticNumberSize,
      statisticLabelSize:
          lerpDouble(statisticLabelSize, other.statisticLabelSize, t) ??
          statisticLabelSize,
    );
  }
}

@immutable
class PersonCardStyles extends ThemeExtension<PersonCardStyles> {
  const PersonCardStyles({
    required this.subtitleStyle,
    required this.nameStyle,
    required this.detailStyle,
    required this.photoRadius,
    required this.labelStyle,
  });

  final TextStyle subtitleStyle; // Date/time or secondary info
  final TextStyle nameStyle; // Person name
  final TextStyle detailStyle; // Charges, address, or details
  final double photoRadius; // Photo/icon size
  final TextStyle labelStyle; // Small labels

  @override
  PersonCardStyles copyWith({
    TextStyle? subtitleStyle,
    TextStyle? nameStyle,
    TextStyle? detailStyle,
    double? photoRadius,
    TextStyle? labelStyle,
  }) {
    return PersonCardStyles(
      subtitleStyle: subtitleStyle ?? this.subtitleStyle,
      nameStyle: nameStyle ?? this.nameStyle,
      detailStyle: detailStyle ?? this.detailStyle,
      photoRadius: photoRadius ?? this.photoRadius,
      labelStyle: labelStyle ?? this.labelStyle,
    );
  }

  @override
  PersonCardStyles lerp(ThemeExtension<PersonCardStyles>? other, double t) {
    if (other is! PersonCardStyles) return this;
    return PersonCardStyles(
      subtitleStyle:
          TextStyle.lerp(subtitleStyle, other.subtitleStyle, t) ??
          subtitleStyle,
      nameStyle: TextStyle.lerp(nameStyle, other.nameStyle, t) ?? nameStyle,
      detailStyle:
          TextStyle.lerp(detailStyle, other.detailStyle, t) ?? detailStyle,
      photoRadius: lerpDouble(photoRadius, other.photoRadius, t) ?? photoRadius,
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t) ?? labelStyle,
    );
  }
}

// Legacy alias for backwards compatibility
typedef BookingStyles = PersonCardStyles;

double? lerpDouble(num? a, num? b, double t) {
  if (a == null && b == null) return null;
  final double start = (a ?? 0).toDouble();
  final double end = (b ?? 0).toDouble();
  return start + (end - start) * t;
}

class AppTheme {
  static const Color primaryPurple = Color(0xFF8B7FED);
  static const Color lightPurple = Color(0xFFE8E5FF);
  static const Color darkPurple = Color(0xFF6B5DD3);

  static LinearGradient get purpleGradient => const LinearGradient(
    colors: <Color>[Color(0xFF9B8EF7), Color(0xFF7E6FE8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primaryPurple,
      brightness: Brightness.light,
    );
    final TextTheme baseText = Typography.englishLike2021.apply(
      displayColor: const Color(0xFF2D2D3A),
      bodyColor: const Color(0xFF5A5A6B),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(
        0xFFDAD7FF,
      ), // Purple background matching home screen
      textTheme: baseText.copyWith(
        titleLarge: baseText.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2D2D3A),
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2D2D3A),
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(color: const Color(0xFF5A5A6B)),
        bodyMedium: baseText.bodyMedium?.copyWith(
          color: const Color(0xFF5A5A6B),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:
            primaryPurple, // Purple background matching home screen AppBar
        foregroundColor: Colors
            .white, // White icons and text for contrast on purple background
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize:
              18.0, // Adjust AppBar title font size here (affects "PUTNAM.APP" and all screen titles)
          fontWeight: FontWeight.bold,
          color: Colors.white, // White text for contrast on purple background
        ),
        centerTitle: true,
      ),
      extensions: <ThemeExtension<dynamic>>[
        // AppColors - All color definitions in one place
        const AppColors(
          // Base colors
          white: Color(0xFFFFFFFF),
          black: Color(0xFF000000),

          // Purple theme colors
          primaryPurple: Color(0xFF8B7FED),
          lightPurple: Color(0xFFE8E5FF),
          darkPurple: Color(0xFF6B5DD3),
          purpleGradientStart: Color(0xFF9B8EF7),
          purpleGradientEnd: Color(0xFF7E6FE8),

          // Background colors
          scaffoldBackground: Color(
            0xFFDAD7FF,
          ), // Purple background matching home screen
          cardBackground: Color(0xFFFFFFFF),

          // Text colors
          textDark: Color(0xFF2D2D3A),
          textMedium: Color(0xFF5A5A6B),
          textLight: Color(0xFF8B8B8B),

          // Accent colors
          accentPink: Color(0xFFFF6B9D),
          accentPinkDark: Color(0xFFC06C84),
          accentTeal: Color(0xFF4ECDC4),
          accentTealDark: Color(0xFF44A08D),
          accentOrange: Color(0xFFFF9F40),
          accentOrangeDark: Color(0xFFFF6F00),

          // UI element colors
          divider: Color(0xFFCCCCCC),
          border: Color(0xFFE0E0E0),
          iconBackground: Color(0xFFE8E5FF),

          // Weather gradient colors
          weatherGradientStart: Color(0xFFFFE5B4),
          weatherGradientEnd: Color(0xFFB4D4FF),
        ),
        const FooterStyles(
          fontSize: 16, // Adjust footer font size here
          opacity: 0.4, // Adjust footer opacity here (0.0-1.0)
        ),
        const CardTextStyles(
          cardTitleSize:
              22.0, // Adjust card title font size here (JAIL, SOCIAL, OFFENDER, etc.)
        ),
        const DetailScreenStyles(
          sectionTitleSize:
              16.0, // Section headers (PERSONAL INFORMATION, etc.)
          sectionIconSize: 24.0, // Section header icons
          personNameSize: 14.0, // Person's name (centered)
          infoLabelSize: 12.0, // Info row labels
          infoValueSize: 14.0, // Info row values
          chargeDetailLabelSize: 12.0, // Charge labels (Statute:, Bond:)
          chargeDetailValueSize: 12.0, // Charge values
          statisticNumberSize: 32.0, // # BOOKINGS, # CHARGES numbers
          statisticLabelSize: 11.0, // # BOOKINGS, # CHARGES labels
        ),
        PersonCardStyles(
          subtitleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          nameStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          detailStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          photoRadius: 72, // Adjust here to change photo/icon size globally
          labelStyle: const TextStyle(
            fontSize: 11, // Small size for labels
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
