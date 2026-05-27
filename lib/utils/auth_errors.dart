/// Supabase auth hatalarını kullanıcı dostu Türkçe mesajlara çevirir.
String friendlyAuthError(dynamic error) {
  final msg = error.toString().toLowerCase();

  // E-posta onayı
  if (msg.contains('email not confirmed') ||
      msg.contains('email_not_confirmed')) {
    return 'E-posta adresiniz henüz onaylanmamış.\n'
        'Supabase panelinden "Email confirmations" seçeneğini kapatın veya gelen kutunuzu kontrol edin.';
  }

  // Yanlış e-posta / şifre
  if (msg.contains('invalid login credentials') ||
      msg.contains('invalid_credentials') ||
      msg.contains('wrong password') ||
      msg.contains('user not found')) {
    return 'E-posta adresi veya şifre hatalı.\nLütfen bilgilerinizi kontrol edip tekrar deneyin.';
  }

  // E-posta girişi devre dışı (422)
  if (msg.contains('email login') ||
      msg.contains('email logins are disabled') ||
      msg.contains('provider is not enabled') ||
      msg.contains('statuscode: 422')) {
    return 'E-posta ile giriş şu an devre dışı.\n'
        'Supabase paneli → Authentication → Providers → Email bölümünden aktif edin.';
  }

  // Kayıt kapalı
  if (msg.contains('signups not allowed') ||
      msg.contains('signup_disabled')) {
    return 'Yeni kayıt şu an kapalı. Lütfen daha sonra tekrar deneyin.';
  }

  // Hesap zaten mevcut
  if (msg.contains('user already registered') ||
      msg.contains('already exists') ||
      msg.contains('email_exists')) {
    return 'Bu e-posta adresiyle zaten bir hesap mevcut.\nGiriş yapmayı deneyin.';
  }

  // Zayıf şifre
  if (msg.contains('weak password') ||
      msg.contains('password should be') ||
      msg.contains('at least')) {
    return 'Şifreniz çok zayıf. En az 6 karakter kullanın.';
  }

  // Rate limit (çok fazla deneme)
  if (msg.contains('rate limit') ||
      msg.contains('too many requests') ||
      msg.contains('statuscode: 429')) {
    return 'Çok fazla deneme yaptınız. Lütfen birkaç dakika bekleyip tekrar deneyin.';
  }

  // Ağ hatası
  if (msg.contains('socketexception') ||
      msg.contains('network') ||
      msg.contains('connection') ||
      msg.contains('failed host lookup')) {
    return 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
  }

  // Geçersiz e-posta formatı
  if (msg.contains('invalid email') ||
      msg.contains('email_address_invalid')) {
    return 'Geçersiz e-posta adresi. Lütfen doğru bir adres girin.';
  }

  // Supabase sunucu hatası
  if (msg.contains('statuscode: 5') || msg.contains('server error')) {
    return 'Sunucu hatası oluştu. Lütfen birkaç dakika sonra tekrar deneyin.';
  }

  // Bilinmeyen hata — teknik detayı gizle, genel mesaj ver
  return 'Bir hata oluştu. Lütfen bilgilerinizi kontrol edip tekrar deneyin.';
}
