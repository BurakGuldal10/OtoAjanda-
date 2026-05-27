import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/supabase_config.dart';
import 'config/app_theme.dart';
import 'screens/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  await SupabaseConfig.initialize();

  // Flutter Windows klavye state tutarsızlığını önler
  HardwareKeyboard.instance.addHandler(_keyboardHandler);

  runApp(const OtoGaleriApp());
}

bool _keyboardHandler(KeyEvent event) => false;

class OtoGaleriApp extends StatelessWidget {
  const OtoGaleriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GaleriPro',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('tr', 'TR'),
      home: const AuthGate(),
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppTheme.primary,
        onPrimary: Colors.white,
        primaryContainer: AppTheme.primaryLight,
        onPrimaryContainer: AppTheme.primaryDark,
        surface: AppTheme.bgCard,
        onSurface: AppTheme.textPrimary,
        error: AppTheme.error,
        surfaceContainerHighest: AppTheme.bgMuted,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w800),
        displayMedium: GoogleFonts.inter(fontWeight: FontWeight.w800),
        headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w400, color: AppTheme.textPrimary),
        bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w400, color: AppTheme.textPrimary),
        labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
      scaffoldBackgroundColor: AppTheme.bgPage,

      // Kart teması — gölge ile
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppTheme.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input tema
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.bgMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
        ),
        labelStyle:
            GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
        floatingLabelStyle:
            GoogleFonts.inter(color: AppTheme.primary, fontSize: 12),
        hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14),
        errorStyle: GoogleFonts.inter(color: AppTheme.error, fontSize: 11.5),
      ),

      // Filled button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textSecondary,
          side: const BorderSide(color: AppTheme.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppTheme.border,
        space: 1,
        thickness: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppTheme.bgMuted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: AppTheme.border),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppTheme.bgCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentTextStyle: GoogleFonts.inter(fontSize: 13.5),
      ),
    );
  }
}
