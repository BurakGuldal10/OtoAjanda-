import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Mevcut kullanıcı
  User? get currentUser => _client.auth.currentUser;

  // Auth durumu stream'i
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Kayıt ol
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String galeriAdi,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    // Profil tablosuna ekle
    if (response.user != null) {
      await _client.from('profiles').insert({
        'id': response.user!.id,
        'galeri_adi': galeriAdi,
      });
    }

    return response;
  }

  // Giriş yap
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
