import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';
import '../../config/supabase_config.dart';
import '../../utils/error_handler.dart';
import '../../widgets/brand_picker.dart';
import '../../widgets/model_picker.dart';
import '../../widgets/car_logo_widget.dart';

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
  late TextEditingController _saticiAdiController;
  late TextEditingController _saticiTelefonController;
  late TextEditingController _saticiAdresController;
  DateTime? _alisTarihi;
  String _durum = 'stokta';
  bool _isLoading = false;
  String? _errorMessage; // Form submit hatasını kalıcı göstermek için

  bool get _isEditing => widget.vehicle != null;
  // Satıldı durumu sadece sat butonu ile değiştirilir, formda gösterilmez
  bool get _isSold => widget.vehicle?.durum == 'satildi';
  bool get _isMobile => MediaQuery.sizeOf(context).width < 600;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _plakaController = TextEditingController(text: v?.plaka ?? '');
    _markaController = TextEditingController(text: v?.marka ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');
    _yilController =
        TextEditingController(text: v?.yil?.toString() ?? '');
    _renkController = TextEditingController(text: v?.renk ?? '');
    _kilometreController =
        TextEditingController(text: v?.kilometre?.toString() ?? '');
    _alisFiyatiController =
        TextEditingController(text: v?.alisFiyati.toString() ?? '');
    _notlarController = TextEditingController(text: v?.notlar ?? '');
    _saticiAdiController = TextEditingController(text: v?.saticiAdi ?? '');
    _saticiTelefonController =
        TextEditingController(text: v?.saticiTelefon ?? '');
    _saticiAdresController =
        TextEditingController(text: v?.saticiAdres ?? '');
    _alisTarihi = v?.alisTarihi;
    _durum = v?.durum ?? 'stokta';
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
    _saticiAdiController.dispose();
    _saticiTelefonController.dispose();
    _saticiAdresController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _alisTarihi ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _alisTarihi = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _errorMessage =
            'Oturumunuz bulunamadı. Uygulamayı kapatıp tekrar giriş yapın.');
        return;
      }

      final vehicle = Vehicle(
        id: widget.vehicle?.id,
        userId: userId,
        plaka: _plakaController.text.trim().toUpperCase(),
        marka: _markaController.text.trim(),
        model: _modelController.text.trim(),
        yil: _yilController.text.isNotEmpty
            ? int.tryParse(_yilController.text)
            : null,
        renk: _renkController.text.trim().isNotEmpty
            ? _renkController.text.trim()
            : null,
        kilometre: _kilometreController.text.isNotEmpty
            ? int.tryParse(_kilometreController.text)
            : null,
        alisTarihi: _alisTarihi,
        alisFiyati: double.tryParse(_alisFiyatiController.text) ?? 0,
        durum: _isSold ? 'satildi' : _durum,
        notlar: _notlarController.text.trim().isNotEmpty
            ? _notlarController.text.trim()
            : null,
        saticiAdi: _saticiAdiController.text.trim().isNotEmpty
            ? _saticiAdiController.text.trim()
            : null,
        saticiTelefon: _saticiTelefonController.text.trim().isNotEmpty
            ? _saticiTelefonController.text.trim()
            : null,
        saticiAdres: _saticiAdresController.text.trim().isNotEmpty
            ? _saticiAdresController.text.trim()
            : null,
      );
      if (_isEditing) {
        await _vehicleService.updateVehicle(vehicle);
      } else {
        await _vehicleService.addVehicle(vehicle);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = AppError.from(e,
            ctx: _isEditing ? 'Araç güncellenemedi' : 'Araç kaydedilemedi'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                _isEditing ? Icons.edit_rounded : Icons.add_rounded,
                color: AppTheme.primary,
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _isEditing ? 'Aracı Düzenle' : 'Yeni Araç Ekle',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Araç Bilgileri ──────────────────────────────
                  _buildSectionCard(
                    title: 'Araç Bilgileri',
                    icon: Icons.directions_car_rounded,
                    children: [
                      // Plaka alanı
                      _buildField(
                        label: 'Plaka',
                        required: true,
                        child: TextFormField(
                          controller: _plakaController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: _decoration(
                              '34 ABC 123',
                              Icons.confirmation_number_outlined),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Plaka gerekli' : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Marka - Model: yan yana veya alt alta
                      if (_isMobile) ...[
                        _buildField(
                          label: 'Marka',
                          required: true,
                          child: _buildPickerField(
                            controller: _markaController,
                            hint: 'Toyota, BMW...',
                            icon: Icons.branding_watermark_outlined,
                            leading: _markaController.text.isNotEmpty
                                ? CarLogoWidget(
                                    marka: _markaController.text, size: 22)
                                : null,
                            onTap: () async {
                              final brand = await showBrandPicker(context);
                              if (brand != null) {
                                setState(() {
                                  _markaController.text = brand;
                                  _modelController.clear();
                                });
                              }
                            },
                            validator: (v) => v == null || v.isEmpty
                                ? 'Marka gerekli'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Model',
                          required: true,
                          child: _buildPickerField(
                            controller: _modelController,
                            hint: 'Corolla, 3 Serisi...',
                            icon: Icons.model_training_outlined,
                            onTap: () async {
                              final brand = _markaController.text.trim();
                              if (brand.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Önce marka seçin',
                                        style: GoogleFonts.inter(fontSize: 13)),
                                    backgroundColor: AppTheme.warning,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                );
                                return;
                              }
                              final model =
                                  await showModelPicker(context, brand);
                              if (model != null) {
                                setState(() => _modelController.text = model);
                              }
                            },
                            validator: (v) => v == null || v.isEmpty
                                ? 'Model gerekli'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                            child: _buildField(
                              label: 'Yıl',
                              child: TextFormField(
                                controller: _yilController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                decoration: _decoration(
                                    '2020', Icons.calendar_today_outlined),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return null;
                                  final y = int.tryParse(v);
                                  if (y == null || y < 1900 || y > 2100) {
                                    return 'Geçerli yıl girin';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              label: 'Renk',
                              child: TextFormField(
                                controller: _renkController,
                                decoration: _decoration('Beyaz, Siyah...',
                                    Icons.color_lens_outlined),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Kilometre',
                          child: TextFormField(
                            controller: _kilometreController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration:
                                _decoration('45000', Icons.speed_outlined)
                                    .copyWith(suffixText: 'km'),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              if (int.tryParse(v) == null) {
                                return 'Geçerli sayı girin';
                              }
                              return null;
                            },
                          ),
                        ),
                      ] else ...[
                        // Masaüstü: Marka - Model yan yana
                        Row(children: [
                          Expanded(
                            child: _buildField(
                              label: 'Marka',
                              required: true,
                              child: _buildPickerField(
                                controller: _markaController,
                                hint: 'Toyota, BMW...',
                                icon: Icons.branding_watermark_outlined,
                                leading: _markaController.text.isNotEmpty
                                    ? CarLogoWidget(
                                        marka: _markaController.text, size: 22)
                                    : null,
                                onTap: () async {
                                  final brand = await showBrandPicker(context);
                                  if (brand != null) {
                                    setState(() {
                                      _markaController.text = brand;
                                      _modelController.clear();
                                    });
                                  }
                                },
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Marka gerekli'
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'Model',
                              required: true,
                              child: _buildPickerField(
                                controller: _modelController,
                                hint: 'Corolla, 3 Serisi...',
                                icon: Icons.model_training_outlined,
                                onTap: () async {
                                  final brand = _markaController.text.trim();
                                  if (brand.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Önce marka seçin',
                                            style: GoogleFonts.inter(
                                                fontSize: 13)),
                                        backgroundColor: AppTheme.warning,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                    );
                                    return;
                                  }
                                  final model =
                                      await showModelPicker(context, brand);
                                  if (model != null) {
                                    setState(
                                        () => _modelController.text = model);
                                  }
                                },
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Model gerekli'
                                    : null,
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                            child: _buildField(
                              label: 'Yıl',
                              child: TextFormField(
                                controller: _yilController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                decoration: _decoration(
                                    '2020', Icons.calendar_today_outlined),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return null;
                                  final y = int.tryParse(v);
                                  if (y == null || y < 1900 || y > 2100) {
                                    return 'Geçerli yıl girin';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'Renk',
                              child: TextFormField(
                                controller: _renkController,
                                decoration: _decoration('Beyaz, Siyah...',
                                    Icons.color_lens_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'Kilometre',
                              child: TextFormField(
                                controller: _kilometreController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration:
                                    _decoration('45000', Icons.speed_outlined)
                                        .copyWith(suffixText: 'km'),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return null;
                                  if (int.tryParse(v) == null) {
                                    return 'Geçerli sayı girin';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Finansal Bilgiler ───────────────────────────
                  _buildSectionCard(
                    title: 'Finansal Bilgiler',
                    icon: Icons.payments_rounded,
                    children: [
                      if (_isMobile) ...[
                        _buildField(
                          label: 'Alış Fiyatı',
                          required: true,
                          child: TextFormField(
                            controller: _alisFiyatiController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*')),
                            ],
                            decoration:
                                _decoration('250000', Icons.payments_outlined)
                                    .copyWith(suffixText: '₺'),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Alış fiyatı gerekli';
                              }
                              final f = double.tryParse(v);
                              if (f == null || f < 0) {
                                return 'Geçerli fiyat girin';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Alış Tarihi',
                          child: InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(10),
                            child: InputDecorator(
                              decoration: _decoration(
                                  'Tarih seçin', Icons.date_range_outlined),
                              child: Text(
                                _alisTarihi != null
                                    ? _dateFormat.format(_alisTarihi!)
                                    : 'Tarih seçin',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: _alisTarihi != null
                                      ? AppTheme.textPrimary
                                      : AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else
                        Row(children: [
                          Expanded(
                            child: _buildField(
                              label: 'Alış Fiyatı',
                              required: true,
                              child: TextFormField(
                                controller: _alisFiyatiController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*')),
                                ],
                                decoration:
                                    _decoration('250000', Icons.payments_outlined)
                                        .copyWith(suffixText: '₺'),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Alış fiyatı gerekli';
                                  }
                                  final f = double.tryParse(v);
                                  if (f == null || f < 0) {
                                    return 'Geçerli fiyat girin';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'Alış Tarihi',
                              child: InkWell(
                                onTap: _selectDate,
                                borderRadius: BorderRadius.circular(10),
                                child: InputDecorator(
                                  decoration: _decoration('Tarih seçin',
                                      Icons.date_range_outlined),
                                  child: Text(
                                    _alisTarihi != null
                                        ? _dateFormat.format(_alisTarihi!)
                                        : 'Tarih seçin',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: _alisTarihi != null
                                          ? AppTheme.textPrimary
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Expanded(child: SizedBox()),
                        ]),
                      // Satıldı durumundaki araçta durum değiştirilemez
                      if (!_isSold) ...[
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Araç Durumu',
                          child: _buildDurumSelector(),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.successBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.success.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  size: 16, color: AppTheme.success),
                              const SizedBox(width: 8),
                              Text(
                                'Bu araç satıldı. Durum araç detay ekranından değiştirilemez.',
                                style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: AppTheme.successText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Satıcı Bilgileri (araç alınan kişi) ─────────
                  _buildSectionCard(
                    title: 'Satıcı Bilgileri',
                    icon: Icons.person_outline_rounded,
                    children: [
                      if (_isMobile) ...[
                        _buildField(
                          label: 'Satıcı Adı Soyadı',
                          child: TextFormField(
                            controller: _saticiAdiController,
                            decoration: _decoration(
                                'Ad Soyad', Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Telefon',
                          child: TextFormField(
                            controller: _saticiTelefonController,
                            keyboardType: TextInputType.phone,
                            decoration: _decoration(
                                '05XX XXX XX XX', Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Adres',
                          child: TextFormField(
                            controller: _saticiAdresController,
                            maxLines: 2,
                            decoration: _decoration(
                                    'Mahalle, ilçe, şehir...',
                                    Icons.location_on_outlined)
                                .copyWith(
                              prefixIcon: null,
                              alignLabelWithHint: true,
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(children: [
                          Expanded(
                            child: _buildField(
                              label: 'Satıcı Adı Soyadı',
                              child: TextFormField(
                                controller: _saticiAdiController,
                                decoration: _decoration(
                                    'Ad Soyad', Icons.badge_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'Telefon',
                              child: TextFormField(
                                controller: _saticiTelefonController,
                                keyboardType: TextInputType.phone,
                                decoration: _decoration('05XX XXX XX XX',
                                    Icons.phone_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'Adres',
                              child: TextFormField(
                                controller: _saticiAdresController,
                                decoration: _decoration(
                                    'Mahalle, ilçe, şehir...',
                                    Icons.location_on_outlined),
                              ),
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Notlar ──────────────────────────────────────
                  _buildSectionCard(
                    title: 'Notlar',
                    icon: Icons.notes_rounded,
                    children: [
                      TextFormField(
                        controller: _notlarController,
                        maxLines: 3,
                        decoration: _decoration(
                                'Araçla ilgili notlarınızı buraya yazın...',
                                Icons.notes_outlined)
                            .copyWith(
                          prefixIcon: null,
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Hata mesajı (varsa) ──────────────────────────
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppTheme.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF991B1B),
                                height: 1.5,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _errorMessage = null),
                            child: const Icon(Icons.close_rounded,
                                size: 16, color: AppTheme.error),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Butonlar ────────────────────────────────────
                  if (_isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _save,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : Icon(
                                    _isEditing
                                        ? Icons.save_rounded
                                        : Icons.add_rounded,
                                    size: 18),
                            label: Text(
                              _isEditing
                                  ? 'Değişiklikleri Kaydet'
                                  : 'Araç Ekle',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side: const BorderSide(color: AppTheme.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('İptal',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(color: AppTheme.border),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('İptal',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 46,
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _save,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : Icon(
                                    _isEditing
                                        ? Icons.save_rounded
                                        : Icons.add_rounded,
                                    size: 18),
                            label: Text(
                              _isEditing
                                  ? 'Değişiklikleri Kaydet'
                                  : 'Araç Ekle',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 13),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDurumSelector() {
    const options = [
      ('stokta', 'Stokta', Icons.inventory_2_outlined, AppTheme.primary, AppTheme.primaryLight),
      ('rezerve', 'Rezerve', Icons.schedule_rounded, AppTheme.warning, AppTheme.warningBg),
    ];

    return Row(
      children: options.map((opt) {
        final (value, label, icon, color, bg) = opt;
        final isSelected = _durum == value;
        return Expanded(
          child: Padding(
            padding: options.indexOf(opt) == 0
                ? const EdgeInsets.only(right: 8)
                : const EdgeInsets.only(left: 8),
            child: GestureDetector(
              onTap: () => setState(() => _durum = value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? bg : AppTheme.bgMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.5)
                        : AppTheme.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon,
                        size: 18,
                        color: isSelected ? color : AppTheme.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected ? color : AppTheme.textSecondary,
                      ),
                    ),
                    if (isSelected) ...[
                      const Spacer(),
                      Icon(Icons.check_circle_rounded,
                          size: 16, color: color),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primary, size: 16),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppTheme.border),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    bool required = false,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 3),
              const Text('*',
                  style: TextStyle(color: AppTheme.error, fontSize: 13)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 17, color: AppTheme.textMuted),
    );
  }

  /// Tıklanabilir picker field (marka / model için)
  Widget _buildPickerField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    Widget? leading,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
        prefixIcon: leading != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: leading,
              )
            : Icon(icon, size: 17, color: AppTheme.textMuted),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 42,
          minHeight: 0,
        ),
        suffixIcon: const Icon(Icons.expand_more_rounded,
            size: 18, color: AppTheme.textMuted),
      ),
      validator: validator,
    );
  }
}
