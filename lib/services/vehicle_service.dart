import '../config/supabase_config.dart';
import '../models/vehicle.dart';

class VehicleService {
  final _client = SupabaseConfig.client;

  String get _userId => _client.auth.currentUser!.id;

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

    return Vehicle.fromJson(response);
  }

  // Araç güncelle
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    final response = await _client
        .from('vehicles')
        .update(vehicle.toJson())
        .eq('id', vehicle.id!)
        .select()
        .single();

    return Vehicle.fromJson(response);
  }

  // Araç sil
  Future<void> deleteVehicle(String id) async {
    await _client.from('vehicles').delete().eq('id', id);
  }

  // Araç sat
  Future<Vehicle> sellVehicle({
    required String vehicleId,
    required double satisFiyati,
    required DateTime satisTarihi,
  }) async {
    final response = await _client
        .from('vehicles')
        .update({
          'satis_fiyati': satisFiyati,
          'satis_tarihi': satisTarihi.toIso8601String().split('T').first,
          'durum': 'satildi',
        })
        .eq('id', vehicleId)
        .select()
        .single();

    return Vehicle.fromJson(response);
  }

  // İstatistikler
  Future<Map<String, dynamic>> getStats() async {
    final vehicles = await getVehicles();

    final stokta = vehicles.where((v) => v.durum == 'stokta').toList();
    final satilan = vehicles.where((v) => v.durum == 'satildi').toList();

    double toplamKar = 0;
    double toplamYatirim = 0;

    for (var v in satilan) {
      if (v.kar != null) toplamKar += v.kar!;
    }

    for (var v in stokta) {
      toplamYatirim += v.alisFiyati;
    }

    return {
      'stoktaAdet': stokta.length,
      'satilanAdet': satilan.length,
      'toplamKar': toplamKar,
      'toplamYatirim': toplamYatirim,
      'toplamArac': vehicles.length,
    };
  }
}
