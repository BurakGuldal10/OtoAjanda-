import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/vehicle.dart';
import 'local_backup_service.dart';

class VehicleService {
  final _client = SupabaseConfig.client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException(
        'Oturumunuz bulunamadı. Lütfen tekrar giriş yapın.',
      );
    }
    return user.id;
  }

  // Tüm araçları getir
  Future<List<Vehicle>> getVehicles() async {
    final response = await _client
        .from('vehicles')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Vehicle.fromJson(e)).toList();
  }

  // Durama göre araçları getir
  Future<List<Vehicle>> getVehiclesByStatus(String durum) async {
    final response = await _client
        .from('vehicles')
        .select()
        .eq('user_id', _userId)
        .eq('durum', durum)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Vehicle.fromJson(e)).toList();
  }

  // Araç ekle
  Future<Vehicle> addVehicle(Vehicle vehicle) async {
    final response = await _client
        .from('vehicles')
        .insert(vehicle.toJson())
        .select()
        .single();

    final saved = Vehicle.fromJson(response);
    LocalBackupService.triggerBackup(_userId).ignore();
    return saved;
  }

  // Araç güncelle
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    final response = await _client
        .from('vehicles')
        .update(vehicle.toJson(forUpdate: true))
        .eq('id', vehicle.id!)
        .select()
        .single();

    final saved = Vehicle.fromJson(response);
    LocalBackupService.triggerBackup(_userId).ignore();
    return saved;
  }

  // Araç sil
  Future<void> deleteVehicle(String id) async {
    await _client.from('vehicles').delete().eq('id', id);
    LocalBackupService.triggerBackup(_userId).ignore();
  }

  // Araç durumunu güncelle (stokta ↔ rezerve)
  Future<Vehicle> updateStatus(String vehicleId, String durum) async {
    final response = await _client
        .from('vehicles')
        .update({'durum': durum})
        .eq('id', vehicleId)
        .select()
        .single();

    final saved = Vehicle.fromJson(response);
    LocalBackupService.triggerBackup(_userId).ignore();
    return saved;
  }

  // Araç sat
  Future<Vehicle> sellVehicle({
    required String vehicleId,
    required double satisFiyati,
    required DateTime satisTarihi,
    String? aliciAdi,
    String? aliciTelefon,
    String? aliciAdres,
  }) async {
    final response = await _client
        .from('vehicles')
        .update({
          'satis_fiyati': satisFiyati,
          'satis_tarihi': satisTarihi.toIso8601String().split('T').first,
          'durum': 'satildi',
          'alici_adi': aliciAdi,
          'alici_telefon': aliciTelefon,
          'alici_adres': aliciAdres,
        })
        .eq('id', vehicleId)
        .select()
        .single();

    final saved = Vehicle.fromJson(response);
    LocalBackupService.triggerBackup(_userId).ignore();
    return saved;
  }

  // İstatistikler
  Future<Map<String, dynamic>> getStats() async {
    final vehicles = await getVehicles();

    final stokta = vehicles.where((v) => v.durum == 'stokta').toList();
    final rezerve = vehicles.where((v) => v.durum == 'rezerve').toList();
    final satilan = vehicles.where((v) => v.durum == 'satildi').toList();

    double brutKar = 0;
    double toplamYatirim = 0;
    double toplamGider = 0;

    for (var v in satilan) {
      if (v.kar != null) brutKar += v.kar!;
    }

    // Stok yatırımına hem stokta hem rezerve araçlar dahil
    for (var v in [...stokta, ...rezerve]) {
      toplamYatirim += v.alisFiyati;
    }

    if (satilan.isNotEmpty) {
      final satilanIds = satilan.map((v) => v.id!).toList();
      final expensesResponse = await _client
          .from('expenses')
          .select('tutar')
          .eq('user_id', _userId)
          .inFilter('vehicle_id', satilanIds);

      for (final e in (expensesResponse as List)) {
        toplamGider += (e['tutar'] as num).toDouble();
      }
    }

    return {
      'stoktaAdet': stokta.length,
      'rezerveAdet': rezerve.length,
      'satilanAdet': satilan.length,
      'brutKar': brutKar,
      'toplamGider': toplamGider,
      'toplamKar': brutKar - toplamGider,
      'toplamYatirim': toplamYatirim,
      'toplamArac': vehicles.length,
    };
  }
}
