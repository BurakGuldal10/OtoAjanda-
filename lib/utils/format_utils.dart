/// Saf (UI'dan bağımsız) biçimlendirme / ayrıştırma yardımcıları.
///
/// Bu dosya bilinçli olarak `dart:io`, Supabase veya Flutter widget'larına
/// bağımlı DEĞİLDİR — böylece birim testlerinde (Visual Studio araç zinciri
/// gerekmeden) doğrudan test edilebilir.
library;

/// Kullanıcının girdiği tutar metnini güvenli şekilde sayıya çevirir.
///
/// - Türkçe ondalık ayırıcı (virgül) `.`'a çevrilir → `1500,50` ⇒ `1500.5`
/// - Para simgesi (`₺`) ve boşluklar yok sayılır
/// - Boş, geçersiz ya da negatif değerde `null` döner (asla istisna atmaz)
double? tutarCevir(String raw) {
  final temiz = raw
      .trim()
      .replaceAll('₺', '')
      .replaceAll(' ', '')
      .replaceAll(',', '.');
  if (temiz.isEmpty) return null;
  final deger = double.tryParse(temiz);
  if (deger == null || deger < 0) return null;
  return deger;
}

/// Seçili yılın, mevcut yıllar listesinde bulunmasını garanti eder.
///
/// `DropdownButton` değeri listede yoksa Flutter assertion ile çöker. Bu
/// fonksiyon, seçili yıl listede yoksa en güncel (son) yılı döndürür.
/// [mevcutYillar] boşsa [seciliYil] aynen döner.
int gecerliYilSec(List<int> mevcutYillar, int seciliYil) {
  if (mevcutYillar.isEmpty) return seciliYil;
  if (mevcutYillar.contains(seciliYil)) return seciliYil;
  return mevcutYillar.last;
}
