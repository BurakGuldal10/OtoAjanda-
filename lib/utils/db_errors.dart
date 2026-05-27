/// Supabase / PostgreSQL hatalarını kullanıcı dostu Türkçe mesajlara çevirir.
/// [context] — hangi işlem yapılıyordu (örn. "Araç kaydedilemedi")
String friendlyDbError(dynamic error, {String? context}) {
  final msg = error.toString().toLowerCase();
  final p = context != null ? '$context.\n' : '';

  // ── Ağ / Bağlantı hataları ───────────────────────────────────────
  if (msg.contains('socketexception') ||
      msg.contains('failed host lookup') ||
      msg.contains('network is unreachable') ||
      msg.contains('connection refused')) {
    return '${p}İnternet bağlantınızı kontrol edin ve tekrar deneyin.'; // ignore: unnecessary_brace_in_string_interps
  }

  if (msg.contains('timeout') || msg.contains('timed out')) {
    return '${p}Sunucu yanıt vermedi. İnternet bağlantınızı kontrol edip tekrar deneyin.';
  }

  // ── Yetki / Oturum hataları ──────────────────────────────────────
  if (msg.contains('jwt expired') ||
      msg.contains('pgrst301') ||
      msg.contains('not authenticated') ||
      msg.contains('invalid jwt')) {
    return '${p}Oturumunuzun süresi dolmuş. Lütfen tekrar giriş yapın.';
  }

  if (msg.contains('42501') ||
      msg.contains('insufficient privilege') ||
      msg.contains('row-level security') ||
      msg.contains('rls')) {
    return '${p}Bu işlem için yetkiniz yok. Lütfen tekrar giriş yapın.';
  }

  // ── Benzersizlik ihlali (duplicate) ─────────────────────────────
  if (msg.contains('23505') ||
      msg.contains('unique') ||
      msg.contains('duplicate key') ||
      msg.contains('already exists')) {
    if (msg.contains('plaka') || msg.contains('plate')) {
      return '${p}Bu plaka numarası zaten kayıtlı. Farklı bir plaka girin.';
    }
    return '${p}Bu kayıt zaten mevcut. Lütfen bilgileri kontrol edin.';
  }

  // ── Zorunlu alan boş ────────────────────────────────────────────
  if (msg.contains('23502') ||
      msg.contains('not-null') ||
      msg.contains('null value') ||
      msg.contains('violates not-null')) {
    return '${p}Zorunlu alanlar boş bırakılamaz. Lütfen tüm alanları doldurun.';
  }

  // ── Yabancı anahtar ihlali ───────────────────────────────────────
  if (msg.contains('23503') || msg.contains('foreign key')) {
    return '${p}İlişkili bir kayıt bulunamadı. Lütfen sayfayı yenileyip tekrar deneyin.'; // ignore: unnecessary_brace_in_string_interps
  }

  // ── Kayıt bulunamadı ────────────────────────────────────────────
  if (msg.contains('pgrst116') ||
      msg.contains('no rows') ||
      msg.contains('not found')) {
    return '${p}Kayıt bulunamadı. Silinmiş ya da taşınmış olabilir.';
  }

  // ── Geçersiz veri tipi ───────────────────────────────────────────
  if (msg.contains('22p02') ||
      msg.contains('invalid input syntax') ||
      msg.contains('invalid value')) {
    return '${p}Girilen değer geçersiz. Lütfen sayısal alanlara sadece rakam girin.';
  }

  // ── Sunucu / Supabase hataları ───────────────────────────────────
  if (msg.contains('500') ||
      msg.contains('internal server error') ||
      msg.contains('service unavailable') ||
      msg.contains('503')) {
    return '${p}Sunucu hatası oluştu. Lütfen birkaç dakika bekleyip tekrar deneyin.';
  }

  if (msg.contains('postgrestexception') || msg.contains('supabase')) {
    return '${p}Veritabanı işlemi başarısız oldu. Lütfen tekrar deneyin.';
  }

  // ── Bilinmeyen hata ──────────────────────────────────────────────
  return '${p}Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
}
