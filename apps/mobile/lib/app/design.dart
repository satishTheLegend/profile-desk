import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

ThemeData deskTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xff21675e),
    brightness: brightness,
    primary: dark ? const Color(0xffa1d5c6) : const Color(0xff21675e),
    onPrimary: dark ? const Color(0xff103a32) : Colors.white,
    primaryContainer: dark ? const Color(0xff26483e) : const Color(0xffdfede3),
    onPrimaryContainer: dark
        ? const Color(0xffdaeee2)
        : const Color(0xff173d34),
    surface: dark ? const Color(0xff131d19) : const Color(0xfff8f8f2),
    onSurface: dark ? const Color(0xffe7eee6) : const Color(0xff1b302a),
    onSurfaceVariant: dark ? const Color(0xffb9c7be) : const Color(0xff50645b),
    surfaceContainerLowest: dark ? const Color(0xff17241e) : Colors.white,
    surfaceContainerLow: dark
        ? const Color(0xff1b2a23)
        : const Color(0xfff0f2eb),
    surfaceContainer: dark ? const Color(0xff22332b) : const Color(0xffe9eee6),
    outlineVariant: dark ? const Color(0xff40574b) : const Color(0xffcbd8ce),
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
  return ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 32),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 54),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        side: BorderSide(color: scheme.outlineVariant),
        shape: shape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 36,
        height: 1.16,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.3,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 25,
        height: 1.24,
        fontWeight: FontWeight.w700,
        letterSpacing: -.7,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -.3,
      ),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );
}

class DeskIcon extends StatelessWidget {
  const DeskIcon(this.name, {super.key, this.size = 22, this.color});
  final String name;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ??
            IconTheme.of(context).color ??
            Theme.of(context).colorScheme.onSurface,
        BlendMode.srcIn,
      ),
    ),
  );
}

class ProfileMark extends StatelessWidget {
  const ProfileMark({
    super.key,
    required this.alias,
    required this.color,
    this.size = 40,
  });
  final String alias;
  final int color;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color(color).withValues(alpha: .15),
        border: Border.all(color: Color(color).withValues(alpha: .22)),
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: Text(
        alias.trim().isEmpty ? '?' : alias.characters.first.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: size * .4,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),
  );
}

/// A quiet surface for a meaningful group of related controls or information.
class DeskSurface extends StatelessWidget {
  const DeskSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.emphasized = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: emphasized
          ? colors.primaryContainer
          : colors.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: emphasized
              ? colors.primary.withValues(alpha: .2)
              : colors.outlineVariant,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class ContentColumn extends StatelessWidget {
  const ContentColumn({super.key, required this.children, this.maxWidth = 620});
  final List<Widget> children;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: EdgeInsets.all(constraints.maxWidth < 360 ? 20 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}
