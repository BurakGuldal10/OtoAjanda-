/// Saf (UI'dan bağımsız) biçimlendirme / ayrıştırma yardımcıları.
///
/// Bu dosya bilinçli olarak `dart:io`, Supabase veya Flutter widget'larına
/// bağımlı DEĞİLDİR — böylece birim testlerinde (Visual Studio araç zinciri
/// gerekmeden) doğrudan test edilebilir.
library;

/// Kullanıcının girdiği tutar metnini güvenli şekilde sayıya çevirir.
///
/// - Türkçe ve uluslararası binlik/ondalık ayırıcıları desteklenir
///   (`150.000`, `1.250,50`, `1,250.50`)
/// - Para simgesi (`₺`) ve boşluklar yok sayılır
/// - Boş, geçersiz ya da negatif değerde `null` döner (asla istisna atmaz)
double? tutarCevir(String raw) {
  final temiz = raw
      .trim()
      .replaceAll('₺', '')
      .replaceAll(' ', '')
      .replaceAll('\u00A0', '');
  if (temiz.isEmpty || temiz.startsWith('-')) return null;

  final normalizeEdilmis = _tutarNormalizeEt(temiz);
  if (normalizeEdilmis == null) return null;

  final deger = double.tryParse(normalizeEdilmis);
  if (deger == null || deger < 0) return null;
  return deger;
}

String? _tutarNormalizeEt(String raw) {
  if (!RegExp(r'^[0-9.,]+$').hasMatch(raw)) return null;

  final sonVirgul = raw.lastIndexOf(',');
  final sonNokta = raw.lastIndexOf('.');

  if (sonVirgul >= 0 && sonNokta >= 0) {
    final ondalikAyrac = sonVirgul > sonNokta ? ',' : '.';
    final binlikAyrac = ondalikAyrac == ',' ? '.' : ',';
    return raw.replaceAll(binlikAyrac, '').replaceAll(ondalikAyrac, '.');
  }

  if (sonVirgul >= 0) return _tekAyracNormalizeEt(raw, ',');
  if (sonNokta >= 0) return _tekAyracNormalizeEt(raw, '.');
  return raw;
}

String? _tekAyracNormalizeEt(String raw, String ayrac) {
  final parcalar = raw.split(ayrac);
  if (parcalar.any((p) => p.isEmpty)) return null;

  if (parcalar.length > 2) {
    final binlikMi =
        parcalar.first.length <= 3 &&
        parcalar.skip(1).every((p) => p.length == 3);
    return binlikMi ? parcalar.join() : null;
  }

  final tam = parcalar.first;
  final kusuratVeyaBinlik = parcalar.last;
  if (kusuratVeyaBinlik.length == 3 && tam.length <= 3) {
    return parcalar.join();
  }

  return '$tam.$kusuratVeyaBinlik';
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
