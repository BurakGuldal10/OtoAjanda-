import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/expense.dart';
import 'local_backup_service.dart';

class ExpenseService {
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

  // Araca ait giderleri getir
  Future<List<Expense>> getExpenses(String vehicleId) async {
    final response = await _client
        .from('expenses')
        .select()
        .eq('vehicle_id', vehicleId)
        .eq('user_id', _userId)
        .order('tarih', ascending: false);

    return (response as List).map((e) => Expense.fromJson(e)).toList();
  }

  // Gider ekle
  Future<Expense> addExpense(Expense expense) async {
    final response = await _client
        .from('expenses')
        .insert(expense.toJson())
        .select()
        .single();

    final saved = Expense.fromJson(response);
    LocalBackupService.triggerBackup(_userId).ignore();
    return saved;
  }

  // Gider güncelle
  Future<Expense> updateExpense(Expense expense) async {
    final userId = _userId;
    final response = await _client
        .from('expenses')
        .update(expense.toJson(forUpdate: true))
        .eq('id', expense.id!)
        .eq('user_id', userId)
        .select()
        .single();

    final saved = Expense.fromJson(response);
    LocalBackupService.triggerBackup(userId).ignore();
    return saved;
  }

  // Gider sil
  Future<void> deleteExpense(String id) async {
    final userId = _userId;
    await _client.from('expenses').delete().eq('id', id).eq('user_id', userId);
    LocalBackupService.triggerBackup(userId).ignore();
  }

  // Araca ait toplam gider
  Future<double> getTotalExpenses(String vehicleId) async {
    final expenses = await getExpenses(vehicleId);
    return expenses.fold<double>(0.0, (sum, e) => sum + e.tutar);
  }

  // Birden fazla araç için toplam giderleri vehicle_id bazında getir
  Future<Map<String, double>> getTotalExpensesByVehicles(
    List<String> vehicleIds,
  ) async {
    if (vehicleIds.isEmpty) return {};
    final response = await _client
        .from('expenses')
        .select('vehicle_id, tutar')
        .eq('user_id', _userId)
        .inFilter('vehicle_id', vehicleIds);

    final result = <String, double>{};
    for (final e in (response as List)) {
      final vid = e['vehicle_id'] as String;
      result[vid] = (result[vid] ?? 0) + (e['tutar'] as num).toDouble();
    }
    return result;
  }
}
