import '../config/supabase_config.dart';
import '../models/expense.dart';

class ExpenseService {
  final _client = SupabaseConfig.client;

  String get _userId => _client.auth.currentUser!.id;

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

    return Expense.fromJson(response);
  }

  // Gider sil
  Future<void> deleteExpense(String id) async {
    await _client.from('expenses').delete().eq('id', id);
  }

  // Araca ait toplam gider
  Future<double> getTotalExpenses(String vehicleId) async {
    final expenses = await getExpenses(vehicleId);
    return expenses.fold<double>(0.0, (sum, e) => sum + e.tutar);
  }
}
