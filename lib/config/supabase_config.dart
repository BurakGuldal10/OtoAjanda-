import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/secure_session_storage.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
    final url = dotenv.env['SUPABASE_URL']!;
    final projectRef = Uri.parse(url).host.split('.').first;

    await Supabase.initialize(
      url: url,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(
          legacySessionKey: 'sb-$projectRef-auth-token',
        ),
        pkceAsyncStorage: const SecurePkceStorage(),
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
