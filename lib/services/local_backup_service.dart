import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../config/supabase_config.dart';
import '../models/expense.dart';
import '../models/vehicle.dart';

/// Araç ve gider verilerinin yerel JSON yedeğini yönetir.
/// DB işlemlerinden sonra arka planda çağrılır; hata uygulamayı durdurmaz.
///
/// Platform bazlı yedek konumları:
///   Windows : Documents\GaleriPro\yedek.json
///   macOS   : Documents/GaleriPro/yedek.json
///   Linux   : Documents/GaleriPro/yedek.json
///   Android : /sdcard/Android/data/PAKET/files/GaleriPro/yedek.json  (dosya yöneticisinden erişilebilir)
///   iOS     : Uygulama Documents dizini (Files uygulamasından erişilebilir)
class LocalBackupService {
  static final _client = SupabaseConfig.client;

  static const _appFolder = 'GaleriPro';
  static const _fileName = 'yedek.json';

  // ── Dizin seçimi ──────────────────────────────────────────────────

  static Future<Directory> _backupDir() async {
    final Directory baseDir;

    if (Platform.isAndroid) {
      // Android: harici uygulama dizini — dosya yöneticisinde görünür,
      // API 29+ için izin gerekmez (uygulama özel alan).
      // Harici depolama yoksa (emülatör vb.) dahili dizine düşer.
      baseDir = (await getExternalStorageDirectory()) ??
          await getApplicationDocumentsDirectory();
    } else {
      // iOS     : Files uygulamasından erişilebilir (Info.plist ile etkinleştirildi)
      // Windows : C:\Users\USERNAME\Documents\
      // macOS   : /Users/USERNAME/Documents/
      // Linux   : /home/USERNAME/Documents/
      baseDir = await getApplicationDocumentsDirectory();
    }

    final dir = Directory(
      [baseDir.path, _appFolder].join(Platform.pathSeparator),
    );
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Yedek dosyasının tam yolunu döndürür (bilgi / ayarlar ekranı için).
  static Future<String> getBackupFilePath() async {
    final dir = await _backupDir();
    return [dir.path, _fileName].join(Platform.pathSeparator);
  }

  // ── Dışarıdan çağrılan tek metot ─────────────────────────────────

  /// DB'den tüm veriyi çekip yerel dosyaya yazar.
  /// Hata olursa sessizce geçer — yedek hiçbir zaman ana akışı kesmez.
  static Future<void> triggerBackup(String userId) async {
    try {
      final vehiclesRaw = await _client
          .from('vehicles')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final expensesRaw = await _client
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .order('tarih', ascending: false);

      final vehicles =
          (vehiclesRaw as List).map((e) => Vehicle.fromJson(e)).toList();
      final expenses =
          (expensesRaw as List).map((e) => Expense.fromJson(e)).toList();

      await _writeSnapshot(
        userId: userId,
        vehicles: vehicles,
        expenses: expenses,
      );
    } catch (_) {
      // Yedek hatası uygulamayı durdurmamalı
    }
  }

  // ── İç yazma mantığı ─────────────────────────────────────────────

  static Future<void> _writeSnapshot({
    required String userId,
    required List<Vehicle> vehicles,
    required List<Expense> expenses,
  }) async {
    final filePath = await getBackupFilePath();

    final snapshot = {
      'versiyon': 1,
      'sonGuncelleme': DateTime.now().toIso8601String(),
      'kullaniciId': userId,
      'platform': Platform.operatingSystem,
      'aracSayisi': vehicles.length,
      'giderSayisi': expenses.length,
      'araclar': vehicles
          .map((v) => {
                'id': v.id,
                'kullaniciId': v.userId,
                'plaka': v.plaka,
                'marka': v.marka,
                'model': v.model,
                'yil': v.yil,
                'renk': v.renk,
                'kilometre': v.kilometre,
                'alisFiyati': v.alisFiyati,
                'alisTarihi': v.alisTarihi?.toIso8601String(),
                'satisFiyati': v.satisFiyati,
                'satisTarihi': v.satisTarihi?.toIso8601String(),
                'kar': v.kar,
                'durum': v.durum,
                'notlar': v.notlar,
                'olusturmaTarihi': v.createdAt?.toIso8601String(),
              })
          .toList(),
      'giderler': expenses
          .map((e) => {
                'id': e.id,
                'aracId': e.vehicleId,
                'kullaniciId': e.userId,
                'tur': e.tur,
                'tutar': e.tutar,
                'aciklama': e.aciklama,
                'tarih': e.tarih?.toIso8601String(),
                'olusturmaTarihi': e.createdAt?.toIso8601String(),
              })
          .toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    await File(filePath).writeAsString(encoder.convert(snapshot), flush: true);
  }
}
