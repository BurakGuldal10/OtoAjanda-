import 'package:flutter_test/flutter_test.dart';
import 'package:oto_galeri_app/utils/format_utils.dart';

void main() {
  // ── tutarCevir: tutar metnini güvenli sayıya çevirme ───────────────
  group('tutarCevir', () {
    test('düz tam sayıyı ayrıştırır', () {
      expect(tutarCevir('150000'), 150000);
    });

    test('Türkçe virgüllü ondalığı ayrıştırır', () {
      expect(tutarCevir('1500,50'), 1500.5);
    });

    test('noktalı ondalığı ayrıştırır', () {
      expect(tutarCevir('1500.50'), 1500.5);
    });

    test('para simgesi ve boşlukları yok sayar', () {
      expect(tutarCevir(' 250000 ₺ '), 250000);
    });

    test('boş metin null döner', () {
      expect(tutarCevir(''), isNull);
      expect(tutarCevir('   '), isNull);
    });

    test('geçersiz metin null döner (istisna atmaz)', () {
      expect(tutarCevir('abc'), isNull);
      expect(tutarCevir('12a34'), isNull);
    });

    test('negatif değer null döner', () {
      expect(tutarCevir('-500'), isNull);
    });

    test('sıfır geçerli bir değerdir', () {
      expect(tutarCevir('0'), 0);
    });
  });

  // ── gecerliYilSec: DropdownButton yıl çökmesini önleme ─────────────
  group('gecerliYilSec', () {
    test('seçili yıl listede varsa aynen döner', () {
      expect(gecerliYilSec([2023, 2024, 2025], 2024), 2024);
    });

    test('seçili yıl listede yoksa en güncel yılı döner', () {
      // Asıl çökme senaryosu: kullanıcı 2026'da ama veri yalnızca eski yıllarda
      expect(gecerliYilSec([2023, 2024], 2026), 2024);
    });

    test('mevcut yıllar boşsa seçili yıl aynen döner', () {
      expect(gecerliYilSec([], 2026), 2026);
    });

    test('tek elemanlı liste', () {
      expect(gecerliYilSec([2025], 2026), 2025);
    });
  });
}
