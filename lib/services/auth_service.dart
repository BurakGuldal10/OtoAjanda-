import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// `signUp` çağrısının sonucunu temsil eder.
/// `needsEmailConfirmation` true ise kullanıcı henüz oturum açmamıştır;
/// önce e-postasını onaylaması gerekir.
class SignUpResult {
  final bool needsEmailConfirmation;
  final User? user;

  const SignUpResult({required this.needsEmailConfirmation, this.user});
}

class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Yeni kullanıcı kaydı oluşturur.
  ///
  /// - `galeri_adi` user_metadata'ya yazılır → DB trigger profil satırını
  ///   oluşturabilir (önerilen kurulum). Trigger yoksa fallback olarak
  ///   bu metot session açık olduğunda profili kendisi ekler.
  /// - Supabase "Confirm email" etkinse session henüz yoktur ve
  ///   `needsEmailConfirmation = true` döner; profil insert yapılmaz.
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String galeriAdi,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'galeri_adi': galeriAdi},
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException(
        'Kayıt oluşturulamadı. Lütfen tekrar deneyin.',
      );
    }

    final needsEmailConfirmation = response.session == null;

    // Sadece otomatik oturum açıldıysa profil ekle (RLS auth.uid() = id bekler).
    // Email onayı bekleniyorsa profil oluşturmayı DB trigger veya ilk login yapar.
    if (!needsEmailConfirmation) {
      try {
        await _client.from('profiles').insert({
          'id': user.id,
          'galeri_adi': galeriAdi,
        });
      } on PostgrestException catch (e) {
        // 23505 = unique violation: trigger zaten oluşturmuş, sorun değil
        if (e.code != '23505') rethrow;
      }
    }

    return SignUpResult(
      needsEmailConfirmation: needsEmailConfirmation,
      user: user,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Lazy profil oluşturma: kayıt sırasında email onayı bekleniyorsa
    // profil oluşmamış olabilir. İlk login'de user_metadata'dan galeri adını
    // alıp profili oluşturalım.
    final user = response.user;
    if (user != null) {
      await _ensureProfile(user);
    }

    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Profil satırı yoksa user_metadata'dan oluşturur. Hata olursa sessiz
  /// geçer — kullanıcı login akışını blokelemesin.
  Future<void> _ensureProfile(User user) async {
    try {
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      if (existing != null) return;

      final galeriAdi =
          (user.userMetadata?['galeri_adi'] as String?)?.trim();
      await _client.from('profiles').insert({
        'id': user.id,
        if (galeriAdi != null && galeriAdi.isNotEmpty) 'galeri_adi': galeriAdi,
      });
    } catch (_) {
      // Profil oluşturulamazsa login devam etsin; UI sonra düzeltir.
    }
  }
}
