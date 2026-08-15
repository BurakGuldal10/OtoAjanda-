import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../config/supabase_config.dart';
import '../models/expense.dart';
import '../models/vehicle.dart';
import '../utils/backup_crypto.dart';

/// Araç ve gider verilerinin şifreli yerel yedeğini yönetir.
/// DB işlemlerinden sonra arka planda çağrılır; hata uygulamayı durdurmaz.
class LocalBackupService {
  static final _client = SupabaseConfig.client;
  static const _secureStorage = FlutterSecureStorage();

  static const _appFolder = 'GaleriPro';
  static const _fileName = 'yedek.gpb';
  static const _legacyFileName = 'yedek.json';
  static const _keyName = 'galeripro_backup_key_v1';

  // ── Dizin seçimi ──────────────────────────────────────────────────

  static Future<Directory> _backupDir() async {
    final baseDir = await getApplicationSupportDirectory();

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

      final vehicles = (vehiclesRaw as List)
          .map((e) => Vehicle.fromJson(e))
          .toList();
      final expenses = (expensesRaw as List)
          .map((e) => Expense.fromJson(e))
          .toList();

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
          .map(
            (v) => {
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
              'saticiAdi': v.saticiAdi,
              'saticiTelefon': v.saticiTelefon,
              'saticiAdres': v.saticiAdres,
              'aliciAdi': v.aliciAdi,
              'aliciTelefon': v.aliciTelefon,
              'aliciAdres': v.aliciAdres,
              'olusturmaTarihi': v.createdAt?.toIso8601String(),
            },
          )
          .toList(),
      'giderler': expenses
          .map(
            (e) => {
              'id': e.id,
              'aracId': e.vehicleId,
              'kullaniciId': e.userId,
              'tur': e.tur,
              'tutar': e.tutar,
              'aciklama': e.aciklama,
              'tarih': e.tarih?.toIso8601String(),
              'olusturmaTarihi': e.createdAt?.toIso8601String(),
            },
          )
          .toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    final encrypted = await _encrypt(utf8.encode(encoder.convert(snapshot)));
    await File(filePath).writeAsString(jsonEncode(encrypted), flush: true);
    await _removeLegacyPlaintextBackup();
  }

  static Future<Map<String, Object>> _encrypt(List<int> plaintext) async {
    final key = await _getOrCreateEncryptionKey();
    final nonce = _randomBytes(12);
    return BackupCrypto.encrypt(
      plaintext: Uint8List.fromList(plaintext),
      key: key,
      nonce: nonce,
    );
  }

  static Future<Uint8List> _getOrCreateEncryptionKey() async {
    final storedKey = await _secureStorage.read(key: _keyName);
    if (storedKey != null) return base64Decode(storedKey);

    final key = _randomBytes(32);
    await _secureStorage.write(key: _keyName, value: base64Encode(key));
    return key;
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Future<void> _removeLegacyPlaintextBackup() async {
    final legacyRoots = <Directory>[await getApplicationDocumentsDirectory()];
    if (Platform.isAndroid) {
      final externalDirectory = await getExternalStorageDirectory();
      if (externalDirectory != null) legacyRoots.add(externalDirectory);
    }

    for (final root in legacyRoots) {
      final legacyFile = File(
        [root.path, _appFolder, _legacyFileName].join(Platform.pathSeparator),
      );
      if (await legacyFile.exists()) await legacyFile.delete();
    }
  }
}
