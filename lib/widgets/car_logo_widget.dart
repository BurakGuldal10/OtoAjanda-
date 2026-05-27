import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';

/// Araç marka logosunu görüntüler.
///
/// [size]  → toplam widget boyutu; [boxed] true ise kutu dahil.
/// [boxed] → true (varsayılan): beyaz yuvarlak kutu içinde gösterir.
///            false: ham logo — form alanı leading gibi dar alanlarda kullan.
///
/// Yükleme sırası:
///   1. SVG  — original klasör (vektör, net görünüm)
///   2. PNG  — optimized klasör (yüksek kalite raster)
///   3. Fallback — gradyan daire + marka baş harfi
class CarLogoWidget extends StatefulWidget {
  final String marka;
  final double size;
  final bool   boxed;

  const CarLogoWidget({
    super.key,
    required this.marka,
    this.size  = 36,
    this.boxed = true,
  });

  static String _toSlug(String marka) =>
      marka.trim().toLowerCase().replaceAll(' ', '-');

  static String svgUrl(String marka) =>
      'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/original/${_toSlug(marka)}.svg';

  static String pngUrl(String marka) =>
      'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized/${_toSlug(marka)}.png';

  /// Oturum boyunca SVG varlığını önbellekler.
  static final Map<String, bool> _svgCache = {};

  @override
  State<CarLogoWidget> createState() => _CarLogoWidgetState();
}

class _CarLogoWidgetState extends State<CarLogoWidget> {
  late Future<bool> _svgAvailable;

  @override
  void initState() {
    super.initState();
    _svgAvailable = _checkSvg();
  }

  @override
  void didUpdateWidget(CarLogoWidget old) {
    super.didUpdateWidget(old);
    if (old.marka != widget.marka) {
      setState(() => _svgAvailable = _checkSvg());
    }
  }

  Future<bool> _checkSvg() async {
    final url = CarLogoWidget.svgUrl(widget.marka);
    if (CarLogoWidget._svgCache.containsKey(url)) {
      return CarLogoWidget._svgCache[url]!;
    }
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);
      final req = await client.headUrl(Uri.parse(url));
      final res = await req.close();
      await res.drain<void>();
      client.close();
      final available = res.statusCode == 200;
      CarLogoWidget._svgCache[url] = available;
      return available;
    } catch (_) {
      CarLogoWidget._svgCache[url] = false;
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial  = widget.marka.isNotEmpty ? widget.marka[0].toUpperCase() : '?';
    final bgColor  = _brandColor(widget.marka);
    // Kutulu ise logo iç alana sığdırılır; kutuzsuz ise boyutun tamamını kullan
    final logoSize = widget.boxed ? widget.size * 0.60 : widget.size;

    final logo = FutureBuilder<bool>(
      future: _svgAvailable,
      builder: (context, snapshot) {
        // SVG mevcut — vektör, sonsuz netlik
        if (snapshot.data == true) {
          return SvgPicture.network(
            CarLogoWidget.svgUrl(widget.marka),
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
            placeholderBuilder: (_) =>
                _buildFallback(logoSize, initial, bgColor),
          );
        }

        // SVG yok → PNG dene
        if (snapshot.data == false) {
          return CachedNetworkImage(
            imageUrl: CarLogoWidget.pngUrl(widget.marka),
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
            placeholder:  (_, _) => _buildFallback(logoSize, initial, bgColor),
            errorWidget:  (_, _, _) => _buildFallback(logoSize, initial, bgColor),
          );
        }

        // Kontrol devam ediyor — fallback göster
        return _buildFallback(logoSize, initial, bgColor);
      },
    );

    if (!widget.boxed) return logo;

    // ── Kutulu versiyon ──────────────────────────────────────────────
    // Beyaz arka plan + yuvarlak köşe + ince kenarlık + hafif gölge
    return Container(
      width:  widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.size * 0.22),
        border: Border.all(color: const Color(0xFFE2E8F0)), // slate-200
        boxShadow: const [
          BoxShadow(
            color:      Color(0x0C000000), // %5 siyah
            blurRadius: 6,
            offset:     Offset(0, 2),
          ),
          BoxShadow(
            color:      Color(0x06000000), // %2 siyah
            blurRadius: 14,
            offset:     Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: logo,
    );
  }

  /// Gradyan daire + marka baş harfi fallback
  Widget _buildFallback(double size, String initial, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.lerp(color, Colors.black, 0.30)!,
          ],
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.inter(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }

  /// Markaya özel renk — hash'e göre sabit renk seçilir
  static Color _brandColor(String marka) {
    const colors = [
      AppTheme.primary,
      Color(0xFF7C3AED), // violet
      Color(0xFF059669), // emerald
      Color(0xFFD97706), // amber
      Color(0xFFDC2626), // red
      Color(0xFF0891B2), // cyan
      Color(0xFF9D174D), // pink
      Color(0xFF065F46), // dark green
    ];
    final index = marka.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }
}
