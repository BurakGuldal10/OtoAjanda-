import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _vehicleService = VehicleService();
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  final _dateFormat = DateFormat('dd/MM/yyyy');
  List<Vehicle> _soldVehicles = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _stats = await _vehicleService.getStats();
      _soldVehicles = await _vehicleService.getVehiclesByStatus('satildi');
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Özet kartları - yatay
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Toplam Araç',
                  '${_stats['toplamArac'] ?? 0}',
                  Icons.directions_car,
                  Colors.indigo,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Stokta',
                  '${_stats['stoktaAdet'] ?? 0}',
                  Icons.inventory,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Satılan',
                  '${_stats['satilanAdet'] ?? 0}',
                  Icons.sell,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Toplam Kar',
                  _currencyFormat.format(_stats['toplamKar'] ?? 0),
                  Icons.trending_up,
                  (_stats['toplamKar'] ?? 0) >= 0 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Stok Yatırımı',
                  _currencyFormat.format(_stats['toplamYatirim'] ?? 0),
                  Icons.account_balance_wallet,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Son satışlar tablosu
          Text(
            'Satış Geçmişi',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (_soldVehicles.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Henüz satış yapılmamış')),
              ),
            )
          else
            Card(
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Araç')),
                    DataColumn(label: Text('Plaka')),
                    DataColumn(label: Text('Satış Tarihi')),
                    DataColumn(label: Text('Alış Fiyatı'), numeric: true),
                    DataColumn(label: Text('Satış Fiyatı'), numeric: true),
                    DataColumn(label: Text('Kar'), numeric: true),
                  ],
                  rows: _soldVehicles.map((v) {
                    return DataRow(cells: [
                      DataCell(Text('${v.marka} ${v.model}')),
                      DataCell(Text(v.plaka)),
                      DataCell(Text(v.satisTarihi != null
                          ? _dateFormat.format(v.satisTarihi!)
                          : '-')),
                      DataCell(Text(_currencyFormat.format(v.alisFiyati))),
                      DataCell(Text(
                          _currencyFormat.format(v.satisFiyati ?? 0))),
                      DataCell(
                        Text(
                          _currencyFormat.format(v.kar ?? 0),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (v.kar ?? 0) >= 0
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
