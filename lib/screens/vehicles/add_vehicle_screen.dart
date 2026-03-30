import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';
import '../../config/supabase_config.dart';

class AddVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const AddVehicleScreen({super.key, this.vehicle});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleService = VehicleService();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  late TextEditingController _plakaController;
  late TextEditingController _markaController;
  late TextEditingController _modelController;
  late TextEditingController _yilController;
  late TextEditingController _renkController;
  late TextEditingController _kilometreController;
  late TextEditingController _alisFiyatiController;
  late TextEditingController _notlarController;
  DateTime? _alisTarihi;
  bool _isLoading = false;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _plakaController = TextEditingController(text: v?.plaka ?? '');
    _markaController = TextEditingController(text: v?.marka ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');
    _yilController = TextEditingController(text: v?.yil?.toString() ?? '');
    _renkController = TextEditingController(text: v?.renk ?? '');
    _kilometreController =
        TextEditingController(text: v?.kilometre?.toString() ?? '');
    _alisFiyatiController =
        TextEditingController(text: v?.alisFiyati.toString() ?? '');
    _notlarController = TextEditingController(text: v?.notlar ?? '');
    _alisTarihi = v?.alisTarihi;
  }

  @override
  void dispose() {
    _plakaController.dispose();
    _markaController.dispose();
    _modelController.dispose();
    _yilController.dispose();
    _renkController.dispose();
    _kilometreController.dispose();
    _alisFiyatiController.dispose();
    _notlarController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _alisTarihi ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _alisTarihi = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final vehicle = Vehicle(
        id: widget.vehicle?.id,
        userId: SupabaseConfig.client.auth.currentUser!.id,
        plaka: _plakaController.text.trim().toUpperCase(),
        marka: _markaController.text.trim(),
        model: _modelController.text.trim(),
        yil: _yilController.text.isNotEmpty
            ? int.parse(_yilController.text)
            : null,
        renk: _renkController.text.trim().isNotEmpty
            ? _renkController.text.trim()
            : null,
        kilometre: _kilometreController.text.isNotEmpty
            ? int.parse(_kilometreController.text)
            : null,
        alisTarihi: _alisTarihi,
        alisFiyati: double.parse(_alisFiyatiController.text),
        notlar: _notlarController.text.trim().isNotEmpty
            ? _notlarController.text.trim()
            : null,
      );

      if (_isEditing) {
        await _vehicleService.updateVehicle(vehicle);
      } else {
        await _vehicleService.addVehicle(vehicle);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Aracı Düzenle' : 'Araç Ekle'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Araç bilgileri başlığı
                  Text(
                    'Araç Bilgileri',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Satır 1: Plaka - Marka - Model
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _plakaController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Plaka *',
                            prefixIcon: Icon(Icons.confirmation_number),
                            hintText: '34 ABC 123',
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Plaka gerekli' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _markaController,
                          decoration: const InputDecoration(
                            labelText: 'Marka *',
                            prefixIcon: Icon(Icons.branding_watermark),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Marka gerekli' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _modelController,
                          decoration: const InputDecoration(
                            labelText: 'Model *',
                            prefixIcon: Icon(Icons.model_training),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Model gerekli' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Satır 2: Yıl - Renk - Kilometre
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _yilController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Yıl',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _renkController,
                          decoration: const InputDecoration(
                            labelText: 'Renk',
                            prefixIcon: Icon(Icons.color_lens),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _kilometreController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Kilometre',
                            prefixIcon: Icon(Icons.speed),
                            suffixText: 'km',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Finansal bilgiler başlığı
                  Text(
                    'Finansal Bilgiler',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Satır 3: Alış Fiyatı - Alış Tarihi
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _alisFiyatiController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Alış Fiyatı *',
                            prefixIcon: Icon(Icons.payments),
                            suffixText: '₺',
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Alış fiyatı gerekli'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Alış Tarihi',
                              prefixIcon: Icon(Icons.date_range),
                            ),
                            child: Text(
                              _alisTarihi != null
                                  ? _dateFormat.format(_alisTarihi!)
                                  : 'Tarih seçin',
                            ),
                          ),
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Notlar
                  Text(
                    'Notlar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notlarController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notlar',
                      prefixIcon: Icon(Icons.notes),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Kaydet butonu
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 200,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _save,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(_isEditing ? Icons.save : Icons.add),
                        label: Text(
                          _isEditing ? 'Güncelle' : 'Araç Ekle',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
