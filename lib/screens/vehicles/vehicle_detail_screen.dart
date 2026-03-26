import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vehicle.dart';
import '../../models/expense.dart';
import '../../services/vehicle_service.dart';
import '../../services/expense_service.dart';
import '../../config/supabase_config.dart';
import 'add_vehicle_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final _vehicleService = VehicleService();
  final _expenseService = ExpenseService();
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  final _dateFormat = DateFormat('dd/MM/yyyy');

  late Vehicle _vehicle;
  List<Expense> _expenses = [];
  double _totalExpenses = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    if (_vehicle.id == null) return;
    setState(() => _isLoading = true);
    try {
      _expenses = await _expenseService.getExpenses(_vehicle.id!);
      _totalExpenses = await _expenseService.getTotalExpenses(_vehicle.id!);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  double get _netKar {
    if (_vehicle.kar == null) return 0;
    return _vehicle.kar! - _totalExpenses;
  }

  Future<void> _sellVehicle() async {
    final fiyatController = TextEditingController();
    DateTime satisTarihi = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Aracı Sat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: fiyatController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Satış Fiyatı',
                  suffixText: '₺',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: satisTarihi,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => satisTarihi = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Satış Tarihi',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_dateFormat.format(satisTarihi)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sat'),
            ),
          ],
        ),
      ),
    );

    if (result == true && fiyatController.text.isNotEmpty) {
      try {
        final updated = await _vehicleService.sellVehicle(
          vehicleId: _vehicle.id!,
          satisFiyati: double.parse(fiyatController.text),
          satisTarihi: satisTarihi,
        );
        setState(() => _vehicle = updated);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _addExpense() async {
    final tutarController = TextEditingController();
    final aciklamaController = TextEditingController();
    String selectedTur = 'bakim';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Gider Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedTur,
                decoration: const InputDecoration(
                  labelText: 'Gider Türü',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'bakim', child: Text('Bakım')),
                  DropdownMenuItem(value: 'boya', child: Text('Boya')),
                  DropdownMenuItem(value: 'sigorta', child: Text('Sigorta')),
                  DropdownMenuItem(value: 'vergi', child: Text('Vergi')),
                  DropdownMenuItem(value: 'diger', child: Text('Diğer')),
                ],
                onChanged: (v) => setDialogState(() => selectedTur = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: tutarController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tutar',
                  suffixText: '₺',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: aciklamaController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );

    if (result == true && tutarController.text.isNotEmpty) {
      try {
        await _expenseService.addExpense(Expense(
          vehicleId: _vehicle.id!,
          userId: SupabaseConfig.client.auth.currentUser!.id,
          tur: selectedTur,
          tutar: double.parse(tutarController.text),
          aciklama: aciklamaController.text.isNotEmpty
              ? aciklamaController.text
              : null,
          tarih: DateTime.now(),
        ));
        _loadExpenses();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteVehicle() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aracı Sil'),
        content: const Text('Bu aracı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _vehicleService.deleteVehicle(_vehicle.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSold = _vehicle.durum == 'satildi';

    return Scaffold(
      appBar: AppBar(
        title: Text('${_vehicle.marka} ${_vehicle.model}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddVehicleScreen(vehicle: _vehicle),
                ),
              );
              if (result == true) Navigator.pop(context, true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteVehicle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Araç bilgileri kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('Plaka', _vehicle.plaka),
                    _buildInfoRow('Marka', _vehicle.marka),
                    _buildInfoRow('Model', _vehicle.model),
                    if (_vehicle.yil != null)
                      _buildInfoRow('Yıl', _vehicle.yil.toString()),
                    if (_vehicle.renk != null)
                      _buildInfoRow('Renk', _vehicle.renk!),
                    if (_vehicle.kilometre != null)
                      _buildInfoRow(
                          'Kilometre', '${_vehicle.kilometre} km'),
                    _buildInfoRow('Durum', isSold ? 'Satıldı' : 'Stokta'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Finansal bilgiler
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Finansal Bilgiler',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Divider(),
                    _buildInfoRow('Alış Fiyatı',
                        _currencyFormat.format(_vehicle.alisFiyati)),
                    if (_vehicle.alisTarihi != null)
                      _buildInfoRow(
                          'Alış Tarihi', _dateFormat.format(_vehicle.alisTarihi!)),
                    if (isSold && _vehicle.satisFiyati != null)
                      _buildInfoRow('Satış Fiyatı',
                          _currencyFormat.format(_vehicle.satisFiyati)),
                    if (_vehicle.satisTarihi != null)
                      _buildInfoRow('Satış Tarihi',
                          _dateFormat.format(_vehicle.satisTarihi!)),
                    if (_vehicle.kar != null)
                      _buildInfoRow(
                        'Brüt Kar',
                        _currencyFormat.format(_vehicle.kar),
                        valueColor:
                            _vehicle.kar! >= 0 ? Colors.green : Colors.red,
                      ),
                    _buildInfoRow(
                        'Toplam Gider', _currencyFormat.format(_totalExpenses)),
                    if (isSold)
                      _buildInfoRow(
                        'Net Kar',
                        _currencyFormat.format(_netKar),
                        valueColor: _netKar >= 0 ? Colors.green : Colors.red,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Giderler
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Giderler',
                    style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: _addExpense,
                  icon: const Icon(Icons.add),
                  label: const Text('Gider Ekle'),
                ),
              ],
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_expenses.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Henüz gider eklenmemiş')),
                ),
              )
            else
              ..._expenses.map((e) => Card(
                    child: ListTile(
                      leading: Icon(_getExpenseIcon(e.tur)),
                      title: Text(_getExpenseLabel(e.tur)),
                      subtitle: e.aciklama != null ? Text(e.aciklama!) : null,
                      trailing: Text(
                        _currencyFormat.format(e.tutar),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  )),

            if (_vehicle.notlar != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notlar',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Divider(),
                      Text(_vehicle.notlar!),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Satış butonu
            if (!isSold)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _sellVehicle,
                  icon: const Icon(Icons.sell),
                  label: const Text('Bu Aracı Sat',
                      style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getExpenseIcon(String tur) {
    switch (tur) {
      case 'bakim':
        return Icons.build;
      case 'boya':
        return Icons.format_paint;
      case 'sigorta':
        return Icons.security;
      case 'vergi':
        return Icons.receipt;
      default:
        return Icons.money_off;
    }
  }

  String _getExpenseLabel(String tur) {
    switch (tur) {
      case 'bakim':
        return 'Bakım';
      case 'boya':
        return 'Boya';
      case 'sigorta':
        return 'Sigorta';
      case 'vergi':
        return 'Vergi';
      default:
        return 'Diğer';
    }
  }
}
