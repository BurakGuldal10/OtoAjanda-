import 'package:flutter/material.dart';

/// GaleriPro design token'ları — tüm ekranlarda bu sınıf kullanılır.
class AppTheme {
  // ── Koyu Sidebar ─────────────────────────────────────────────────
  static const Color sidebarBg = Color(0xFF0F172A);         // slate-900
  static const Color sidebarSurface = Color(0xFF1E293B);    // slate-800
  static const Color sidebarBorder = Color(0xFF1E293B);     // slate-800
  static const Color sidebarIcon = Color(0xFF64748B);       // slate-500
  static const Color sidebarIconActive = Color(0xFF60A5FA); // blue-400
  static const Color sidebarText = Color(0xFF94A3B8);       // slate-400
  static const Color sidebarTextActive = Color(0xFFF1F5F9); // slate-100
  static const Color sidebarActiveBg = Color(0xFF1D3461);   // dark-blue
  static const Color sidebarGroupLabel = Color(0xFF334155); // slate-700
  static const Color sidebarAccent = Color(0xFF3B82F6);     // blue-500

  // ── Marka Renkleri ────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);      // blue-600
  static const Color primaryDark = Color(0xFF1D4ED8);  // blue-700
  static const Color primaryLight = Color(0xFFDBEAFE); // blue-100
  static const Color primaryMid = Color(0xFF3B82F6);   // blue-500

  // ── Arka Plan ─────────────────────────────────────────────────────
  static const Color bgPage = Color(0xFFF1F5F9);    // slate-100
  static const Color bgCard = Colors.white;
  static const Color bgMuted = Color(0xFFF8FAFC);   // slate-50
  static const Color bgHover = Color(0xFFF1F5F9);   // slate-100

  // ── Metin ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);   // slate-900
  static const Color textSecondary = Color(0xFF475569); // slate-600
  static const Color textMuted = Color(0xFF94A3B8);     // slate-400

  // ── Kenar ─────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);      // slate-200
  static const Color borderLight = Color(0xFFF1F5F9); // slate-100

  // ── Durum Renkleri ────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);     // green-600
  static const Color successBg = Color(0xFFF0FDF4);
  static const Color successText = Color(0xFF166534);
  static const Color error = Color(0xFFDC2626);       // red-600
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFD97706);     // amber-600
  static const Color warningBg = Color(0xFFFFFBEB);

  // ── İkon Arka Planları ────────────────────────────────────────────
  static const Color iconBgBlue = Color(0xFFDBEAFE);
  static const Color iconBgGreen = Color(0xFFD1FAE5);
  static const Color iconBgAmber = Color(0xFFFEF3C7);
  static const Color iconBgPurple = Color(0xFFEDE9FE);
  static const Color iconBgTeal = Color(0xFFCCFBF1);
  static const Color iconBgRose = Color(0xFFFFE4E6);

  static const Color iconBlue = Color(0xFF2563EB);
  static const Color iconGreen = Color(0xFF059669);
  static const Color iconAmber = Color(0xFFD97706);
  static const Color iconPurple = Color(0xFF7C3AED);
  static const Color iconTeal = Color(0xFF0D9488);
  static const Color iconRose = Color(0xFFE11D48);

  // ── Gölge Sistemi ─────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  // ── Gradyanlar ───────────────────────────────────────────────────
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
  );
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF047857)],
  );
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
  );
  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );
  static const LinearGradient roseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF43F5E), Color(0xFFBE123C)],
  );
  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
  );
  static const LinearGradient slateGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF475569), Color(0xFF1E293B)],
  );

  // ── Sidebar Yeni ─────────────────────────────────────────────────
  static const Color sidebarNew       = Color(0xFF0D1117); // github dark
  static const Color sidebarNewSurf   = Color(0xFF161B22); // elevated surface
  static const Color sidebarNewBorder = Color(0xFF21262D);
  static const Color sidebarNewText   = Color(0xFF8B949E); // inactive
  static const Color sidebarNewActive = Color(0xFFE6EDF3); // active text
  static const Color sidebarNewAccent = Color(0xFF58A6FF); // blue-400

  // ── Gradyan Hero ──────────────────────────────────────────────────
  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
    stops: [0.0, 0.5, 1.0],
  );
  static const LinearGradient blueShineGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
  );

  // ── Auth Gradyanı ─────────────────────────────────────────────────
  static const LinearGradient authGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1E40AF)],
    stops: [0.0, 0.55, 1.0],
  );

  // ── Hero Dashboard Gradyanı ───────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
    stops: [0.0, 0.5, 1.0],
  );
}
