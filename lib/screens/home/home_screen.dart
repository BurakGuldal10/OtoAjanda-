import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/vehicle_service.dart';
import '../vehicles/vehicle_list_screen.dart';
import '../vehicles/add_vehicle_screen.dart';
import '../stats/stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _vehicleService = VehicleService();
  final _authService = AuthService();
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _vehicleService.getStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Yan menü (NavigationRail)
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
              if (index == 0) _loadStats();
            },
            extended: MediaQuery.of(context).size.width > 1100,
            minWidth: 72,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  if (MediaQuery.of(context).size.width > 1100)
                    Text(
                      'GaleriPro',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Çıkış Yap',
                    onPressed: () async {
                      await _authService.signOut();
                    },
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Ana Sayfa'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.directions_car_outlined),
                selectedIcon: Icon(Icons.directions_car),
                label: Text('Araçlar'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('İstatistik'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Ana içerik
          Expanded(
            child: Column(
              children: [
                // Üst bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getTitle(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      if (_currentIndex == 0 || _currentIndex == 1)
                        FilledButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AddVehicleScreen()),
                            );
                            if (result == true) _loadStats();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Araç Ekle'),
                        ),
                    ],
                  ),
                ),
                // İçerik alanı
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Ana Sayfa';
      case 1:
        return 'Araç Yönetimi';
      case 2:
        return 'İstatistikler';
      default:
        return '';
    }
  }

  Widget _buildContent() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const VehicleListScreen();
      case 2:
        return const StatsScreen();
      default:
        return const SizedBox();
    }
  }

  Widget _buildDashboard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoş Geldiniz!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          // 4 stat kartı yan yana
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Stoktaki Araçlar',
                  '${_stats['stoktaAdet'] ?? 0}',
                  Icons.directions_car,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Satılan Araçlar',
                  '${_stats['satilanAdet'] ?? 0}',
                  Icons.sell,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Toplam Kar',
                  _currencyFormat.format(_stats['toplamKar'] ?? 0),
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Stok Yatırımı',
                  _currencyFormat.format(_stats['toplamYatirim'] ?? 0),
                  Icons.account_balance_wallet,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Hızlı İşlemler',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Araç Ekle',
                  Icons.add_circle_outline,
                  Colors.indigo,
                  () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddVehicleScreen()),
                    );
                    if (result == true) _loadStats();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  'Tüm Araçları Gör',
                  Icons.list_alt,
                  Colors.teal,
                  () => setState(() => _currentIndex = 1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  'İstatistikleri Gör',
                  Icons.analytics,
                  Colors.deepOrange,
                  () => setState(() => _currentIndex = 2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
              ],
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

  Widget _buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
