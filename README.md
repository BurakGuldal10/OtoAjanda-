# GaleriPro

Oto galeri sahipleri için araç alım-satım takip ve yönetim uygulaması.  
Öncelikli platform **Windows masaüstü**, ilerleyen aşamalarda Android/iOS/Web desteği eklenecek.

## Kurulum

```bash
# Bağımlılıkları yükle
flutter pub get

# .env dosyasını oluştur (.env.example'ı kopyala)
copy .env.example .env
# Supabase URL ve anon key'i .env dosyasına gir

# Uygulamayı çalıştır
flutter run -d windows
```

## Özellikler

- Araç alım-satım kaydı ve durum takibi (Stokta / Rezerve / Satıldı)
- Araç bazlı gider takibi ve net kâr hesabı
- Dashboard, araç listesi ve istatistik ekranları
- Supabase ile bulut yedekleme — tüm veriler güvende
