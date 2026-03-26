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

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Genel Bakış',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Özet kartları
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatRow('Toplam Araç', '${_stats['toplamArac'] ?? 0}'),
                  _buildStatRow(
                      'Stoktaki Araçlar', '${_stats['stoktaAdet'] ?? 0}'),
                  _buildStatRow(
                      'Satılan Araçlar', '${_stats['satilanAdet'] ?? 0}'),
                  const Divider(),
                  _buildStatRow(
                    'Toplam Kar',
                    _currencyFormat.format(_stats['toplamKar'] ?? 0),
                    valueColor: (_stats['toplamKar'] ?? 0) >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                  _buildStatRow(
                    'Stok Yatırımı',
                    _currencyFormat.format(_stats['toplamYatirim'] ?? 0),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Son satışlar
          Text(
            'Son Satışlar',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          if (_soldVehicles.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Henüz satış yapılmamış')),
              ),
            )
          else
            ..._soldVehicles.map((v) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFC8E6C9),
                      child: Icon(Icons.sell, color: Colors.green),
                    ),
                    title: Text('${v.marka} ${v.model}'),
                    subtitle: Text(v.plaka),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currencyFormat.format(v.satisFiyati ?? 0),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (v.kar != null)
                          Text(
                            'Kar: ${_currencyFormat.format(v.kar)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: v.kar! >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
