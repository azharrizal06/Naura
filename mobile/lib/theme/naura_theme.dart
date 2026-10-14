import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet naura — diambil dari kain.
class NauraColors {
  NauraColors._();

  static const kabut = Color(0xFFF3F1F5); // latar
  static const terong = Color(0xFF2B1830); // tinta
  static const plum = Color(0xFF6E2F63); // aksi
  static const plumTint = Color(0xFFF1E7EF);
  static const kuningan = Color(0xFF9C7A3C); // benang emas
  static const garis = Color(0xFFE2DCE6);
  static const garisKuat = Color(0xFFCFC6D5);
  static const muted = Color(0xFF6F6375);
  static const marun = Color(0xFFA3343F);
  static const marunTint = Color(0xFFF8E9EB);
}

/// Judul & wordmark memakai Marcellus.
TextStyle display(double size, {Color color = NauraColors.terong}) =>
    GoogleFonts.marcellus(fontSize: size, color: color, height: 1.15);

ThemeData buildNauraTheme() {
  final base = ThemeData(useMaterial3: true);
  final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
    bodyColor: NauraColors.terong,
    displayColor: NauraColors.terong,
  );
  const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: NauraColors.plum,
      primary: NauraColors.plum,
      onPrimary: Colors.white,
      surface: NauraColors.kabut,
      onSurface: NauraColors.terong,
      error: NauraColors.marun,
    ),
    scaffoldBackgroundColor: NauraColors.kabut,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: NauraColors.kabut,
      foregroundColor: NauraColors.terong,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: display(22),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NauraColors.plum,
        foregroundColor: Colors.white,
        disabledBackgroundColor: NauraColors.garis,
        disabledForegroundColor: NauraColors.muted,
        minimumSize: const Size.fromHeight(52),
        shape: shape,
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: NauraColors.plum,
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: const TextStyle(color: NauraColors.muted),
      floatingLabelStyle: const TextStyle(color: NauraColors.plum),
      hintStyle: const TextStyle(color: NauraColors.muted),
      border: _border(NauraColors.garisKuat),
      enabledBorder: _border(NauraColors.garisKuat),
      focusedBorder: _border(NauraColors.plum, width: 1.5),
      errorBorder: _border(NauraColors.marun),
      focusedErrorBorder: _border(NauraColors.marun, width: 1.5),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: NauraColors.terong,
      behavior: SnackBarBehavior.floating,
      shape: shape,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: NauraColors.plumTint,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? NauraColors.terong : NauraColors.muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? NauraColors.plum : NauraColors.muted,
          )),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: NauraColors.plum,
    ),
    pageTransitionsTheme: base.pageTransitionsTheme,
  );
}

OutlineInputBorder _border(Color color, {double width = 1}) => OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: color, width: width),
    );
