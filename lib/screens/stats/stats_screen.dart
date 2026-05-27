import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';
import '../../services/expense_service.dart';
import '../../services/export_service.dart';
import '../../utils/error_handler.dart';
import '../../utils/format_utils.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _vehicleService = VehicleService();
  final _expenseService = ExpenseService();
  final _currencyFormat =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  final _dateFormat = DateFormat('dd/MM/yyyy');

  List<Vehicle> _soldVehicles = [];
  List<Vehicle> _allVehicles = [];
  Map<String, dynamic> _stats = {};
  Map<String, double> _vehicleExpenses = {};
  bool _isLoading = true;
  bool _isPdfExporting = false;
  int _selectedYear = DateTime.now().year;

  bool get _isMobile => MediaQuery.sizeOf(context).width < 700;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _stats = await _vehicleService.getStats();
      _soldVehicles =
          await _vehicleService.getVehiclesByStatus('satildi');
      _allVehicles = await _vehicleService.getVehicles();
      final ids = _soldVehicles
          .where((v) => v.id != null)
          .map((v) => v.id!)
          .toList();
      _vehicleExpenses =
          await _expenseService.getTotalExpensesByVehicles(ids);

      // Seçili yıl, mevcut yıllar arasında değilse en güncel yıla çek.
      // Aksi halde DropdownButton'ın value'su listede bulunmaz ve
      // "exactly one item" assertion hatasıyla ekran çöker.
      _selectedYear = gecerliYilSec(_getAvailableYears(), _selectedYear);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppError.from(e, ctx: 'İstatistikler yüklenemedi')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _exportPdf() async {
    setState(() => _isPdfExporting = true);
    try {
      await ExportService.exportStatsToPdf(
        stats: _stats,
        soldVehicles: _soldVehicles,
        vehicleExpenses: _vehicleExpenses,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppError.from(e, ctx: 'PDF raporu oluşturulamadı')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPdfExporting = false);
    }
  }

  List<_MonthData> _getMonthlyData() {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final month = DateTime(now.year, now.month - (5 - i));
      double profit = 0;
      int count = 0;
      for (final v in _soldVehicles) {
        if (v.satisTarihi == null) continue;
        if (v.satisTarihi!.year == month.year &&
            v.satisTarihi!.month == month.month) {
          final gider = _vehicleExpenses[v.id] ?? 0;
          profit += (v.kar ?? 0) - gider;
          count++;
        }
      }
      return _MonthData(
        label: DateFormat('MMM', 'tr_TR').format(month),
        profit: profit,
        count: count,
      );
    });
  }

  List<_AylikFaaliyet> _getMonthlyActivity(int year) {
    return List.generate(12, (i) {
      final month = i + 1;
      int alinan = 0;
      int satilan = 0;
      for (final v in _allVehicles) {
        if (v.alisTarihi != null &&
            v.alisTarihi!.year == year &&
            v.alisTarihi!.month == month) {
          alinan++;
        }
        if (v.satisTarihi != null &&
            v.satisTarihi!.year == year &&
            v.satisTarihi!.month == month) {
          satilan++;
        }
      }
      return _AylikFaaliyet(ay: month, alinan: alinan, satilan: satilan);
    });
  }

  List<int> _getAvailableYears() {
    final years = <int>{};
    for (final v in _allVehicles) {
      if (v.alisTarihi != null) years.add(v.alisTarihi!.year);
      if (v.satisTarihi != null) years.add(v.satisTarihi!.year);
    }
    if (years.isEmpty) years.add(DateTime.now().year);
    final sorted = years.toList()..sort();
    return sorted;
  }

  List<_BrandData> _getBrandData() {
    final counts = <String, int>{};
    for (final v in _soldVehicles) {
      counts[v.marka] = (counts[v.marka] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => _BrandData(e.key, e.value)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }

    final brutKar = (_stats['brutKar'] ?? 0.0) as double;
    final toplamGider = (_stats['toplamGider'] ?? 0.0) as double;
    final netKar = (_stats['toplamKar'] ?? 0.0) as double;

    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI Kartlar ──────────────────────────────────────────
          _isMobile
              ? _buildKpiCardsWrap(brutKar, toplamGider, netKar)
              : _buildKpiCardsRow(brutKar, toplamGider, netKar),
          const SizedBox(height: 20),

          // ── Stok yatırım bandı ───────────────────────────────────
          _buildInvestmentBanner(),
          const SizedBox(height: 24),

          // ── Grafikler ────────────────────────────────────────────
          if (_soldVehicles.isNotEmpty) ...[
            _isMobile
                ? Column(
                    children: [
                      _buildMonthlyChart(),
                      const SizedBox(height: 16),
                      _buildBrandChart(),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildMonthlyChart()),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _buildBrandChart()),
                    ],
                  ),
            const SizedBox(height: 28),
          ],

          // ── Aylık Faaliyet ────────────────────────────────────────
          _buildActivitySectionHeader(),
          const SizedBox(height: 14),
          _buildActivityTable(),
          const SizedBox(height: 28),

          // ── Satış geçmişi ────────────────────────────────────────
          _buildSalesHistoryHeader(),
          const SizedBox(height: 14),
          _soldVehicles.isEmpty
              ? _buildEmptySales()
              : _buildSalesTable(),
        ],
      ),
    );
  }

  // ── KPI satırı (masaüstü) ─────────────────────────────────────────
  Widget _buildKpiCardsRow(
      double brutKar, double toplamGider, double netKar) {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            title: 'Toplam Araç',
            value: '${_stats['toplamArac'] ?? 0}',
            icon: Icons.directions_car_rounded,
            gradient: AppTheme.blueGradient,
            subtitle: 'Kayıtlı araç',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildKpiCard(
            title: 'Stokta',
            value: '${_stats['stoktaAdet'] ?? 0}',
            icon: Icons.inventory_2_rounded,
            gradient: AppTheme.tealGradient,
            subtitle: 'Satışa hazır',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildKpiCard(
            title: 'Satılan',
            value: '${_stats['satilanAdet'] ?? 0}',
            icon: Icons.sell_rounded,
            gradient: AppTheme.greenGradient,
            subtitle: 'Tamamlanan satış',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildKpiCard(
            title: 'Brüt Kâr',
            value: _currencyFormat.format(brutKar),
            icon: Icons.trending_up_rounded,
            gradient: AppTheme.purpleGradient,
            subtitle: 'Giderler hariç',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildKpiCard(
            title: 'Toplam Gider',
            value: _currencyFormat.format(toplamGider),
            icon: Icons.money_off_rounded,
            gradient: AppTheme.amberGradient,
            subtitle: 'Tüm giderler',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildKpiCard(
            title: 'Net Kâr',
            value: _currencyFormat.format(netKar),
            icon: Icons.account_balance_rounded,
            gradient: netKar >= 0
                ? AppTheme.greenGradient
                : AppTheme.roseGradient,
            subtitle: 'Giderler düşülmüş',
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCardsWrap(
      double brutKar, double toplamGider, double netKar) {
    final cards = [
      _buildKpiCard(
        title: 'Toplam Araç',
        value: '${_stats['toplamArac'] ?? 0}',
        icon: Icons.directions_car_rounded,
        gradient: AppTheme.blueGradient,
        subtitle: 'Kayıtlı araç',
      ),
      _buildKpiCard(
        title: 'Stokta',
        value: '${_stats['stoktaAdet'] ?? 0}',
        icon: Icons.inventory_2_rounded,
        gradient: AppTheme.tealGradient,
        subtitle: 'Satışa hazır',
      ),
      _buildKpiCard(
        title: 'Satılan',
        value: '${_stats['satilanAdet'] ?? 0}',
        icon: Icons.sell_rounded,
        gradient: AppTheme.greenGradient,
        subtitle: 'Tamamlanan satış',
      ),
      _buildKpiCard(
        title: 'Brüt Kâr',
        value: _currencyFormat.format(brutKar),
        icon: Icons.trending_up_rounded,
        gradient: AppTheme.purpleGradient,
        subtitle: 'Giderler hariç',
      ),
      _buildKpiCard(
        title: 'Toplam Gider',
        value: _currencyFormat.format(toplamGider),
        icon: Icons.money_off_rounded,
        gradient: AppTheme.amberGradient,
        subtitle: 'Tüm giderler',
      ),
      _buildKpiCard(
        title: 'Net Kâr',
        value: _currencyFormat.format(netKar),
        icon: Icons.account_balance_rounded,
        gradient: netKar >= 0
            ? AppTheme.greenGradient
            : AppTheme.roseGradient,
        subtitle: 'Giderler düşülmüş',
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final itemWidth = (constraints.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: cards
            .map((c) => SizedBox(width: itemWidth, child: c))
            .toList(),
      );
    });
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required LinearGradient gradient,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const Spacer(),
              Icon(Icons.arrow_outward_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stok yatırım bandı ────────────────────────────────────────────
  Widget _buildInvestmentBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.iconBgPurple,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: AppTheme.iconPurple, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mevcut Stok Yatırımı',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currencyFormat.format(_stats['toplamYatirim'] ?? 0),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label: Text('Yenile',
                style: GoogleFonts.inter(fontSize: 12.5)),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  // ── Aylık kâr grafiği ────────────────────────────────────────────
  Widget _buildMonthlyChart() {
    final data = _getMonthlyData();
    final maxY = data
        .map((d) => d.profit.abs())
        .fold(0.0, (a, b) => a > b ? a : b);
    final yMax = maxY == 0 ? 100000.0 : maxY * 1.3;

    return _chartCard(
      title: 'Aylık Net Kâr (Son 6 Ay)',
      icon: Icons.bar_chart_rounded,
      child: SizedBox(
        height: 210,
        child: BarChart(
          BarChartData(
            maxY: yMax,
            minY: -yMax * 0.1,
            barGroups:
                data.asMap().entries.map((entry) {
              final d = entry.value;
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: d.profit,
                    gradient: d.profit >= 0
                        ? AppTheme.greenGradient
                        : AppTheme.roseGradient,
                    width: 30,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: yMax,
                      color: AppTheme.bgMuted,
                    ),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= data.length) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        data[idx].label,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppTheme.border,
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppTheme.textPrimary,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${data[group.x].label}\n',
                    GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                    children: [
                      TextSpan(
                        text: NumberFormat.currency(
                                locale: 'tr_TR', symbol: '₺')
                            .format(rod.toY),
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 11.5),
                      ),
                      if (data[group.x].count > 0)
                        TextSpan(
                          text: '\n${data[group.x].count} araç',
                          style: GoogleFonts.inter(
                              color: Colors.white60, fontSize: 10.5),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Marka grafiği ────────────────────────────────────────────────
  Widget _buildBrandChart() {
    final data = _getBrandData();
    if (data.isEmpty) return const SizedBox();

    final maxVal =
        data.map((d) => d.count).reduce((a, b) => a > b ? a : b);

    const colors = [
      AppTheme.primary,
      AppTheme.success,
      AppTheme.warning,
      AppTheme.iconPurple,
      AppTheme.iconTeal,
    ];

    return _chartCard(
      title: 'En Çok Satılan Markalar',
      icon: Icons.leaderboard_rounded,
      child: Column(
        children: data.asMap().entries.map((entry) {
          final d = entry.value;
          final color = colors[entry.key % colors.length];
          final ratio = d.count / maxVal;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  child: Text(
                    d.brand,
                    style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppTheme.bgMuted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: ratio,
                        child: Container(
                          height: 26,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: color.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${d.count}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _chartCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 15),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // ── Aylık faaliyet başlığı ────────────────────────────────────────
  Widget _buildActivitySectionHeader() {
    final years = _getAvailableYears();
    return Row(
      children: [
        Text(
          'Aylık Alım-Satım Faaliyeti',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedYear,
              isDense: true,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600),
              items: years
                  .map((y) => DropdownMenuItem(
                        value: y,
                        child: Text('$y'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedYear = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Aylık faaliyet tablosu ─────────────────────────────────────────
  Widget _buildActivityTable() {
    final aylar = _getMonthlyActivity(_selectedYear);
    final toplamAlinan = aylar.fold(0, (s, a) => s + a.alinan);
    final toplamSatilan = aylar.fold(0, (s, a) => s + a.satilan);
    final ayIsimleri = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: _isMobile ? Axis.horizontal : Axis.vertical,
          child: ConstrainedBox(
            constraints: _isMobile
                ? const BoxConstraints(minWidth: 560)
                : const BoxConstraints(),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(80),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              children: [
                // Başlık satırı
                TableRow(
                  decoration: const BoxDecoration(
                    color: AppTheme.bgMuted,
                    border: Border(
                        bottom: BorderSide(color: AppTheme.border)),
                  ),
                  children: [
                    _actCell(
                        Text('Ay',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                                letterSpacing: 0.4)),
                        isHeader: true),
                    _actCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_downward_rounded,
                                size: 13, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text('ALINAN',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textMuted,
                                    letterSpacing: 0.4)),
                          ],
                        ),
                        isHeader: true),
                    _actCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_upward_rounded,
                                size: 13, color: AppTheme.success),
                            const SizedBox(width: 4),
                            Text('SATILAN',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textMuted,
                                    letterSpacing: 0.4)),
                          ],
                        ),
                        isHeader: true),
                    _actCell(
                        Text('NET',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                                letterSpacing: 0.4)),
                        isHeader: true),
                  ],
                ),
                // Aylık veri satırları
                ...aylar.asMap().entries.map((entry) {
                  final i = entry.key;
                  final a = entry.value;
                  final net = a.satilan - a.alinan;
                  final isEven = i % 2 == 0;
                  final isCurrentMonth =
                      _selectedYear == DateTime.now().year &&
                          (i + 1) == DateTime.now().month;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: isCurrentMonth
                          ? AppTheme.primaryLight.withValues(alpha: 0.5)
                          : isEven
                              ? Colors.white
                              : AppTheme.bgMuted.withValues(alpha: 0.4),
                      border: const Border(
                          bottom: BorderSide(
                              color: AppTheme.border, width: 0.5)),
                    ),
                    children: [
                      _actCell(Row(
                        children: [
                          Text(
                            ayIsimleri[i],
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isCurrentMonth
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isCurrentMonth
                                    ? AppTheme.primary
                                    : AppTheme.textPrimary),
                          ),
                          if (isCurrentMonth) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Bu ay',
                                  style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      )),
                      _actCell(_countBadge(a.alinan, AppTheme.primary)),
                      _actCell(_countBadge(a.satilan, AppTheme.success)),
                      _actCell(net == 0
                          ? Text('-',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.textMuted))
                          : Text(
                              net > 0 ? '+$net' : '$net',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: net > 0
                                    ? AppTheme.success
                                    : AppTheme.error,
                              ),
                            )),
                    ],
                  );
                }),
                // Toplam satırı
                TableRow(
                  decoration: const BoxDecoration(
                    color: AppTheme.bgMuted,
                    border: Border(
                        top: BorderSide(color: AppTheme.border, width: 1.5)),
                  ),
                  children: [
                    _actCell(Text('TOPLAM',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary))),
                    _actCell(_countBadge(toplamAlinan, AppTheme.primary,
                        bold: true)),
                    _actCell(_countBadge(toplamSatilan, AppTheme.success,
                        bold: true)),
                    _actCell(() {
                      final net = toplamSatilan - toplamAlinan;
                      return Text(
                        net == 0 ? '-' : net > 0 ? '+$net' : '$net',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: net > 0
                              ? AppTheme.success
                              : net < 0
                                  ? AppTheme.error
                                  : AppTheme.textMuted,
                        ),
                      );
                    }()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actCell(Widget child, {bool isHeader = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 14, vertical: isHeader ? 12 : 11),
      child: child,
    );
  }

  Widget _countBadge(int count, Color color, {bool bold = false}) {
    if (count == 0) {
      return Text('-',
          style: GoogleFonts.inter(
              fontSize: 13, color: AppTheme.textMuted));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Text(
            '$count araç',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ── Satış geçmişi başlığı ─────────────────────────────────────────
  Widget _buildSalesHistoryHeader() {
    return Row(
      children: [
        Text(
          'Satış Geçmişi',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.bgMuted,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.border),
          ),
          child: Text(
            '${_soldVehicles.length} kayıt',
            style:
                GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textMuted),
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _soldVehicles.isEmpty || _isPdfExporting
              ? null
              : _exportPdf,
          icon: _isPdfExporting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.error))
              : const Icon(Icons.picture_as_pdf_rounded, size: 16),
          label: Text(
              _isPdfExporting ? 'Oluşturuluyor...' : 'PDF İndir',
              style: GoogleFonts.inter(fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.error,
            side: const BorderSide(color: Color(0xFFFECACA)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  // ── Boş satış ─────────────────────────────────────────────────────
  Widget _buildEmptySales() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.bgMuted,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.sell_outlined,
                  size: 28, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz satış yapılmamış',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Araç detay ekranından satış kaydedebilirsiniz',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ── Satış tablosu ─────────────────────────────────────────────────
  Widget _buildSalesTable() {
    return SingleChildScrollView(
      scrollDirection: _isMobile ? Axis.horizontal : Axis.vertical,
      child: Container(
        constraints:
            _isMobile ? const BoxConstraints(minWidth: 620) : null,
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.4),
              1: FixedColumnWidth(100),
              2: FixedColumnWidth(110),
              3: FlexColumnWidth(1.2),
              4: FlexColumnWidth(1.2),
              5: FlexColumnWidth(1.2),
              6: FlexColumnWidth(1.2),
            },
            children: [
              _buildTableHeader([
                'Araç',
                'Plaka',
                'Satış Tarihi',
                'Alış Fiyatı',
                'Satış Fiyatı',
                'Giderler',
                'Net Kâr',
              ]),
              ..._soldVehicles.asMap().entries.map((entry) {
                final v = entry.value;
                final gider = _vehicleExpenses[v.id] ?? 0;
                final netKarRow = (v.kar ?? 0) - gider;
                final isEven = entry.key % 2 == 0;
                return TableRow(
                  decoration: BoxDecoration(
                    color: isEven
                        ? Colors.white
                        : AppTheme.bgMuted.withValues(alpha: 0.5),
                    border: const Border(
                        bottom: BorderSide(
                            color: AppTheme.border, width: 0.5)),
                  ),
                  children: [
                    _tableCell(Text(
                      '${v.marka} ${v.model}',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary),
                    )),
                    _tableCell(Text(
                      v.plaka,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    )),
                    _tableCell(Text(
                      v.satisTarihi != null
                          ? _dateFormat.format(v.satisTarihi!)
                          : '-',
                      style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary),
                    )),
                    _tableCell(Text(
                      _currencyFormat.format(v.alisFiyati),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppTheme.textPrimary),
                    )),
                    _tableCell(Text(
                      _currencyFormat.format(v.satisFiyati ?? 0),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppTheme.textPrimary),
                    )),
                    _tableCell(Text(
                      _currencyFormat.format(gider),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    )),
                    _tableCell(Text(
                      _currencyFormat.format(netKarRow),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: netKarRow >= 0
                            ? AppTheme.success
                            : AppTheme.error,
                      ),
                    )),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildTableHeader(List<String> headers) {
    return TableRow(
      decoration: const BoxDecoration(
        color: AppTheme.bgMuted,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      children: headers
          .map((h) => Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Text(
                  h,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.4,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _tableCell(Widget child) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: child,
    );
  }
}

class _MonthData {
  final String label;
  final double profit;
  final int count;
  const _MonthData(
      {required this.label, required this.profit, required this.count});
}

class _BrandData {
  final String brand;
  final int count;
  const _BrandData(this.brand, this.count);
}

class _AylikFaaliyet {
  final int ay;
  final int alinan;
  final int satilan;
  const _AylikFaaliyet(
      {required this.ay, required this.alinan, required this.satilan});
}
