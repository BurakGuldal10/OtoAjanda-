import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';
import '../../services/export_service.dart';
import '../../widgets/car_logo_widget.dart';
import '../../utils/error_handler.dart';
import 'vehicle_detail_screen.dart';

class VehicleListScreen extends StatefulWidget {
  final VoidCallback? onRefresh;
  const VehicleListScreen({super.key, this.onRefresh});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final _vehicleService = VehicleService();
  final _currencyFormat =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  final _dateFormat = DateFormat('dd/MM/yyyy');

  List<Vehicle> _allVehicles = [];
  bool _isLoading = true;
  bool _isExporting = false;
  String _filter = 'all';
  String _searchQuery = '';
  int? _hoveredIndex; // Tablo satır hover için

  bool get _isMobile => MediaQuery.sizeOf(context).width < 700;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      final path =
          await ExportService.exportVehiclesToExcel(_filteredVehicles);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel kaydedildi: $path'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppError.from(e, ctx: 'Excel dosyası oluşturulamadı')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      final vehicles = await _vehicleService.getVehicles();
      setState(() {
        _allVehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppError.from(e, ctx: 'Araç listesi yüklenemedi')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  List<Vehicle> get _filteredVehicles {
    var list = _allVehicles;
    if (_filter == 'stokta') {
      list = list.where((v) => v.durum == 'stokta').toList();
    } else if (_filter == 'satildi') {
      list = list.where((v) => v.durum == 'satildi').toList();
    } else if (_filter == 'rezerve') {
      list = list.where((v) => v.durum == 'rezerve').toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((v) =>
              v.plaka.toLowerCase().contains(q) ||
              v.marka.toLowerCase().contains(q) ||
              v.model.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }

    final vehicles = _filteredVehicles;

    return Column(
      children: [
        _isMobile
            ? _buildMobileToolbar(vehicles)
            : _buildDesktopToolbar(vehicles),
        Container(height: 1, color: AppTheme.border),
        Expanded(
          child: vehicles.isEmpty
              ? _buildEmptyState()
              : _isMobile
                  ? _buildMobileList(vehicles)
                  : _buildDesktopTable(vehicles),
        ),
      ],
    );
  }

  // ── Mobil araç çubuğu ────────────────────────────────────────────
  Widget _buildMobileToolbar(List<Vehicle> vehicles) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      color: AppTheme.bgCard,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSearchField(),
              ),
              const SizedBox(width: 8),
              _buildIconButton(
                icon: Icons.refresh_rounded,
                onTap: () {
                  _loadVehicles();
                  widget.onRefresh?.call();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildFilterChip('all', 'Tümü'),
              const SizedBox(width: 6),
              _buildFilterChip('stokta', 'Stokta'),
              const SizedBox(width: 6),
              _buildFilterChip('satildi', 'Satıldı'),
              const SizedBox(width: 6),
              _buildFilterChip('rezerve', 'Rezerve'),
              const Spacer(),
              Text(
                '${vehicles.length} araç',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Masaüstü araç çubuğu ─────────────────────────────────────────
  Widget _buildDesktopToolbar(List<Vehicle> vehicles) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      color: AppTheme.bgCard,
      child: Row(
        children: [
          SizedBox(width: 300, child: _buildSearchField()),
          const SizedBox(width: 14),
          _buildFilterChip('all', 'Tümü'),
          const SizedBox(width: 6),
          _buildFilterChip('stokta', 'Stokta'),
          const SizedBox(width: 6),
          _buildFilterChip('satildi', 'Satıldı'),
          const SizedBox(width: 6),
          _buildFilterChip('rezerve', 'Rezerve'),
          const Spacer(),

          // Araç sayacı
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.bgMuted,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_car_outlined,
                    size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  '${vehicles.length} araç',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Excel export
          OutlinedButton.icon(
            onPressed:
                _allVehicles.isEmpty || _isExporting ? null : _exportToExcel,
            icon: _isExporting
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.success))
                : const Icon(Icons.table_chart_outlined, size: 15),
            label: Text(
              _isExporting ? 'Kaydediliyor...' : 'Excel',
              style: GoogleFonts.inter(fontSize: 12.5),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.success,
              side: const BorderSide(color: Color(0xFFBBF7D0)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 6),

          // Yenile
          _buildIconButton(
            icon: Icons.refresh_rounded,
            onTap: () {
              _loadVehicles();
              widget.onRefresh?.call();
            },
          ),
        ],
      ),
    );
  }

  // ── Mobil kart listesi ───────────────────────────────────────────
  Widget _buildMobileList(List<Vehicle> vehicles) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: vehicles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildVehicleCard(vehicles[i]),
    );
  }

  Widget _buildVehicleCard(Vehicle v) {
    return Material(
      color: AppTheme.bgCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => VehicleDetailScreen(vehicle: v)),
          );
          if (result == true) {
            _loadVehicles();
            widget.onRefresh?.call();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CarLogoWidget(marka: v.marka, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${v.marka} ${v.model}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          v.plaka,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(v.durum),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  _cardDetail(Icons.calendar_today_outlined,
                      v.yil?.toString() ?? '-'),
                  if (v.kilometre != null) ...[
                    const SizedBox(width: 14),
                    _cardDetail(
                      Icons.speed_outlined,
                      '${NumberFormat('#,##0', 'tr_TR').format(v.kilometre)} km',
                    ),
                  ],
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currencyFormat.format(v.alisFiyati),
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary),
                      ),
                      if (v.kar != null)
                        Text(
                          _currencyFormat.format(v.kar),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: v.kar! >= 0
                                ? AppTheme.success
                                : AppTheme.error,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(text,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  // ── Masaüstü tablo ───────────────────────────────────────────────
  Widget _buildDesktopTable(List<Vehicle> vehicles) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Tablo başlığı
              _buildTableHeaderRow(),
              Container(height: 1, color: AppTheme.border),
              // Tablo satırları
              ...vehicles.asMap().entries.map(
                    (entry) => _buildTableDataRow(
                        entry.value, entry.key, vehicles.length),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeaderRow() {
    const headers = [
      ('Plaka', 110.0, false),
      ('Marka', 0.0, true),
      ('Model', 0.0, true),
      ('Yıl', 60.0, false),
      ('Alış Tarihi', 108.0, false),
      ('Alış Fiyatı', 0.0, true),
      ('Satış Fiyatı', 0.0, true),
      ('Kâr', 0.0, true),
      ('Durum', 100.0, false),
      ('', 48.0, false),
    ];

    return Container(
      color: AppTheme.bgMuted,
      child: Row(
        children: headers.map((h) {
          final (label, width, flex) = h;
          Widget cell = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
                letterSpacing: 0.4,
              ),
            ),
          );
          return flex
              ? Expanded(child: cell)
              : SizedBox(width: width, child: cell);
        }).toList(),
      ),
    );
  }

  Widget _buildTableDataRow(Vehicle v, int index, int total) {
    final isHovered = _hoveredIndex == index;
    final isLast = index == total - 1;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => VehicleDetailScreen(vehicle: v)),
          );
          if (result == true) {
            _loadVehicles();
            widget.onRefresh?.call();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: isHovered
                ? AppTheme.bgPage
                : (index % 2 == 0
                    ? Colors.white
                    : AppTheme.bgMuted.withValues(alpha: 0.5)),
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: AppTheme.border, width: 0.5)),
          ),
          child: Row(
            children: [
              // Plaka
              SizedBox(
                width: 110,
                child: _cell(Text(
                  v.plaka,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                )),
              ),

              // Marka
              Expanded(
                child: _cell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CarLogoWidget(marka: v.marka, size: 24),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        v.marka,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                )),
              ),

              // Model
              Expanded(
                child: _cell(Text(
                  v.model,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppTheme.textPrimary),
                )),
              ),

              // Yıl
              SizedBox(
                width: 60,
                child: _cell(Text(
                  v.yil?.toString() ?? '-',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppTheme.textSecondary),
                )),
              ),

              // Alış tarihi
              SizedBox(
                width: 108,
                child: _cell(Text(
                  v.alisTarihi != null
                      ? _dateFormat.format(v.alisTarihi!)
                      : '-',
                  style: GoogleFonts.inter(
                      fontSize: 12.5, color: AppTheme.textSecondary),
                )),
              ),

              // Alış fiyatı
              Expanded(
                child: _cell(
                  Text(
                    _currencyFormat.format(v.alisFiyati),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppTheme.textPrimary),
                  ),
                ),
              ),

              // Satış fiyatı
              Expanded(
                child: _cell(
                  Text(
                    v.satisFiyati != null
                        ? _currencyFormat.format(v.satisFiyati)
                        : '-',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ),
              ),

              // Kâr
              Expanded(
                child: _cell(
                  v.kar != null
                      ? Text(
                          _currencyFormat.format(v.kar),
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: v.kar! >= 0
                                ? AppTheme.success
                                : AppTheme.error,
                          ),
                        )
                      : Text('-',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textMuted)),
                ),
              ),

              // Durum
              SizedBox(
                width: 100,
                child: _cell(_buildStatusBadge(v.durum)),
              ),

              // Ok ikonu
              SizedBox(
                width: 48,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: isHovered ? 1.0 : 0.4,
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: isHovered
                          ? AppTheme.primary
                          : AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: child,
    );
  }

  // ── Filtre chip ───────────────────────────────────────────────────
  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.bgMuted,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
              color: isSelected
                  ? AppTheme.primary
                  : AppTheme.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── Arama alanı ──────────────────────────────────────────────────
  Widget _buildSearchField() {
    return SizedBox(
      height: 38,
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: GoogleFonts.inter(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Plaka, marka veya model ara...',
          hintStyle:
              GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: AppTheme.textMuted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: true,
          fillColor: AppTheme.bgMuted,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── İkon butonu ──────────────────────────────────────────────────
  Widget _buildIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: AppTheme.bgMuted,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppTheme.border),
          ),
          child: Icon(icon, size: 17, color: AppTheme.textMuted),
        ),
      ),
    );
  }

  // ── Durum badge ──────────────────────────────────────────────────
  Widget _buildStatusBadge(String durum) {
    Color bg, textColor, dotColor;
    String label;
    switch (durum) {
      case 'satildi':
        bg        = AppTheme.successBg;
        textColor = AppTheme.successText;
        dotColor  = AppTheme.success;
        label     = 'Satıldı';
        break;
      case 'rezerve':
        bg        = AppTheme.warningBg;
        textColor = AppTheme.warning;
        dotColor  = AppTheme.warning;
        label     = 'Rezerve';
        break;
      default:
        bg        = AppTheme.primaryLight;
        textColor = AppTheme.primaryDark;
        dotColor  = AppTheme.primary;
        label     = 'Stokta';
    }
    // Pill şekil — rektangüler değil, tam yuvarlak
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Boş durum ────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.bgMuted,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border, width: 2),
            ),
            child: const Icon(Icons.directions_car_outlined,
                size: 38, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isNotEmpty
                ? 'Aramanızla eşleşen araç bulunamadı'
                : 'Henüz araç eklenmemiş',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Farklı bir arama terimi deneyin'
                : '"Araç Ekle" butonuyla ilk aracınızı kaydedin',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
