import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase oturumunu platformun güvenli kimlik bilgisi kasasında saklar.
///
/// İlk açılışta eski SharedPreferences oturumunu taşıyarak kullanıcıların
/// güvenlik güncellemesinden sonra yeniden giriş yapmak zorunda kalmasını önler.
class SecureSessionStorage extends LocalStorage {
  static const _sessionKey = 'galeripro_supabase_session_v1';

  final String legacySessionKey;

  const SecureSessionStorage({required this.legacySessionKey});

  FlutterSecureStorage get _storage => const FlutterSecureStorage();

  @override
  Future<void> initialize() async {
    if (await _storage.containsKey(key: _sessionKey)) return;

    final preferences = await SharedPreferences.getInstance();
    final legacySession = preferences.getString(legacySessionKey);
    if (legacySession == null || legacySession.isEmpty) return;

    await _storage.write(key: _sessionKey, value: legacySession);
    await preferences.remove(legacySessionKey);
  }

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _sessionKey);

  @override
  Future<String?> accessToken() => _storage.read(key: _sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _sessionKey, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _sessionKey);
}

class SecurePkceStorage extends GotrueAsyncStorage {
  static const _prefix = 'galeripro_pkce_';

  const SecurePkceStorage();

  FlutterSecureStorage get _storage => const FlutterSecureStorage();

  @override
  Future<String?> getItem({required String key}) =>
      _storage.read(key: '$_prefix$key');

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: '$_prefix$key', value: value);

  @override
  Future<void> removeItem({required String key}) =>
      _storage.delete(key: '$_prefix$key');
}
