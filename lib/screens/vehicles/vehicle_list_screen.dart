import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';
import 'vehicle_detail_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final _vehicleService = VehicleService();
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  final _dateFormat = DateFormat('dd/MM/yyyy');
  List<Vehicle> _allVehicles = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, stokta, satildi
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadVehicles();
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
    }
  }

  List<Vehicle> get _filteredVehicles {
    var list = _allVehicles;

    // Durum filtresi
    if (_filter == 'stokta') {
      list = list.where((v) => v.durum == 'stokta').toList();
    } else if (_filter == 'satildi') {
      list = list.where((v) => v.durum == 'satildi').toList();
    }

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((v) {
        return v.plaka.toLowerCase().contains(query) ||
            v.marka.toLowerCase().contains(query) ||
            v.model.toLowerCase().contains(query);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final vehicles = _filteredVehicles;

    return Column(
      children: [
        // Filtre ve arama çubuğu
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              // Arama
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Plaka, marka veya model ara...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Filtre butonları
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('Tümü')),
                  ButtonSegment(value: 'stokta', label: Text('Stokta')),
                  ButtonSegment(value: 'satildi', label: Text('Satıldı')),
                ],
                selected: {_filter},
                onSelectionChanged: (selected) {
                  setState(() => _filter = selected.first);
                },
              ),
              const Spacer(),
              // Toplam sayı
              Chip(
                label: Text('${vehicles.length} araç'),
                avatar: const Icon(Icons.directions_car, size: 18),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Yenile',
                onPressed: _loadVehicles,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Tablo
        Expanded(
          child: vehicles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Aramanızla eşleşen araç bulunamadı'
                            : 'Henüz araç eklenmemiş',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.3),
                      ),
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text('Plaka')),
                        DataColumn(label: Text('Marka')),
                        DataColumn(label: Text('Model')),
                        DataColumn(label: Text('Yıl')),
                        DataColumn(label: Text('Alış Tarihi')),
                        DataColumn(
                            label: Text('Alış Fiyatı'), numeric: true),
                        DataColumn(
                            label: Text('Satış Fiyatı'), numeric: true),
                        DataColumn(label: Text('Kar'), numeric: true),
                        DataColumn(label: Text('Durum')),
                        DataColumn(label: Text('')),
                      ],
                      rows: vehicles.map((vehicle) {
                        final isSold = vehicle.durum == 'satildi';
                        return DataRow(
                          cells: [
                            DataCell(Text(
                              vehicle.plaka,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            )),
                            DataCell(Text(vehicle.marka)),
                            DataCell(Text(vehicle.model)),
                            DataCell(Text(vehicle.yil?.toString() ?? '-')),
                            DataCell(Text(vehicle.alisTarihi != null
                                ? _dateFormat.format(vehicle.alisTarihi!)
                                : '-')),
                            DataCell(Text(
                                _currencyFormat.format(vehicle.alisFiyati))),
                            DataCell(Text(vehicle.satisFiyati != null
                                ? _currencyFormat.format(vehicle.satisFiyati)
                                : '-')),
                            DataCell(
                              vehicle.kar != null
                                  ? Text(
                                      _currencyFormat.format(vehicle.kar),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: vehicle.kar! >= 0
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                      ),
                                    )
                                  : const Text('-'),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSold
                                      ? Colors.green[50]
                                      : Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isSold ? 'Satıldı' : 'Stokta',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSold
                                        ? Colors.green[800]
                                        : Colors.blue[800],
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios,
                                    size: 16),
                                tooltip: 'Detay',
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VehicleDetailScreen(
                                          vehicle: vehicle),
                                    ),
                                  );
                                  if (result == true) _loadVehicles();
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
