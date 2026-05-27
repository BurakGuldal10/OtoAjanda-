import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uygulamadaki tüm hataları Türkçe, kullanıcı dostu mesajlara çevirir.
///
/// Kullanım:
///   AppError.from(e, ctx: 'Araç kaydedilemedi')
///   AppError.auth(e)
class AppError {
  /// Veritabanı / genel işlem hataları.
  /// [ctx] — hangi işlem başarısız oldu (örn. "Araç kaydedilemedi")
  static String from(dynamic error, {String? ctx}) {
    final prefix = ctx != null ? '$ctx.\n' : '';

    // ── Null check (oturum kapandıysa currentUser! patlar) ───────
    if (error is TypeError ||
        error.toString().contains('Null check operator used on a null value') ||
        error.toString().contains('is not a subtype')) {
      return '${prefix}Oturumunuz sona ermiş. Lütfen uygulamayı kapatıp yeniden açın ve tekrar giriş yapın.'; // ignore: unnecessary_brace_in_string_interps
    }

    // ── Sayı/format dönüşüm hatası ───────────────────────────────
    if (error is FormatException ||
        error.toString().contains('FormatException') ||
        error.toString().contains('Invalid double') ||
        error.toString().contains('Invalid int')) {
      return '${prefix}Sayısal alanlarda geçersiz değer var. Fiyat ve kilometre alanlarını kontrol edin.'; // ignore: unnecessary_brace_in_string_interps
    }

    // ── Supabase AuthException ───────────────────────────────────
    if (error is AuthException) {
      return prefix + _authMessage(error.message, error.statusCode);
    }

    // ── Supabase PostgrestException ──────────────────────────────
    if (error is PostgrestException) {
      return prefix + _postgrestMessage(error);
    }

    // ── Ağ / IO hataları ────────────────────────────────────────
    if (error is SocketException) {
      return '${prefix}İnternet bağlantınızı kontrol edin ve tekrar deneyin.'; // ignore: unnecessary_brace_in_string_interps
    }

    // ── String tabanlı fallback ──────────────────────────────────
    return prefix + _fallback(error.toString().toLowerCase());
  }

  /// Auth işlemleri (giriş, kayıt) için.
  static String auth(dynamic error) {
    if (error is TypeError ||
        error.toString().contains('Null check operator')) {
      return 'Bir kimlik doğrulama hatası oluştu. Uygulamayı yeniden başlatın.';
    }
    if (error is AuthException) {
      return _authMessage(error.message, error.statusCode);
    }
    if (error is SocketException) {
      return 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
    }
    return _fallback(error.toString().toLowerCase());
  }

  // ── Auth mesajları ─────────────────────────────────────────────

  static String _authMessage(String message, String? statusCode) {
    final m = message.toLowerCase();

    if (m.contains('email not confirmed') ||
        m.contains('email_not_confirmed')) {
      return 'E-posta adresiniz henüz onaylanmamış.\n'
          'Çözüm: Supabase paneli → Authentication → Settings → '
          '"Enable email confirmations" seçeneğini kapatın.';
    }
    if (m.contains('invalid login credentials') ||
        m.contains('invalid_credentials') ||
        m.contains('wrong password') ||
        m.contains('user not found')) {
      return 'E-posta adresi veya şifre hatalı.\n'
          'Bilgilerinizi kontrol edip tekrar deneyin.';
    }
    if (m.contains('email login') ||
        m.contains('email logins are disabled') ||
        m.contains('provider is not enabled') ||
        statusCode == '422') {
      return 'E-posta girişi devre dışı.\n'
          'Çözüm: Supabase paneli → Authentication → Providers → '
          'Email → "Enable" seçeneğini aktif edin.';
    }
    if (m.contains('signups not allowed') ||
        m.contains('signup_disabled')) {
      return 'Yeni kayıt şu an kapalı.\n'
          'Çözüm: Supabase paneli → Authentication → Settings → '
          '"Enable signups" seçeneğini aktif edin.';
    }
    if (m.contains('user already registered') ||
        m.contains('already exists') ||
        m.contains('email_exists')) {
      return 'Bu e-posta adresiyle zaten bir hesap var.\n'
          'Giriş yapmayı deneyin ya da farklı bir e-posta kullanın.';
    }
    if (m.contains('weak password') || m.contains('password should be')) {
      return 'Şifre çok kısa. En az 6 karakter kullanın.';
    }
    if (m.contains('rate limit') ||
        m.contains('too many requests') ||
        statusCode == '429') {
      return 'Çok fazla deneme yapıldı. Birkaç dakika bekleyip tekrar deneyin.';
    }
    if (m.contains('jwt expired') || m.contains('token expired')) {
      return 'Oturumunuzun süresi dolmuş. Lütfen tekrar giriş yapın.';
    }
    if (m.contains('oturumunuz bulunamadı') ||
        m.contains('session not found') ||
        m.contains('no session')) {
      return 'Oturumunuz bulunamadı. Lütfen tekrar giriş yapın.';
    }
    if (m.contains('invalid email') ||
        m.contains('email_address_invalid')) {
      return 'Geçersiz e-posta adresi. Lütfen doğru bir adres girin.';
    }
    if (statusCode != null && statusCode.startsWith('5')) {
      return 'Supabase sunucu hatası. Birkaç dakika bekleyip tekrar deneyin.';
    }
    return 'Kimlik doğrulama başarısız. Lütfen tekrar deneyin.';
  }

  // ── PostgrestException mesajları ───────────────────────────────

  static String _postgrestMessage(PostgrestException e) {
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();

    switch (code) {
      case '23505': // Benzersizlik ihlali
        if (msg.contains('plaka') || msg.contains('plate')) {
          return 'Bu plaka numarası zaten kayıtlı.\n'
              'Farklı bir plaka girin ya da mevcut kaydı düzenleyin.';
        }
        return 'Bu kayıt zaten mevcut. Lütfen bilgileri kontrol edin.';

      case '23502': // Zorunlu alan null
        return 'Zorunlu alanlar boş bırakılamaz.\n'
            'Plaka, marka, model ve alış fiyatı zorunludur.';

      case '23503': // Yabancı anahtar ihlali
        return 'İlişkili kayıt bulunamadı.\n'
            'Lütfen sayfayı yenileyip tekrar deneyin.';

      case '23514': // Check constraint
        return 'Girilen değer geçerli aralık dışında.\n'
            'Lütfen alanlara mantıklı değerler girin.';

      case '22P02': // Geçersiz veri tipi
        return 'Sayısal alanlarda geçersiz değer.\n'
            'Fiyat ve kilometre alanlarına yalnızca rakam girin.';

      case '42501': // RLS - yetersiz izin
        return 'Veritabanı erişim hatası (RLS politikası).\n'
            'Çözüm: Supabase paneli → Table Editor → vehicles tablosu → '
            'RLS Policies bölümünde INSERT/UPDATE/DELETE politikalarını kontrol edin.';

      case 'PGRST116': // Kayıt bulunamadı
        return 'Kayıt bulunamadı. Silinmiş ya da taşınmış olabilir.';

      case 'PGRST301': // JWT süresi doldu
        return 'Oturumunuzun süresi dolmuş. Lütfen tekrar giriş yapın.';

      case 'PGRST204': // Sütun bulunamadı
        return 'Veritabanı yapısı uyumsuz.\n'
            'Supabase panelinde tablo yapısını kontrol edin.';
    }

    // Kod eşleşmedi — mesaj içeriğine bak
    if (msg.contains('row-level security') || msg.contains('policy')) {
      return 'Veritabanı erişim izni reddedildi (RLS).\n'
          'Çözüm: Supabase paneli → Table Editor → ilgili tablo → '
          'RLS Policies bölümünü kontrol edin.';
    }
    if (msg.contains('duplicate') || msg.contains('unique')) {
      return 'Bu kayıt zaten mevcut. Lütfen bilgileri kontrol edin.';
    }
    if (msg.contains('not found') || msg.contains('no rows')) {
      return 'Kayıt bulunamadı. Silinmiş ya da taşınmış olabilir.';
    }
    if (msg.contains('permission denied') || msg.contains('insufficient')) {
      return 'Bu işlem için yetkiniz yok.\n'
          'Supabase panelinde tablo izinlerini kontrol edin.';
    }
    if (msg.contains('connection') || msg.contains('network')) {
      return 'Veritabanı bağlantı hatası. İnternet bağlantınızı kontrol edin.';
    }

    return 'Veritabanı işlemi başarısız oldu.\n'
        'Lütfen bilgileri kontrol edip tekrar deneyin.';
  }

  // ── String fallback ────────────────────────────────────────────

  static String _fallback(String msg) {
    if (msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection refused') ||
        msg.contains('network is unreachable')) {
      return 'İnternet bağlantısı yok. Bağlantınızı kontrol edip tekrar deneyin.';
    }
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return 'Sunucu yanıt vermedi. İnternetinizi kontrol edip tekrar deneyin.';
    }
    if (msg.contains('jwt expired') || msg.contains('not authenticated')) {
      return 'Oturumunuzun süresi dolmuş. Lütfen tekrar giriş yapın.';
    }
    if (msg.contains('internal server error') ||
        msg.contains('service unavailable')) {
      return 'Supabase sunucusunda geçici bir sorun var. Birkaç dakika bekleyip deneyin.';
    }
    if (msg.contains('excel') || msg.contains('file')) {
      return 'Dosya oluşturulamadı. İndirilenler klasörüne yazma izni olduğundan emin olun.';
    }
    return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
  }
}
