import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Supabase projenizi oluşturduktan sonra bu değerleri doldurun:
  // https://supabase.com/dashboard → Settings → API
  static const String supabaseUrl = 'https://sfcumafkxhndjuukbodn.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_wmvSQmUZGEwBDYz0GdWuFw_KfFGKlCx';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
