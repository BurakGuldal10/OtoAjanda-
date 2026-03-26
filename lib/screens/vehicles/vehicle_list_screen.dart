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

class _VehicleListScreenState extends State<VehicleListScreen>
    with SingleTickerProviderStateMixin {
  final _vehicleService = VehicleService();
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  late TabController _tabController;
  List<Vehicle> _allVehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVehicles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  List<Vehicle> _filterByStatus(String? durum) {
    if (durum == null) return _allVehicles;
    return _allVehicles.where((v) => v.durum == durum).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'Stokta'),
            Tab(text: 'Satıldı'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildVehicleList(null),
              _buildVehicleList('stokta'),
              _buildVehicleList('satildi'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleList(String? durum) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final vehicles = _filterByStatus(durum);

    if (vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Henüz araç eklenmemiş',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVehicles,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = vehicles[index];
          return _buildVehicleCard(vehicle);
        },
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    final isSold = vehicle.durum == 'satildi';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSold ? Colors.green[100] : Colors.blue[100],
          child: Icon(
            isSold ? Icons.sell : Icons.directions_car,
            color: isSold ? Colors.green : Colors.blue,
          ),
        ),
        title: Text(
          '${vehicle.marka} ${vehicle.model}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vehicle.plaka),
            Text(
              'Alış: ${_currencyFormat.format(vehicle.alisFiyati)}',
              style: const TextStyle(fontSize: 12),
            ),
            if (isSold && vehicle.kar != null)
              Text(
                'Kar: ${_currencyFormat.format(vehicle.kar)}',
                style: TextStyle(
                  fontSize: 12,
                  color: vehicle.kar! >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Chip(
          label: Text(
            isSold ? 'Satıldı' : 'Stokta',
            style: TextStyle(
              fontSize: 11,
              color: isSold ? Colors.green[800] : Colors.blue[800],
            ),
          ),
          backgroundColor: isSold ? Colors.green[50] : Colors.blue[50],
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VehicleDetailScreen(vehicle: vehicle),
            ),
          );
          if (result == true) _loadVehicles();
        },
      ),
    );
  }
}
