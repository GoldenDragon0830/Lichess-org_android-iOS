import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lichess_mobile/src/styles/lichess_colors.dart';

// ignore: avoid_classes_with_only_static_members
abstract class Styles {
  // text
  static const bold = TextStyle(fontWeight: FontWeight.bold);
  static const title = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
  );
  static const subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  static final callout = TextStyle(
    fontSize: defaultTargetPlatform == TargetPlatform.iOS ? 20 : 18,
    letterSpacing: defaultTargetPlatform == TargetPlatform.iOS ? -0.41 : null,
    fontWeight: FontWeight.w600,
  );
  static final mainListTileTitle = TextStyle(
    fontSize: defaultTargetPlatform == TargetPlatform.iOS ? 19 : 18,
    letterSpacing: defaultTargetPlatform == TargetPlatform.iOS ? -0.41 : null,
    fontWeight: FontWeight.w500,
  );
  static const mainListTileIconSize = 28.0;
  static final sectionTitle = TextStyle(
    fontSize: defaultTargetPlatform == TargetPlatform.iOS ? 20 : 18,
    letterSpacing: defaultTargetPlatform == TargetPlatform.iOS ? -0.41 : null,
    fontWeight: FontWeight.bold,
  );
  static const boardPreviewTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  static const subtitleOpacity = 0.7;
  static const timeControl = TextStyle(
    letterSpacing: 1.2,
  );
  static const formLabel = TextStyle(
    fontWeight: FontWeight.bold,
  );
  static const formError = TextStyle(
    color: LichessColors.red,
  );
  static const formDescription = TextStyle(fontSize: 12);

  // padding
  static const cupertinoAppBarTrailingWidgetPadding =
      EdgeInsetsDirectional.only(
    end: 8.0,
  );
  static const bodyPadding =
      EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0);
  static const verticalBodyPadding = EdgeInsets.symmetric(vertical: 16.0);

  // colors
  static Color? expansionTileColor(BuildContext context) =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? CupertinoColors.secondaryLabel.resolveFrom(context)
          : null;
  static const cupertinoAppBarColor = CupertinoDynamicColor.withBrightness(
    color: Color(0xE6F9F9F9),
    darkColor: Color.fromARGB(210, 36, 36, 38),
  );
  static const cupertinoScaffoldColor = CupertinoDynamicColor.withBrightness(
    color: Color.fromARGB(255, 242, 242, 247),
    darkColor: Color.fromARGB(255, 23, 23, 23),
  );

  static const _cupertinoDarkLabelColor = Color(0xFFDCDCDC);
  static const cupertinoLabelColor = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF000000),
    darkColor: _cupertinoDarkLabelColor,
  );
  static const cupertinoTitleColor = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF000000),
    darkColor: Color(0xFFF5F5F5),
  );
  static const cupertinoCardColor = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFFFFFF),
    darkColor: Color.fromARGB(255, 44, 44, 46),
  );
  static const cupertinoSeparatorColor = CupertinoDynamicColor.withBrightness(
    debugLabel: 'separator',
    color: Color.fromARGB(73, 60, 60, 67),
    darkColor: Color.fromARGB(153, 101, 101, 105),
  );

  /// A Material Design text theme with light glyphs based on San Francisco.
  ///
  /// This [TextTheme] provides color but not geometry (font size, weight, etc).
  ///
  /// This theme uses the iOS version of the font names.
  static const TextTheme whiteCupertinoTextTheme = TextTheme(
    displayLarge: TextStyle(
      debugLabel: 'whiteCupertino displayLarge',
      fontFamily: 'CupertinoSystemDisplay',
      color: Color(0xFFF5F5F5),
      decoration: TextDecoration.none,
    ),
    displayMedium: TextStyle(
      debugLabel: 'whiteCupertino displayMedium',
      fontFamily: 'CupertinoSystemDisplay',
      color: Color(0xFFF5F5F5),
      decoration: TextDecoration.none,
    ),
    displaySmall: TextStyle(
      debugLabel: 'whiteCupertino displaySmall',
      fontFamily: 'CupertinoSystemDisplay',
      color: Color(0xFFF5F5F5),
      decoration: TextDecoration.none,
    ),
    headlineLarge: TextStyle(
      debugLabel: 'whiteCupertino headlineLarge',
      fontFamily: 'CupertinoSystemDisplay',
      color: Color(0xFFF5F5F5),
      decoration: TextDecoration.none,
    ),
    headlineMedium: TextStyle(
      debugLabel: 'whiteCupertino headlineMedium',
      fontFamily: 'CupertinoSystemDisplay',
      color: Color(0xFFF5F5F5),
      decoration: TextDecoration.none,
    ),
    headlineSmall: TextStyle(
      debugLabel: 'whiteCupertino headlineSmall',
      fontFamily: 'CupertinoSystemDisplay',
      color: Color(0xFFF5F5F5),
      decoration: TextDecoration.none,
    ),
    titleLarge: TextStyle(
      debugLabel: 'whiteCupertino titleLarge',
      fontFamily: 'CupertinoSystemDisplay',
      color: _cupertinoDarkLabelColor,
      decoration: TextDecoration.none,
    ),
    titleMedium: TextStyle(
      debugLabel: 'whiteCupertino titleMedium',
      fontFamily: 'CupertinoSystemText',
      color: _cupertinoDarkLabelColor,
      decoration: TextDecoration.none,
    ),
    titleSmall: TextStyle(
      debugLabel: 'whiteCupertino titleSmall',
      fontFamily: 'CupertinoSystemText',
      color: _cupertinoDarkLabelColor,
      decoration: TextDecoration.none,
    ),
    bodyLarge: TextStyle(
      debugLabel: 'whiteCupertino bodyLarge',
      fontFamily: 'CupertinoSystemText',
      color: _cupertinoDarkLabelColor,
      decoration: TextDecoration.none,
    ),
    bodyMedium: TextStyle(
      debugLabel: 'whiteCupertino bodyMedium',
      fontFamily: 'CupertinoSystemText',
      color: _cupertinoDarkLabelColor,
      decoration: TextDecoration.none,
    ),
    bodySmall: TextStyle(
      debugLabel: 'whiteCupertino bodySmall',
      fontFamily: 'CupertinoSystemText',
      color: _cupertinoDarkLabelColor,
      decoration: TextDecoration.none,
    ),
    labelLarge: TextStyle(
      debugLabel: 'whiteCupertino labelLarge',
      fontFamily: 'CupertinoSystemText',
      color: _cupertinoDarkLabelColor,
      decoration: TextDecoration.none,
    ),
    labelMedium: TextStyle(
      debugLabel: 'whiteCupertino labelMedium',
      fontFamily: 'CupertinoSystemText',
      color: _cupertinoDarkLabelColor,
      decoration: TextDecoration.none,
    ),
    labelSmall: TextStyle(
      debugLabel: 'whiteCupertino labelSmall',
      fontFamily: 'CupertinoSystemText',
      color: _cupertinoDarkLabelColor,
      decoration: TextDecoration.none,
    ),
  );

  /// Gets horizontal padding according to platform.
  static const horizontalBodyPadding = EdgeInsets.symmetric(horizontal: 16.0);
  static const sectionBottomPadding = EdgeInsets.only(bottom: 16);
  static const sectionTopPadding = EdgeInsets.only(top: 16);

  /// Horizontal and bottom padding for a body section
  static EdgeInsetsGeometry get bodySectionPadding =>
      horizontalBodyPadding.add(sectionBottomPadding).add(sectionTopPadding);

  static EdgeInsetsGeometry get bodySectionBottomPadding =>
      horizontalBodyPadding.add(sectionBottomPadding);

  // from:
  // https://github.com/flutter/flutter/blob/796c8ef79279f9c774545b3771238c3098dbefab/packages/flutter/lib/src/cupertino/bottom_tab_bar.dart#L17
  static const CupertinoDynamicColor cupertinoDefaultTabBarBorderColor =
      CupertinoDynamicColor.withBrightness(
    color: Color(0x4D000000),
    darkColor: Color(0x29000000),
  );
}

/// Retrieve the default text color and apply an opacity to it.
Color? textShade(BuildContext context, double opacity) =>
    DefaultTextStyle.of(context).style.color?.withOpacity(opacity);

Color? dividerColor(BuildContext context) =>
    defaultTargetPlatform == TargetPlatform.iOS
        ? CupertinoColors.separator.resolveFrom(context)
        : null;

Color darken(Color c, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);
  final f = 1 - amount;
  return Color.fromARGB(
    c.alpha,
    (c.red * f).round(),
    (c.green * f).round(),
    (c.blue * f).round(),
  );
}

Color lighten(Color c, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);
  return Color.fromARGB(
    c.alpha,
    c.red + ((255 - c.red) * amount).round(),
    c.green + ((255 - c.green) * amount).round(),
    c.blue + ((255 - c.blue) * amount).round(),
  );
}

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.cyan,
    required this.brag,
    required this.good,
    required this.error,
    required this.fancy,
    required this.purple,
    required this.primary,
  });

  final Color cyan;
  final Color brag;
  final Color good;
  final Color error;
  final Color fancy;
  final Color purple;
  final Color primary;

  @override
  CustomColors copyWith({
    Color? cyan,
    Color? brag,
    Color? good,
    Color? error,
    Color? fancy,
    Color? purple,
    Color? primary,
  }) {
    return CustomColors(
      cyan: cyan ?? this.cyan,
      brag: brag ?? this.brag,
      good: good ?? this.good,
      error: error ?? this.error,
      fancy: fancy ?? this.fancy,
      purple: purple ?? this.purple,
      primary: primary ?? this.primary,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      cyan: Color.lerp(cyan, other.cyan, t) ?? cyan,
      brag: Color.lerp(brag, other.brag, t) ?? brag,
      good: Color.lerp(good, other.good, t) ?? good,
      error: Color.lerp(error, other.error, t) ?? error,
      fancy: Color.lerp(fancy, other.fancy, t) ?? fancy,
      purple: Color.lerp(purple, other.purple, t) ?? purple,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
    );
  }

  CustomColors harmonized(ColorScheme colorScheme) {
    return copyWith(
      cyan: cyan.harmonizeWith(colorScheme.primary),
      brag: brag.harmonizeWith(colorScheme.primary),
      good: good.harmonizeWith(colorScheme.primary),
      error: error.harmonizeWith(colorScheme.primary),
      fancy: fancy.harmonizeWith(colorScheme.primary),
      purple: purple.harmonizeWith(colorScheme.primary),
      primary: primary.harmonizeWith(colorScheme.primary),
    );
  }
}

const lichessCustomColors = CustomColors(
  cyan: LichessColors.cyan,
  brag: LichessColors.brag,
  good: LichessColors.good,
  error: LichessColors.error,
  fancy: LichessColors.fancy,
  purple: LichessColors.purple,
  primary: LichessColors.primary,
);

extension CustomColorsBuildContext on BuildContext {
  CustomColors get lichessColors =>
      Theme.of(this).extension<CustomColors>() ?? lichessCustomColors;
}
