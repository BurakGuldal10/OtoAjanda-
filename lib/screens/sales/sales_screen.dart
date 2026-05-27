import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';
import '../../services/expense_service.dart';
import '../../utils/error_handler.dart';
import '../../widgets/car_logo_widget.dart';
import '../vehicles/vehicle_detail_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _vehicleService = VehicleService();
  final _expenseService = ExpenseService();
  final _currencyFormat =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  final _dateFormat = DateFormat('dd/MM/yyyy');

  List<Vehicle> _sales = [];
  Map<String, double> _expenses = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final vehicles = await _vehicleService.getVehiclesByStatus('satildi');
      Map<String, double> expenses = {};
      if (vehicles.isNotEmpty) {
        final ids = vehicles.map((v) => v.id!).toList();
        expenses = await _expenseService.getTotalExpensesByVehicles(ids);
      }
      setState(() {
        _sales = vehicles;
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppError.from(e, ctx: 'Satışlar yüklenemedi')),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  List<Vehicle> get _filtered {
    if (_searchQuery.isEmpty) return _sales;
    final q = _searchQuery.toLowerCase();
    return _sales
        .where((v) =>
            v.plaka.toLowerCase().contains(q) ||
            v.marka.toLowerCase().contains(q) ||
            v.model.toLowerCase().contains(q))
        .toList();
  }

  // Özet istatistikler
  double get _toplamCiro =>
      _sales.fold(0, (s, v) => s + (v.satisFiyati ?? 0));
  double get _toplamBrutKar =>
      _sales.fold(0, (s, v) => s + (v.kar ?? 0));
  double get _toplamGider =>
      _expenses.values.fold(0, (s, g) => s + g);
  double get _toplamNetKar => _toplamBrutKar - _toplamGider;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return Column(
      children: [
        // ── Toolbar ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
          color: AppTheme.bgCard,
          child: Row(
            children: [
              SizedBox(
                width: 280,
                height: 38,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Plaka, marka veya model ara...',
                    hintStyle: GoogleFonts.inter(
                        color: AppTheme.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 18, color: AppTheme.textMuted),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
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
                      borderSide: const BorderSide(
                          color: AppTheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.bgMuted,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sell_rounded,
                        size: 15, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      '${_filtered.length} satış',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    size: 18, color: AppTheme.textMuted),
                tooltip: 'Yenile',
                onPressed: _load,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.bgMuted,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                      side: const BorderSide(color: AppTheme.border)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: _sales.isEmpty
              ? _buildEmpty()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Özet kartlar ───────────────────────────
                      _buildSummaryRow(),
                      const SizedBox(height: 20),

                      // ── Tablo ──────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Table(
                            columnWidths: const {
                              0: FixedColumnWidth(115),
                              1: FlexColumnWidth(1.4),
                              2: FlexColumnWidth(1.2),
                              3: FixedColumnWidth(110),
                              4: FlexColumnWidth(1.5),
                              5: FlexColumnWidth(1.5),
                              6: FlexColumnWidth(1.3),
                              7: FlexColumnWidth(1.4),
                              8: FixedColumnWidth(50),
                            },
                            children: [
                              _buildHeader(),
                              if (_filtered.isEmpty)
                                _buildNoResult()
                              else
                                ..._filtered.asMap().entries.map(
                                    (e) => _buildRow(e.value, e.key)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // Net Kâr kartında kullanılan sabit teal rengi
  static const Color _kartRengi = Color(0xFF0D9488); // teal-600
  static const Color _kartRengiZarar = Color(0xFFDC2626); // red-600

  Widget _buildSummaryRow() {
    return Row(
      children: [
        _buildSummaryCard(
          'Toplam Satış',
          '${_sales.length}',
          Icons.sell_rounded,
          _kartRengi,
        ),
        const SizedBox(width: 14),
        _buildSummaryCard(
          'Toplam Ciro',
          _currencyFormat.format(_toplamCiro),
          Icons.payments_rounded,
          _kartRengi,
        ),
        const SizedBox(width: 14),
        _buildSummaryCard(
          'Toplam Gider',
          _currencyFormat.format(_toplamGider),
          Icons.receipt_long_rounded,
          _kartRengi,
        ),
        const SizedBox(width: 14),
        _buildSummaryCard(
          'Net Kâr',
          _currencyFormat.format(_toplamNetKar),
          _toplamNetKar >= 0
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          _toplamNetKar >= 0 ? _kartRengi : _kartRengiZarar,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color renk) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: renk,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: renk.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
            const SizedBox(height: 10),
            Text(title,
                style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildHeader() {
    const headers = [
      'Plaka', 'Marka', 'Model', 'Satış Tarihi',
      'Alış', 'Satış', 'Gider', 'Net Kâr', ''
    ];
    return TableRow(
      decoration: const BoxDecoration(
        color: AppTheme.bgMuted,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      children: headers.map((h) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        child: Text(h,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
                letterSpacing: 0.3)),
      )).toList(),
    );
  }

  TableRow _buildNoResult() {
    return TableRow(children: List.generate(
      9,
      (i) => i == 0
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Arama ile eşleşen kayıt yok.',
                  style: GoogleFonts.inter(
                      color: AppTheme.textMuted, fontSize: 13)),
            )
          : const SizedBox(),
    ));
  }

  TableRow _buildRow(Vehicle v, int index) {
    final gider = _expenses[v.id] ?? 0;
    final netKar = (v.kar ?? 0) - gider;
    final isEven = index % 2 == 0;

    return TableRow(
      decoration: BoxDecoration(
        color: isEven ? Colors.white : AppTheme.bgMuted.withValues(alpha: 0.4),
        border: const Border(
            bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      children: [
        // Plaka
        _cell(Text(v.plaka,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary))),
        // Marka
        _cell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: CarLogoWidget(marka: v.marka, size: 28),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(v.marka,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppTheme.textPrimary)),
            ),
          ],
        )),
        // Model
        _cell(Text(v.model,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.textPrimary))),
        // Satış tarihi
        _cell(Text(
            v.satisTarihi != null
                ? _dateFormat.format(v.satisTarihi!)
                : '-',
            style: GoogleFonts.inter(
                fontSize: 12.5, color: AppTheme.textSecondary))),
        // Alış fiyatı
        _cell(
            Text(_currencyFormat.format(v.alisFiyati),
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppTheme.textSecondary)),
            right: true),
        // Satış fiyatı
        _cell(
            Text(_currencyFormat.format(v.satisFiyati ?? 0),
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppTheme.textPrimary)),
            right: true),
        // Gider
        _cell(
            Text(_currencyFormat.format(gider),
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppTheme.warning)),
            right: true),
        // Net kâr
        _cell(
          Text(
            _currencyFormat.format(netKar),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: netKar >= 0 ? AppTheme.success : AppTheme.error,
            ),
          ),
          right: true,
        ),
        // Detay
        TableRowInkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => VehicleDetailScreen(vehicle: v)),
            );
            if (result == true) _load();
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Center(
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: AppTheme.textMuted),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cell(Widget child, {bool right = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: right && child is Text
          ? DefaultTextStyle.merge(
              textAlign: TextAlign.right,
              style: const TextStyle(inherit: true),
              child: child,
            )
          : child,
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.successBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sell_outlined,
                size: 52, color: AppTheme.success),
          ),
          const SizedBox(height: 20),
          Text('Henüz satış yapılmamış',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text('Araç detay ekranından satış işlemi yapabilirsiniz.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
