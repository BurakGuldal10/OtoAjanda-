import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../services/auth_service.dart';
import '../../services/vehicle_service.dart';
import '../../utils/error_handler.dart';
import '../vehicles/vehicle_list_screen.dart';
import '../vehicles/add_vehicle_screen.dart';
import '../stats/stats_screen.dart';
import '../sales/sales_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Lokal renk token'ları — tema dosyasını kirletmemek için
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  // İçerik alanı
  static const bg      = Color(0xFFF8FAFC);   // slate-50
  static const surface = Colors.white;
  static const border  = Color(0xFFE2E8F0);   // slate-200
  static const text1   = Color(0xFF0F172A);   // slate-900
  static const text2   = Color(0xFF475569);   // slate-600
  static const text3   = Color(0xFF94A3B8);   // slate-400

  // Durum renkleri
  static const blue   = Color(0xFF2563EB);
  static const green  = Color(0xFF059669);
  static const amber  = Color(0xFFD97706);
  static const purple = Color(0xFF7C3AED);
  static const red    = Color(0xFFDC2626);

  // Sidebar (koyu)
  static const sideBase   = Color(0xFF0D1117);
  static const sideBorder = Color(0xFF21262D);
  static const sideText   = Color(0xFF8B949E);
  static const sideActive = Color(0xFFE6EDF3);
  static const sideAccent = Color(0xFF58A6FF);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _vehicleService = VehicleService();
  final _authService    = AuthService();
  final _paraFormati    = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  Map<String, dynamic> _stats = {};
  bool _isLoading    = true;
  int  _aktifIndex   = 0;

  bool get _isMobile => MediaQuery.sizeOf(context).width < 700;

  String get _kullaniciEmail =>
      SupabaseConfig.client.auth.currentUser?.email ?? '';

  String get _gosterimAdi {
    final raw = _kullaniciEmail.split('@').first;
    if (raw.isEmpty) return 'Kullanıcı';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String get _kullaniciBasHarf =>
      _gosterimAdi.isNotEmpty ? _gosterimAdi[0].toUpperCase() : 'K';

  @override
  void initState() {
    super.initState();
    _istatistikYukle();
  }

  Future<void> _istatistikYukle() async {
    setState(() => _isLoading = true);
    try {
      final s = await _vehicleService.getStats();
      setState(() {
        _stats     = s;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppError.from(e, ctx: 'Veriler yüklenemedi')),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  Future<void> _aracEkle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
    );
    if (result == true) _istatistikYukle();
  }

  @override
  Widget build(BuildContext context) {
    return _isMobile ? _mobileDuzen() : _masaustuDuzen();
  }

  // ══════════════════════════════════════════════════════════════════
  // MASAÜSTÜ DÜZEN
  // ══════════════════════════════════════════════════════════════════
  Widget _masaustuDuzen() {
    return Scaffold(
      backgroundColor: _T.bg,
      body: Row(
        children: [
          // Koyu sidebar
          _SidebarKoyu(
            aktifIndex:   _aktifIndex,
            basHarf:      _kullaniciBasHarf,
            gosterimAdi:  _gosterimAdi,
            email:        _kullaniciEmail,
            onNavSec:     (i) {
              setState(() => _aktifIndex = i);
              if (i == 0) _istatistikYukle();
            },
            onCikis: () => _authService.signOut(),
          ),
          // İçerik alanı
          Expanded(
            child: Column(
              children: [
                _UstBar(
                  baslik:       _getBaslik(),
                  aracEkleGoster: _aktifIndex <= 2,
                  onAracEkle:   _aracEkle,
                ),
                Expanded(child: _icerik()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // MOBİL DÜZEN
  // ══════════════════════════════════════════════════════════════════
  Widget _mobileDuzen() {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: _MobilUstBar(
        gosterimAdi: _gosterimAdi,
        basHarf:     _kullaniciBasHarf,
        email:       _kullaniciEmail,
        onCikis:     () => _authService.signOut(),
      ),
      body: _icerik(),
      bottomNavigationBar: _AltNavigasyon(
        aktifIndex: _aktifIndex,
        onSec: (i) {
          setState(() => _aktifIndex = i);
          if (i == 0) _istatistikYukle();
        },
      ),
      floatingActionButton: _aktifIndex <= 2
          ? FloatingActionButton(
              onPressed: _aracEkle,
              backgroundColor: _T.blue,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, size: 22),
            )
          : null,
    );
  }

  Widget _icerik() {
    switch (_aktifIndex) {
      case 0:  return _dashboard();
      case 1:  return VehicleListScreen(onRefresh: _istatistikYukle);
      case 2:  return const SalesScreen();
      case 3:  return const StatsScreen();
      default: return const SizedBox();
    }
  }

  String _getBaslik() {
    switch (_aktifIndex) {
      case 0:  return 'Ana Sayfa';
      case 1:  return 'Araçlar';
      case 2:  return 'Satışlar';
      case 3:  return 'İstatistikler';
      default: return '';
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // DASHBOARD İÇERİĞİ
  // ══════════════════════════════════════════════════════════════════
  Widget _dashboard() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32, height: 32,
              child: CircularProgressIndicator(
                color: _T.blue, strokeWidth: 2.5),
            ),
            const SizedBox(height: 16),
            Text('Veriler yükleniyor...',
                style: GoogleFonts.inter(fontSize: 13, color: _T.text3)),
          ],
        ),
      );
    }

    final netKar  = (_stats['toplamKar']    ?? 0.0) as double;
    final brutKar = (_stats['brutKar']      ?? 0.0) as double;

    // LayoutBuilder ile gerçek içerik genişliğini al.
    // Sidebar (232px) zaten dışarıda olduğu için MediaQuery yerine
    // bu değer kullanılır — kutular doğru genişliğe göre ölçeklenir.
    return LayoutBuilder(
      builder: (context, constraints) {
        final genislik = constraints.maxWidth;
        // Dar: < 520px  →  mobil yığın düzeni
        // Orta: 520–860px  →  2 sütun KPI
        // Geniş: ≥ 860px  →  4 sütun KPI, yatay hero
        final p = genislik < 520 ? 16.0 : 28.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(p, p, p, p + 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Karşılama satırı ──────────────────────────────
              _KarsilamaSatiri(
                gosterimAdi: _gosterimAdi,
                onYenile:    _istatistikYukle,
                genislik:    genislik,
              ),
              SizedBox(height: genislik < 520 ? 20 : 24),

              // ── Gradyan hero kart ─────────────────────────────
              _GradyanHeroKarti(
                netKar:       netKar,
                brutKar:      brutKar,
                stoktaAdet:   _stats['stoktaAdet']   ?? 0,
                satilanAdet:  _stats['satilanAdet']  ?? 0,
                rezerveAdet:  _stats['rezerveAdet']  ?? 0,
                paraFormati:  _paraFormati,
                genislik:     genislik,
              ),
              SizedBox(height: genislik < 520 ? 14 : 16),

              // ── KPI kartları ──────────────────────────────────
              _KpiIzgarasi(
                stoktaAdet:  _stats['stoktaAdet']    ?? 0,
                satilanAdet: _stats['satilanAdet']   ?? 0,
                rezerveAdet: _stats['rezerveAdet']   ?? 0,
                yatirim:    (_stats['toplamYatirim'] ?? 0.0) as double,
                paraFormati: _paraFormati,
                genislik:    genislik,
              ),
              SizedBox(height: genislik < 520 ? 24 : 28),

              // ── Hızlı işlemler ────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  'Hızlı İşlemler',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _T.text2,
                  ),
                ),
              ),
              _HizliIslemler(
                onAracEkle:    _aracEkle,
                onAracListesi: () => setState(() => _aktifIndex = 1),
                onRaporlar:    () => setState(() => _aktifIndex = 3),
                genislik:      genislik,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KOYU SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarKoyu extends StatelessWidget {
  final int          aktifIndex;
  final String       basHarf;
  final String       gosterimAdi;
  final String       email;
  final ValueChanged<int> onNavSec;
  final VoidCallback onCikis;

  const _SidebarKoyu({
    required this.aktifIndex,
    required this.basHarf,
    required this.gosterimAdi,
    required this.email,
    required this.onNavSec,
    required this.onCikis,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      color: _T.sideBase,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo alanı (mavi gradient) ───────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E40AF), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.directions_car_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GaleriPro',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Araç Yönetimi',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── MENÜ grubu ───────────────────────────────────────────
          _NavGrupEtiketi('MENÜ'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                _SideNavItem(0, Icons.home_rounded,
                    Icons.home_outlined, 'Ana Sayfa', aktifIndex, onNavSec),
                _SideNavItem(1, Icons.directions_car_rounded,
                    Icons.directions_car_outlined, 'Araçlar', aktifIndex, onNavSec),
                _SideNavItem(2, Icons.sell_rounded,
                    Icons.sell_outlined, 'Satışlar', aktifIndex, onNavSec),
              ],
            ),
          ),

          const SizedBox(height: 4),
          _NavGrupEtiketi('ANALİZ'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _SideNavItem(3, Icons.bar_chart_rounded,
                Icons.bar_chart_outlined, 'İstatistikler', aktifIndex, onNavSec),
          ),

          const Spacer(),

          // ── Bölücü ───────────────────────────────────────────────
          Container(height: 1, color: _T.sideBorder),

          // ── Çıkış ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: _SideCikisButon(onCikis: onCikis),
          ),

          Container(height: 1, color: _T.sideBorder),

          // ── Kullanıcı footer ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Row(
              children: [
                _GradyanAvatar(basHarf: basHarf, boyut: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gosterimAdi,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _T.sideActive,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        email,
                        style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: _T.sideText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Sidebar grup etiketi
class _NavGrupEtiketi extends StatelessWidget {
  final String etiket;
  const _NavGrupEtiketi(this.etiket);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      child: Text(
        etiket,
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF4B5563), // slate-600 — koyu arka planda görünür
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// Sidebar nav öğesi — sol kenar göstergesi ile aktif durum
class _SideNavItem extends StatefulWidget {
  final int    index;
  final IconData aktifIkon;
  final IconData pasifIkon;
  final String label;
  final int    aktifIndex;
  final ValueChanged<int> onSec;

  const _SideNavItem(this.index, this.aktifIkon, this.pasifIkon,
      this.label, this.aktifIndex, this.onSec);

  @override
  State<_SideNavItem> createState() => _SideNavItemState();
}

class _SideNavItemState extends State<_SideNavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final aktif = widget.aktifIndex == widget.index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        cursor:  SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => widget.onSec(widget.index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: aktif
                  ? Colors.white.withValues(alpha: 0.06)
                  : _hover
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              // Aktif sol kenar çizgisi
              border: aktif
                  ? Border(
                      left: BorderSide(
                          color: _T.sideAccent, width: 2.5))
                  : null,
            ),
            child: Row(
              children: [
                // Aktif olmayan ise boşluk bırak (sol border kalınlığı için)
                if (!aktif) const SizedBox(width: 2.5),
                Icon(
                  aktif ? widget.aktifIkon : widget.pasifIkon,
                  size: 16,
                  color: aktif ? _T.sideAccent : _T.sideText,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight:
                        aktif ? FontWeight.w600 : FontWeight.w400,
                    color: aktif ? _T.sideActive : _T.sideText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Sidebar çıkış butonu
class _SideCikisButon extends StatefulWidget {
  final VoidCallback onCikis;
  const _SideCikisButon({required this.onCikis});

  @override
  State<_SideCikisButon> createState() => _SideCikisButonState();
}

class _SideCikisButonState extends State<_SideCikisButon> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      cursor:  SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onCikis,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _hover
                ? const Color(0xFF1F0707).withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const SizedBox(width: 2.5),
              Icon(Icons.logout_rounded,
                  size: 16,
                  color: _hover ? const Color(0xFFF87171) : _T.sideText),
              const SizedBox(width: 10),
              Text(
                'Çıkış Yap',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _hover ? const Color(0xFFF87171) : _T.sideText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ÜST BAR (masaüstü)
// ─────────────────────────────────────────────────────────────────────────────
class _UstBar extends StatelessWidget {
  final String       baslik;
  final bool         aracEkleGoster;
  final VoidCallback onAracEkle;

  const _UstBar({
    required this.baslik,
    required this.aracEkleGoster,
    required this.onAracEkle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: _T.surface,
        border: Border(bottom: BorderSide(color: _T.border)),
      ),
      child: Row(
        children: [
          Text(
            baslik,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _T.text1,
            ),
          ),
          const Spacer(),
          if (aracEkleGoster) _AracEkleButon(onTap: onAracEkle),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOBİL ÜST BAR
// ─────────────────────────────────────────────────────────────────────────────
class _MobilUstBar extends StatelessWidget implements PreferredSizeWidget {
  final String       gosterimAdi;
  final String       basHarf;
  final String       email;
  final VoidCallback onCikis;

  const _MobilUstBar({
    required this.gosterimAdi,
    required this.basHarf,
    required this.email,
    required this.onCikis,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          backgroundColor: _T.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 20,
          title: Text(
            'GaleriPro',
            style: GoogleFonts.inter(
              color: _T.text1,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: _GradyanAvatar(basHarf: basHarf, boyut: 32),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              onSelected: (v) { if (v == 'cikis') onCikis(); },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  height: 52,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(gosterimAdi,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _T.text1)),
                      Text(email,
                          style: GoogleFonts.inter(
                              fontSize: 11.5, color: _T.text3)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'cikis',
                  child: Row(children: [
                    Icon(Icons.logout_rounded, size: 15, color: _T.red),
                    const SizedBox(width: 8),
                    Text('Çıkış Yap',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: _T.red)),
                  ]),
                ),
              ],
            ),
            const SizedBox(width: 12),
          ],
        ),
        Container(height: 1, color: _T.border),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ALT NAVİGASYON (mobil)
// ─────────────────────────────────────────────────────────────────────────────
class _AltNavigasyon extends StatelessWidget {
  final int                aktifIndex;
  final ValueChanged<int> onSec;

  const _AltNavigasyon({required this.aktifIndex, required this.onSec});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        border: Border(top: BorderSide(color: _T.border)),
      ),
      child: BottomNavigationBar(
        currentIndex:        aktifIndex,
        onTap:               onSec,
        type:                BottomNavigationBarType.fixed,
        backgroundColor:     Colors.transparent,
        elevation:           0,
        selectedItemColor:   _T.blue,
        unselectedItemColor: _T.text3,
        selectedLabelStyle:  GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Ana Sayfa'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car_rounded),
              label: 'Araçlar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.sell_outlined),
              activeIcon: Icon(Icons.sell_rounded),
              label: 'Satışlar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Raporlar'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KARŞILAMA SATIRI
// ─────────────────────────────────────────────────────────────────────────────
class _KarsilamaSatiri extends StatelessWidget {
  final String       gosterimAdi;
  final VoidCallback onYenile;
  final double       genislik;

  const _KarsilamaSatiri({
    required this.gosterimAdi,
    required this.onYenile,
    required this.genislik,
  });

  @override
  Widget build(BuildContext context) {
    final dar = genislik < 520;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Merhaba, $gosterimAdi 👋',
              style: GoogleFonts.inter(
                fontSize: dar ? 18 : 22,
                fontWeight: FontWeight.w700,
                color: _T.text1,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              DateFormat('dd MMMM yyyy, EEEE', 'tr_TR')
                  .format(DateTime.now()),
              style: GoogleFonts.inter(fontSize: 13, color: _T.text3),
            ),
          ],
        ),
        const Spacer(),
        _YenileButon(onTap: onYenile),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRADYAN HERO KARTI — Net Kâr / Araç özeti toggle ile
// ─────────────────────────────────────────────────────────────────────────────
class _GradyanHeroKarti extends StatefulWidget {
  final double       netKar;
  final double       brutKar;
  final int          stoktaAdet;
  final int          satilanAdet;
  final int          rezerveAdet;
  final NumberFormat paraFormati;
  final double       genislik;

  const _GradyanHeroKarti({
    required this.netKar,
    required this.brutKar,
    required this.stoktaAdet,
    required this.satilanAdet,
    required this.rezerveAdet,
    required this.paraFormati,
    required this.genislik,
  });

  @override
  State<_GradyanHeroKarti> createState() => _GradyanHeroKartiState();
}

class _GradyanHeroKartiState extends State<_GradyanHeroKarti> {
  // false = Net Kâr görünümü, true = Araç Sayıları görünümü
  bool _aracGorunu = false;

  @override
  Widget build(BuildContext context) {
    final dar = widget.genislik < 520;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(dar ? 22 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF1D4ED8),
            Color(0xFF3B82F6),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle butonlar — sağ üste
          Align(
            alignment: Alignment.topRight,
            child: _buildToggle(),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _aracGorunu
                ? _aracIcerik(dar, key: const ValueKey('arac'))
                : _karIcerik(dar, key: const ValueKey('kar')),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn('Net Kâr', !_aracGorunu, () {
            setState(() => _aracGorunu = false);
          }),
          _toggleBtn('Araçlar', _aracGorunu, () {
            setState(() => _aracGorunu = true);
          }),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool aktif, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: aktif ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: aktif ? FontWeight.w700 : FontWeight.w400,
            color: aktif ? Colors.white : Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _karIcerik(bool dar, {Key? key}) {
    final karPositif = widget.netKar >= 0;
    final karEtiket  = karPositif ? 'Kârlı dönem' : 'Zarar dönemi';
    final karIkon    = karPositif
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    if (dar) {
      return Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _etiketPil('NET KÂR'),
          const SizedBox(height: 8),
          Text(
            widget.paraFormati.format(widget.netKar),
            style: GoogleFonts.inter(
              fontSize: 30, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 8),
          _durumPil(karIkon, karEtiket),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _miniStat(Icons.inventory_2_rounded, 'Stokta', '${widget.stoktaAdet} araç')),
            Expanded(child: _miniStat(Icons.sell_rounded, 'Satılan', '${widget.satilanAdet} araç')),
            Expanded(child: _miniStat(Icons.schedule_rounded, 'Rezerve', '${widget.rezerveAdet} araç')),
          ]),
        ],
      );
    }

    return Row(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _etiketPil('NET KÂR'),
            const SizedBox(height: 10),
            Text(
              widget.paraFormati.format(widget.netKar),
              style: GoogleFonts.inter(
                fontSize: 38, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 10),
            _durumPil(karIkon, karEtiket),
          ],
        ),
        const Spacer(),
        _miniStat(Icons.inventory_2_rounded, 'Stokta', '${widget.stoktaAdet} araç'),
        _dikey(),
        _miniStat(Icons.sell_rounded, 'Satılan', '${widget.satilanAdet} araç'),
        _dikey(),
        _miniStat(Icons.schedule_rounded, 'Rezerve', '${widget.rezerveAdet} araç'),
      ],
    );
  }

  Widget _aracIcerik(bool dar, {Key? key}) {
    final toplamArac =
        widget.stoktaAdet + widget.satilanAdet + widget.rezerveAdet;

    if (dar) {
      return Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _etiketPil('ARAÇ ÖZETİ'),
          const SizedBox(height: 8),
          Text(
            '$toplamArac',
            style: GoogleFonts.inter(
              fontSize: 38, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: -1.5,
            ),
          ),
          Text(
            'toplam araç',
            style: GoogleFonts.inter(
              fontSize: 13, color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _aracSayiKutu(Icons.inventory_2_rounded, 'Stokta',
                widget.stoktaAdet, const Color(0xFF60A5FA))),
            const SizedBox(width: 8),
            Expanded(child: _aracSayiKutu(Icons.sell_rounded, 'Satılan',
                widget.satilanAdet, const Color(0xFF34D399))),
            const SizedBox(width: 8),
            Expanded(child: _aracSayiKutu(Icons.schedule_rounded, 'Rezerve',
                widget.rezerveAdet, const Color(0xFFFBBF24))),
          ]),
        ],
      );
    }

    return Row(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _etiketPil('ARAÇ ÖZETİ'),
            const SizedBox(height: 10),
            Text(
              '$toplamArac',
              style: GoogleFonts.inter(
                fontSize: 38, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'toplam kayıtlı araç',
              style: GoogleFonts.inter(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
        const Spacer(),
        _aracSayiKutu(Icons.inventory_2_rounded, 'Stokta',
            widget.stoktaAdet, const Color(0xFF60A5FA)),
        const SizedBox(width: 12),
        _aracSayiKutu(Icons.sell_rounded, 'Satılan',
            widget.satilanAdet, const Color(0xFF34D399)),
        const SizedBox(width: 12),
        _aracSayiKutu(Icons.schedule_rounded, 'Rezerve',
            widget.rezerveAdet, const Color(0xFFFBBF24)),
      ],
    );
  }

  Widget _aracSayiKutu(IconData ikon, String etiket, int sayi, Color renk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ikon, size: 13, color: renk),
              const SizedBox(width: 5),
              Text(etiket,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7))),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$sayi',
            style: GoogleFonts.inter(
              fontSize: 26, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: -1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _etiketPil(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9.5, fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _durumPil(IconData ikon, String etiket) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(etiket,
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _miniStat(IconData ikon, String etiket, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(ikon, size: 13, color: Colors.white.withValues(alpha: 0.6)),
            const SizedBox(width: 5),
            Text(etiket,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6))),
          ]),
          const SizedBox(height: 4),
          Text(deger,
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _dikey() => Container(
      width: 1, height: 44,
      color: Colors.white.withValues(alpha: 0.15));
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI IZGARASI — Sol kenar renkli accent, gölge derinliği
// ─────────────────────────────────────────────────────────────────────────────
class _KpiIzgarasi extends StatelessWidget {
  final int          stoktaAdet;
  final int          satilanAdet;
  final int          rezerveAdet;
  final double       yatirim;
  final NumberFormat paraFormati;
  final double       genislik;

  const _KpiIzgarasi({
    required this.stoktaAdet,
    required this.satilanAdet,
    required this.rezerveAdet,
    required this.yatirim,
    required this.paraFormati,
    required this.genislik,
  });

  @override
  Widget build(BuildContext context) {
    final kartlar = [
      _KpiVeri(
        etiket:  'Stoktaki Araçlar',
        deger:   '$stoktaAdet',
        alt:     'satışa hazır',
        ikon:    Icons.inventory_2_outlined,
        renk:    _T.blue,
        ikonBg:  const Color(0xFFDBEAFE), // blue-100
      ),
      _KpiVeri(
        etiket:  'Satılan Araçlar',
        deger:   '$satilanAdet',
        alt:     'tamamlanan işlem',
        ikon:    Icons.sell_outlined,
        renk:    _T.green,
        ikonBg:  const Color(0xFFD1FAE5), // green-100
      ),
      _KpiVeri(
        etiket:  'Rezerve',
        deger:   '$rezerveAdet',
        alt:     'bekliyor',
        ikon:    Icons.schedule_outlined,
        renk:    _T.amber,
        ikonBg:  const Color(0xFFFEF3C7), // amber-100
      ),
      _KpiVeri(
        etiket:  'Stok Yatırımı',
        deger:   paraFormati.format(yatirim),
        alt:     'mevcut değer',
        ikon:    Icons.account_balance_wallet_outlined,
        renk:    _T.purple,
        ikonBg:  const Color(0xFFEDE9FE), // purple-100
      ),
    ];

    // Genişlik kesme noktaları:
    //   < 520px  → 2 sütun Wrap (dar ekran / mobil)
    //   520–860px → 2 sütun Wrap (dar içerik alanı, ör. küçük pencere + sidebar)
    //   ≥ 860px  → 4 sütun yan yana Row (geniş içerik alanı)
    if (genislik < 860) {
      final kolonGenisligi = (genislik - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: kartlar
            .map((k) => SizedBox(width: kolonGenisligi, child: _KpiKart(k)))
            .toList(),
      );
    }

    // crossAxisAlignment: stretch → tüm kartlar aynı yükseklikte
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: kartlar.asMap().entries.map((e) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                right: e.key < kartlar.length - 1 ? 12 : 0),
            child: _KpiKart(e.value),
          ),
        )).toList(),
      ),
    );
  }
}

class _KpiVeri {
  final String etiket;
  final String deger;
  final String alt;
  final IconData ikon;
  final Color renk;      // kenar accent + ikon arka plan
  final Color ikonBg;    // ikon container solid arka plan

  const _KpiVeri({
    required this.etiket,
    required this.deger,
    required this.alt,
    required this.ikon,
    required this.renk,
    required this.ikonBg,
  });
}

class _KpiKart extends StatefulWidget {
  final _KpiVeri veri;
  const _KpiKart(this.veri);

  @override
  State<_KpiKart> createState() => _KpiKartState();
}

class _KpiKartState extends State<_KpiKart> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final renk = widget.veri.renk;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      cursor:  SystemMouseCursors.basic,
      // Row: sol 4px renkli çizgi + içerik alanı
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hover ? renk.withValues(alpha: 0.03) : _T.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hover ? renk.withValues(alpha: 0.3) : _T.border,
          ),
          boxShadow: [
            BoxShadow(
              color: _hover
                  ? renk.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _hover ? 14 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sol accent çizgisi — sabit genişlik, tam yükseklik
              Container(width: 4, color: renk),

              // Kart içeriği
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dairesel ikon
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: widget.veri.ikonBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.veri.ikon,
                            size: 18, color: renk),
                      ),
                      const SizedBox(height: 12),

                      // Büyük değer — FittedBox ile taşmayı önle
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.veri.deger,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Etiket
                      Text(
                        widget.veri.etiket,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      // Alt metin
                      Text(
                        widget.veri.alt,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8)),
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// HIZLI İŞLEMLER
// ─────────────────────────────────────────────────────────────────────────────
class _HizliIslemler extends StatelessWidget {
  final VoidCallback onAracEkle;
  final VoidCallback onAracListesi;
  final VoidCallback onRaporlar;
  final double       genislik;

  const _HizliIslemler({
    required this.onAracEkle,
    required this.onAracListesi,
    required this.onRaporlar,
    required this.genislik,
  });

  @override
  Widget build(BuildContext context) {
    final islemler = [
      _IslemVeri(
        ikonBg:    const Color(0xFFDBEAFE), // blue-100
        ikon:      Icons.add_circle_outline_rounded,
        baslik:    'Araç Ekle',
        aciklama:  'Yeni araç stoka kaydet',
        onTap:     onAracEkle,
        vurguRenk: _T.blue,
      ),
      _IslemVeri(
        ikonBg:    const Color(0xFFD1FAE5), // green-100
        ikon:      Icons.format_list_bulleted_rounded,
        baslik:    'Araç Listesi',
        aciklama:  'Tüm araçları görüntüle',
        onTap:     onAracListesi,
        vurguRenk: _T.green,
      ),
      _IslemVeri(
        ikonBg:    const Color(0xFFEDE9FE), // purple-100
        ikon:      Icons.bar_chart_outlined,
        baslik:    'Raporlar',
        aciklama:  'Kâr & istatistik analizi',
        onTap:     onRaporlar,
        vurguRenk: _T.purple,
      ),
    ];

    // < 520px → dikey yığın, ≥ 520px → yatay 3 sütun
    if (genislik < 520) {
      return Column(
        children: islemler
            .map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _IslemKarti(i),
                ))
            .toList(),
      );
    }

    return Row(
      children: islemler.asMap().entries.map((e) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(
              right: e.key < islemler.length - 1 ? 12 : 0),
          child: _IslemKarti(e.value),
        ),
      )).toList(),
    );
  }
}

class _IslemVeri {
  final Color        ikonBg;
  final IconData     ikon;
  final String       baslik;
  final String       aciklama;
  final VoidCallback onTap;
  final Color        vurguRenk;

  const _IslemVeri({
    required this.ikonBg,
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    required this.onTap,
    required this.vurguRenk,
  });
}

class _IslemKarti extends StatefulWidget {
  final _IslemVeri veri;
  const _IslemKarti(this.veri);

  @override
  State<_IslemKarti> createState() => _IslemKartiState();
}

class _IslemKartiState extends State<_IslemKarti> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      cursor:  SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.veri.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: _hover
                ? widget.veri.vurguRenk.withValues(alpha: 0.04)
                : _T.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hover
                  ? widget.veri.vurguRenk.withValues(alpha: 0.3)
                  : _T.border,
            ),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: widget.veri.vurguRenk
                          .withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Dairesel solid ikon
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: widget.veri.ikonBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.veri.ikon,
                    size: 20, color: widget.veri.vurguRenk),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.veri.baslik,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _T.text1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.veri.aciklama,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: _T.text3),
                    ),
                  ],
                ),
              ),

              AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: _hover
                      ? widget.veri.vurguRenk.withValues(alpha: 0.1)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: _hover
                      ? widget.veri.vurguRenk
                      : _T.text3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORTAK KÜÇÜK BİLEŞENLER
// ─────────────────────────────────────────────────────────────────────────────

/// Gradyan dolgulu dairesel avatar
class _GradyanAvatar extends StatelessWidget {
  final String basHarf;
  final double boyut;
  const _GradyanAvatar({required this.basHarf, required this.boyut});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: boyut, height: boyut,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        basHarf,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: boyut * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Yenile ikon butonu
class _YenileButon extends StatefulWidget {
  final VoidCallback onTap;
  const _YenileButon({required this.onTap});

  @override
  State<_YenileButon> createState() => _YenileButonState();
}

class _YenileButonState extends State<_YenileButon> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Yenile',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        cursor:  SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _hover ? const Color(0xFFF0F4FF) : _T.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _hover
                      ? _T.blue.withValues(alpha: 0.3)
                      : _T.border),
            ),
            child: Icon(Icons.refresh_rounded,
                size: 17,
                color: _hover ? _T.blue : _T.text2),
          ),
        ),
      ),
    );
  }
}

/// Araç Ekle birincil butonu
class _AracEkleButon extends StatelessWidget {
  final VoidCallback onTap;
  const _AracEkleButon({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded,
                    size: 15, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'Araç Ekle',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
