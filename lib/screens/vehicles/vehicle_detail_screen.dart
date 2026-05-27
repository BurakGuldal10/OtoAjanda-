import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/vehicle.dart';
import '../../models/expense.dart';
import '../../services/vehicle_service.dart';
import '../../services/expense_service.dart';
import '../../config/supabase_config.dart';
import '../../widgets/car_logo_widget.dart';
import '../../utils/error_handler.dart';
import '../../utils/format_utils.dart';
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
  final _currencyFormat =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
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
      _totalExpenses =
          await _expenseService.getTotalExpenses(_vehicle.id!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppError.from(e, ctx: 'Giderler yüklenemedi')),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  double get _netKar {
    if (_vehicle.kar == null) return 0;
    return _vehicle.kar! - _totalExpenses;
  }

  bool get _isMobile => MediaQuery.sizeOf(context).width < 600;

  // ── Diyaloglar ────────────────────────────────────────────────────

  Future<void> _sellVehicle() async {
    final fiyatController = TextEditingController();
    final aliciAdiController = TextEditingController();
    final aliciTelefonController = TextEditingController();
    final aliciAdresController = TextEditingController();
    DateTime satisTarihi = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          title: Text('Aracı Sat',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogLabel('Satış Fiyatı'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: fiyatController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: '0',
                      suffixText: '₺',
                      prefixIcon: Icon(Icons.payments_outlined,
                          size: 18, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _dialogLabel('Satış Tarihi'),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: satisTarihi,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setS(() => satisTarihi = picked);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.date_range_outlined,
                            size: 18, color: AppTheme.textMuted),
                      ),
                      child: Text(_dateFormat.format(satisTarihi),
                          style: GoogleFonts.inter(
                              fontSize: 14, color: AppTheme.textPrimary)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 1,
                    color: AppTheme.border,
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 15, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Alıcı Bilgileri',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('(isteğe bağlı)',
                        style: GoogleFonts.inter(
                            fontSize: 11.5, color: AppTheme.textMuted)),
                  ]),
                  const SizedBox(height: 12),
                  _dialogLabel('Ad Soyad'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: aliciAdiController,
                    decoration: const InputDecoration(
                      hintText: 'Alıcının adı soyadı',
                      prefixIcon: Icon(Icons.badge_outlined,
                          size: 18, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _dialogLabel('Telefon'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: aliciTelefonController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '05XX XXX XX XX',
                      prefixIcon: Icon(Icons.phone_outlined,
                          size: 18, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _dialogLabel('Adres'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: aliciAdresController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Mahalle, ilçe, şehir...',
                      prefixIcon: Icon(Icons.location_on_outlined,
                          size: 18, color: AppTheme.textMuted),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('İptal',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: Text('Satışı Onayla',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final fiyat = tutarCevir(fiyatController.text);
      if (fiyat == null) {
        _gecersizTutarUyari();
      } else {
        try {
          final updated = await _vehicleService.sellVehicle(
            vehicleId: _vehicle.id!,
            satisFiyati: fiyat,
            satisTarihi: satisTarihi,
            aliciAdi: aliciAdiController.text.trim().isNotEmpty
                ? aliciAdiController.text.trim()
                : null,
            aliciTelefon: aliciTelefonController.text.trim().isNotEmpty
                ? aliciTelefonController.text.trim()
                : null,
            aliciAdres: aliciAdresController.text.trim().isNotEmpty
                ? aliciAdresController.text.trim()
                : null,
          );
          setState(() => _vehicle = updated);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppError.from(e, ctx: 'Satış kaydedilemedi')),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        }
      }
    }

    fiyatController.dispose();
    aliciAdiController.dispose();
    aliciTelefonController.dispose();
    aliciAdresController.dispose();
  }

  Future<void> _addExpense() async {
    final tutarController = TextEditingController();
    final aciklamaController = TextEditingController();
    String selectedTur = 'bakim';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _buildExpenseDialog(
          title: 'Gider Ekle',
          tutarController: tutarController,
          aciklamaController: aciklamaController,
          selectedTur: selectedTur,
          onTurChanged: (v) => setS(() => selectedTur = v!),
          onConfirm: () => Navigator.pop(ctx, true),
          onCancel: () => Navigator.pop(ctx, false),
          confirmLabel: 'Ekle',
        ),
      ),
    );

    if (result == true) {
      final tutar = tutarCevir(tutarController.text);
      if (tutar == null) {
        _gecersizTutarUyari();
      } else {
        try {
          await _expenseService.addExpense(Expense(
            vehicleId: _vehicle.id!,
            userId: SupabaseConfig.client.auth.currentUser!.id,
            tur: selectedTur,
            tutar: tutar,
            aciklama: aciklamaController.text.isNotEmpty
                ? aciklamaController.text
                : null,
            tarih: DateTime.now(),
          ));
          _loadExpenses();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppError.from(e, ctx: 'Gider eklenemedi')),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        }
      }
    }

    tutarController.dispose();
    aciklamaController.dispose();
  }

  Future<void> _editExpense(Expense expense) async {
    final tutarController =
        TextEditingController(text: expense.tutar.toString());
    final aciklamaController =
        TextEditingController(text: expense.aciklama ?? '');
    String selectedTur = expense.tur;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _buildExpenseDialog(
          title: 'Gider Düzenle',
          tutarController: tutarController,
          aciklamaController: aciklamaController,
          selectedTur: selectedTur,
          onTurChanged: (v) => setS(() => selectedTur = v!),
          onConfirm: () => Navigator.pop(ctx, true),
          onCancel: () => Navigator.pop(ctx, false),
          confirmLabel: 'Kaydet',
        ),
      ),
    );

    if (result == true) {
      final tutar = tutarCevir(tutarController.text);
      if (tutar == null) {
        _gecersizTutarUyari();
      } else {
        try {
          await _expenseService.updateExpense(Expense(
            id: expense.id,
            vehicleId: expense.vehicleId,
            userId: expense.userId,
            tur: selectedTur,
            tutar: tutar,
            aciklama: aciklamaController.text.isNotEmpty
                ? aciklamaController.text
                : null,
            tarih: expense.tarih,
          ));
          _loadExpenses();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppError.from(e, ctx: 'Gider güncellenemedi')),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        }
      }
    }

    tutarController.dispose();
    aciklamaController.dispose();
  }

  Widget _buildExpenseDialog({
    required String title,
    required TextEditingController tutarController,
    required TextEditingController aciklamaController,
    required String selectedTur,
    required ValueChanged<String?> onTurChanged,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
    required String confirmLabel,
  }) {
    return AlertDialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(title,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogLabel('Gider Türü'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: selectedTur,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppTheme.textPrimary),
              dropdownColor: AppTheme.bgCard,
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined,
                      size: 18, color: AppTheme.textMuted)),
              items: [
                DropdownMenuItem(
                    value: 'bakim',
                    child: Text('Bakım',
                        style: GoogleFonts.inter(color: AppTheme.textPrimary))),
                DropdownMenuItem(
                    value: 'boya',
                    child: Text('Boya',
                        style: GoogleFonts.inter(color: AppTheme.textPrimary))),
                DropdownMenuItem(
                    value: 'sigorta',
                    child: Text('Sigorta',
                        style: GoogleFonts.inter(color: AppTheme.textPrimary))),
                DropdownMenuItem(
                    value: 'vergi',
                    child: Text('Vergi',
                        style: GoogleFonts.inter(color: AppTheme.textPrimary))),
                DropdownMenuItem(
                    value: 'diger',
                    child: Text('Diğer',
                        style: GoogleFonts.inter(color: AppTheme.textPrimary))),
              ],
              onChanged: onTurChanged,
            ),
            const SizedBox(height: 14),
            _dialogLabel('Tutar'),
            const SizedBox(height: 6),
            TextFormField(
              controller: tutarController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: '0',
                suffixText: '₺',
                prefixIcon: Icon(Icons.attach_money_rounded,
                    size: 18, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 14),
            _dialogLabel('Açıklama (isteğe bağlı)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: aciklamaController,
              decoration: const InputDecoration(
                hintText: 'Kısa açıklama...',
                prefixIcon: Icon(Icons.notes_outlined,
                    size: 18, color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text('İptal',
              style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        ),
        FilledButton(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          child: Text(confirmLabel,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  void _gecersizTutarUyari() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Geçerli bir tutar girin (örn. 150000).',
            style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _dialogLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: AppTheme.textSecondary),
    );
  }

  Future<void> _deleteVehicle() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: Text('Aracı Sil',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        content: Text(
          '${_vehicle.marka} ${_vehicle.model} (${_vehicle.plaka}) silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
          style: GoogleFonts.inter(
              fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal',
                style:
                    GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: Text('Sil',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _vehicleService.deleteVehicle(_vehicle.id!);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppError.from(e, ctx: 'Araç silinemedi')),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isSold = _vehicle.durum == 'satildi';

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: _buildAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(_isMobile ? 12 : 24),
            child: _isMobile
                ? _buildMobileBody(isSold)
                : _buildDesktopBody(isSold),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          CarLogoWidget(marka: _vehicle.marka, size: 30),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_vehicle.marka} ${_vehicle.model}',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _vehicle.plaka,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: _isMobile
          ? [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppTheme.textPrimary),
                onSelected: (value) async {
                  if (value == 'edit') {
                    final nav = Navigator.of(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              AddVehicleScreen(vehicle: _vehicle)),
                    );
                    if (result == true && mounted) nav.pop(true);
                  } else if (value == 'delete') {
                    _deleteVehicle();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      const Icon(Icons.edit_outlined,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Text('Düzenle',
                          style: GoogleFonts.inter(fontSize: 13)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete_outline_rounded,
                          size: 16, color: AppTheme.error),
                      const SizedBox(width: 8),
                      Text('Sil',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppTheme.error)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ]
          : [
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text('Düzenle',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AddVehicleScreen(vehicle: _vehicle)),
                  );
                  if (result == true && mounted) nav.pop(true);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: Text('Sil',
                    style:
                        GoogleFonts.inter(fontWeight: FontWeight.w500)),
                onPressed: _deleteVehicle,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 16),
            ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.border),
      ),
    );
  }

  // ── Mobil: dikey düzen ────────────────────────────────────────────
  Widget _buildMobileBody(bool isSold) {
    return Column(
      children: [
        _buildHeroSection(),
        const SizedBox(height: 12),
        _buildInfoCard(),
        const SizedBox(height: 12),
        _buildFinanceCard(isSold),
        if (!isSold) ...[
          const SizedBox(height: 12),
          _buildSellButton(),
        ],
        if (_vehicle.notlar != null) ...[
          const SizedBox(height: 12),
          _buildNotesCard(),
        ],
        const SizedBox(height: 12),
        _buildExpensesCard(),
      ],
    );
  }

  // ── Masaüstü: iki sütun ───────────────────────────────────────────
  Widget _buildDesktopBody(bool isSold) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroSection(),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildFinanceCard(isSold),
                  if (!isSold) ...[
                    const SizedBox(height: 16),
                    _buildSellButton(),
                  ],
                  if (_vehicle.notlar != null) ...[
                    const SizedBox(height: 16),
                    _buildNotesCard(),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: _buildExpensesCard(),
            ),
          ],
        ),
      ],
    );
  }

  // ── Hero bölümü — koyu gradyan, büyük logo, net kâr özeti ─────────
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1117), Color(0xFF161B22), Color(0xFF1C2333)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _isMobile ? _heroMobile() : _heroDesktop(),
    );
  }

  Widget _heroDesktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Araç logosu — beyaz yuvarlak kutu içinde
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: CarLogoWidget(marka: _vehicle.marka, size: 56),
        ),
        const SizedBox(width: 20),

        // Araç adı + plaka + hızlı stats
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${_vehicle.marka} ${_vehicle.model}',
                    style: GoogleFonts.inter(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: Colors.white, letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _statusBadgeHero(_vehicle.durum),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _vehicle.plaka,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_vehicle.yil != null)
                    _heroStat(Icons.calendar_today_rounded, '${_vehicle.yil}'),
                  if (_vehicle.renk != null) ...[
                    _heroDivider(),
                    _heroStat(Icons.palette_outlined, _vehicle.renk!),
                  ],
                  if (_vehicle.kilometre != null) ...[
                    _heroDivider(),
                    _heroStat(Icons.speed_rounded,
                        '${NumberFormat('#,###', 'tr_TR').format(_vehicle.kilometre)} km'),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Net Kâr kutusu (sadece satıldıysa ve yüklendiyse)
        if (_vehicle.durum == 'satildi' && !_isLoading) ...[
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: _netKar >= 0
                  ? const Color(0xFF0D9488).withValues(alpha: 0.15)
                  : const Color(0xFFDC2626).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _netKar >= 0
                    ? const Color(0xFF0D9488).withValues(alpha: 0.35)
                    : const Color(0xFFDC2626).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _netKar >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Net Kâr',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  _currencyFormat.format(_netKar),
                  style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: _netKar >= 0
                        ? const Color(0xFF34D399)  // emerald-400
                        : const Color(0xFFF87171), // red-400
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _heroMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(6),
              child: CarLogoWidget(marka: _vehicle.marka, size: 44),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_vehicle.marka} ${_vehicle.model}',
                    style: GoogleFonts.inter(
                      fontSize: 17, fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        _vehicle.plaka,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _statusBadgeHero(_vehicle.durum),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
        const SizedBox(height: 12),
        Row(
          children: [
            if (_vehicle.yil != null)
              Expanded(child: _heroStat(
                  Icons.calendar_today_rounded, '${_vehicle.yil}')),
            if (_vehicle.renk != null)
              Expanded(child: _heroStat(
                  Icons.palette_outlined, _vehicle.renk!)),
            if (_vehicle.kilometre != null)
              Expanded(child: _heroStat(
                  Icons.speed_rounded,
                  '${NumberFormat('#,###', 'tr_TR').format(_vehicle.kilometre)} km')),
          ],
        ),
      ],
    );
  }

  Widget _heroStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.4)),
        const SizedBox(width: 5),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _heroDivider() => Container(
    width: 1, height: 14, margin: const EdgeInsets.symmetric(horizontal: 12),
    color: Colors.white.withValues(alpha: 0.15),
  );

  // Hero için açık renkli durum rozeti (koyu arka plan üzerinde)
  Widget _statusBadgeHero(String durum) {
    Color bg; Color textColor; String label; IconData icon;
    switch (durum) {
      case 'satildi':
        bg        = const Color(0xFF059669).withValues(alpha: 0.2);
        textColor = const Color(0xFF34D399);
        label     = 'Satıldı';
        icon      = Icons.check_circle_outline_rounded;
        break;
      case 'rezerve':
        bg        = const Color(0xFFD97706).withValues(alpha: 0.2);
        textColor = const Color(0xFFFBBF24);
        label     = 'Rezerve';
        icon      = Icons.schedule_rounded;
        break;
      default:
        bg        = const Color(0xFF3B82F6).withValues(alpha: 0.2);
        textColor = const Color(0xFF60A5FA);
        label     = 'Stokta';
        icon      = Icons.inventory_2_outlined;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(label,
            style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final hasSatici = _vehicle.saticiAdi != null ||
        _vehicle.saticiTelefon != null ||
        _vehicle.saticiAdres != null;

    return _card(
      icon: Icons.directions_car_rounded,
      iconColor: AppTheme.primary,
      iconBg: AppTheme.primaryLight,
      title: 'Araç Bilgileri',
      child: Column(children: [
        _row('Plaka', _vehicle.plaka, valueStyle: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary)),
        _row('Marka', '',
          valueWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                padding: const EdgeInsets.all(3),
                child: CarLogoWidget(marka: _vehicle.marka, size: 22),
              ),
              const SizedBox(width: 8),
              Text(_vehicle.marka,
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary)),
            ],
          ),
        ),
        _row('Model', _vehicle.model),
        if (_vehicle.yil != null) _row('Yıl', _vehicle.yil.toString()),
        if (_vehicle.renk != null) _row('Renk', _vehicle.renk!),
        if (_vehicle.kilometre != null)
          _row('Kilometre', '${_vehicle.kilometre} km'),
        _row(
          'Durum',
          '',
          valueWidget: _statusBadge(_vehicle.durum),
        ),
        if (hasSatici) ...[
          const SizedBox(height: 8),
          _sectionDivider('Alındığı Kişi (Satıcı)', Icons.person_outline_rounded,
              const Color(0xFF7C3AED), const Color(0xFFEDE9FE)),
          if (_vehicle.saticiAdi != null)
            _row('Ad Soyad', _vehicle.saticiAdi!),
          if (_vehicle.saticiTelefon != null)
            _row('Telefon', _vehicle.saticiTelefon!),
          if (_vehicle.saticiAdres != null)
            _row('Adres', _vehicle.saticiAdres!),
        ],
      ]),
    );
  }

  Widget _buildFinanceCard(bool isSold) {
    final hasAlici = _vehicle.aliciAdi != null ||
        _vehicle.aliciTelefon != null ||
        _vehicle.aliciAdres != null;

    return _card(
      icon: Icons.payments_rounded,
      iconColor: const Color(0xFF059669),
      iconBg: const Color(0xFFD1FAE5),
      title: 'Finansal Bilgiler',
      child: Column(children: [
        _row('Alış Fiyatı',
            _currencyFormat.format(_vehicle.alisFiyati)),
        if (_vehicle.alisTarihi != null)
          _row('Alış Tarihi',
              _dateFormat.format(_vehicle.alisTarihi!)),
        if (isSold && _vehicle.satisFiyati != null)
          _row('Satış Fiyatı',
              _currencyFormat.format(_vehicle.satisFiyati)),
        if (_vehicle.satisTarihi != null)
          _row('Satış Tarihi',
              _dateFormat.format(_vehicle.satisTarihi!)),
        if (_vehicle.kar != null)
          _row(
            'Brüt Kâr',
            _currencyFormat.format(_vehicle.kar),
            valueColor: _vehicle.kar! >= 0 ? AppTheme.success : AppTheme.error,
          ),
        _row('Toplam Gider',
            _currencyFormat.format(_totalExpenses),
            valueColor: AppTheme.warning),
        if (isSold)
          _row(
            'Net Kâr',
            _currencyFormat.format(_netKar),
            valueColor: _netKar >= 0 ? AppTheme.success : AppTheme.error,
            bold: true,
          ),
        if (isSold && hasAlici) ...[
          const SizedBox(height: 8),
          _sectionDivider('Satıldığı Kişi (Alıcı)', Icons.person_rounded,
              const Color(0xFF059669), const Color(0xFFD1FAE5)),
          if (_vehicle.aliciAdi != null)
            _row('Ad Soyad', _vehicle.aliciAdi!),
          if (_vehicle.aliciTelefon != null)
            _row('Telefon', _vehicle.aliciTelefon!),
          if (_vehicle.aliciAdres != null)
            _row('Adres', _vehicle.aliciAdres!),
        ],
      ]),
    );
  }

  Future<void> _toggleRezerve() async {
    final isRezerve = _vehicle.durum == 'rezerve';
    final newDurum = isRezerve ? 'stokta' : 'rezerve';
    final actionLabel = isRezerve ? 'Rezervasyonu İptal Et' : 'Rezerve Et';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: Text(actionLabel,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        content: Text(
          isRezerve
              ? '${_vehicle.plaka} plakalı araç tekrar stoka alınacak. Onaylıyor musunuz?'
              : '${_vehicle.plaka} plakalı araç rezerveye alınacak. Onaylıyor musunuz?',
          style: GoogleFonts.inter(
              fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal',
                style:
                    GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  isRezerve ? AppTheme.primary : AppTheme.warning,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(actionLabel,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final updated =
            await _vehicleService.updateStatus(_vehicle.id!, newDurum);
        setState(() => _vehicle = updated);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppError.from(e, ctx: 'Araç durumu güncellenemedi')),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    }
  }

  Widget _buildSellButton() {
    final isRezerve = _vehicle.durum == 'rezerve';

    return Column(
      children: [
        // Sat butonu
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton.icon(
            onPressed: _sellVehicle,
            icon: const Icon(Icons.sell_rounded, size: 18),
            label: Text('Bu Aracı Sat',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.success,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Rezerve / Rezerve İptal butonu
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton.icon(
            onPressed: _toggleRezerve,
            icon: Icon(
              isRezerve
                  ? Icons.undo_rounded
                  : Icons.schedule_rounded,
              size: 17,
            ),
            label: Text(
              isRezerve ? 'Rezervasyonu İptal Et' : 'Rezerve Et',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  isRezerve ? AppTheme.textSecondary : AppTheme.warning,
              side: BorderSide(
                color: isRezerve
                    ? AppTheme.border
                    : AppTheme.warning.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard() {
    return _card(
      icon: Icons.notes_rounded,
      iconColor: const Color(0xFF7C3AED),
      iconBg: const Color(0xFFEDE9FE),
      title: 'Notlar',
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _vehicle.notlar!,
          style: GoogleFonts.inter(
              fontSize: 13.5,
              color: AppTheme.textSecondary,
              height: 1.6),
        ),
      ),
    );
  }

  Widget _buildExpensesCard() {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: AppTheme.warning, size: 16),
                ),
                const SizedBox(width: 10),
                Text('Giderler',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _addExpense,
                  icon: const Icon(Icons.add, size: 15),
                  label: Text('Ekle',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2)),
            )
          else if (_expenses.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.receipt_outlined,
                        size: 36, color: AppTheme.textMuted),
                    const SizedBox(height: 10),
                    Text('Henüz gider eklenmemiş',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppTheme.textMuted)),
                  ],
                ),
              ),
            )
          else
            ..._expenses.map((e) => _buildExpenseItem(e)),
          if (_expenses.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Toplam Gider',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text(
                    _currencyFormat.format(_totalExpenses),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseItem(Expense e) {
    final ikonRenk = _getExpenseColor(e.tur);
    return Container(
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ikonRenk.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ikonRenk.withValues(alpha: 0.35)),
              ),
              child: Icon(_getExpenseIcon(e.tur),
                  size: 16, color: ikonRenk),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getExpenseLabel(e.tur),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (e.aciklama != null) ...[
                    const SizedBox(height: 2),
                    Text(e.aciklama!,
                        style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppTheme.textSecondary)),
                  ],
                ],
              ),
            ),
            Text(
              _currencyFormat.format(e.tutar),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 15),
              color: AppTheme.textMuted,
              tooltip: 'Düzenle',
              constraints:
                  const BoxConstraints(minWidth: 30, minHeight: 30),
              padding: EdgeInsets.zero,
              onPressed: () => _editExpense(e),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 15),
              color: AppTheme.error,
              tooltip: 'Sil',
              constraints:
                  const BoxConstraints(minWidth: 30, minHeight: 30),
              padding: EdgeInsets.zero,
              onPressed: () async {
                try {
                  await _expenseService.deleteExpense(e.id!);
                  _loadExpenses();
                } catch (err) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppError.from(err, ctx: 'Gider silinemedi')),
                        backgroundColor: AppTheme.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Yardımcı widget'lar ────────────────────────────────────────────

  Widget _card({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required Widget child,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppTheme.border),
          Padding(
            padding: const EdgeInsets.all(18),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _sectionDivider(
      String title, IconData icon, Color color, Color bg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: AppTheme.border)),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {Color? valueColor,
      bool bold = false,
      TextStyle? valueStyle,
      Widget? valueWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textMuted)),
          valueWidget ??
              Text(
                value,
                style: valueStyle ??
                    GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: bold
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: valueColor ?? AppTheme.textPrimary,
                    ),
              ),
        ],
      ),
    );
  }

  Widget _statusBadge(String durum) {
    Color bg, textColor;
    String label;
    IconData icon;
    switch (durum) {
      case 'satildi':
        bg = AppTheme.successBg;
        textColor = AppTheme.successText;
        label = 'Satıldı';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'rezerve':
        bg = AppTheme.warningBg;
        textColor = AppTheme.warning;
        label = 'Rezerve';
        icon = Icons.schedule_rounded;
        break;
      default:
        bg = AppTheme.primaryLight;
        textColor = AppTheme.primaryDark;
        label = 'Stokta';
        icon = Icons.inventory_2_outlined;
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: textColor)),
        ],
      ),
    );
  }

  IconData _getExpenseIcon(String tur) {
    switch (tur) {
      case 'bakim':   return Icons.build_outlined;
      case 'boya':    return Icons.format_paint_outlined;
      case 'sigorta': return Icons.security_outlined;
      case 'vergi':   return Icons.receipt_outlined;
      default:        return Icons.money_off_outlined;
    }
  }

  // Gider türüne göre renk — ikon arka planı ve tonu için
  Color _getExpenseColor(String tur) {
    switch (tur) {
      case 'bakim':   return const Color(0xFF0891B2); // cyan-600  — mekanik
      case 'boya':    return const Color(0xFF7C3AED); // violet-600 — estetik
      case 'sigorta': return const Color(0xFF059669); // green-600  — güvence
      case 'vergi':   return const Color(0xFFD97706); // amber-600  — resmi
      default:        return const Color(0xFF64748B); // slate-500  — diğer
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
