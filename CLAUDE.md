# CLAUDE.md

## Proje Genel Bakış

**GaleriPro** — Oto galeri sahipleri için araç alım-satım takip ve yönetim uygulaması. Öncelikli platform Windows masaüstü, ilerleyen aşamalarda mobil (iOS/Android) desteği eklenecek. Tüm UI metinleri, değişken adları ve yorumlar Türkçedir.

## Komutlar

```bash
# Bağımlılıkları yükle
flutter pub get

# Uygulamayı çalıştır (Windows masaüstü)
flutter run -d windows

# Build
flutter build windows          # Windows EXE
flutter build apk              # Android APK (ileride)
flutter build ios               # iOS (ileride)

# Lint & analiz
flutter analyze

# Testler
flutter test
flutter test test/foo_test.dart
```

## Mimari

### Klasör Yapısı

```
lib/
├── config/
│   └── supabase_config.dart    # Supabase bağlantısı (.env'den okur)
├── models/
│   ├── vehicle.dart            # Araç veri modeli
│   └── expense.dart            # Gider veri modeli
├── screens/
│   ├── auth/
│   │   ├── auth_gate.dart      # Auth yönlendirme (giriş/kayıt/ana ekran)
│   │   ├── login_screen.dart   # Giriş ekranı
│   │   └── register_screen.dart # Kayıt ekranı
│   ├── home/
│   │   └── home_screen.dart    # Ana sayfa (dashboard + yan menü)
│   ├── vehicles/
│   │   ├── vehicle_list_screen.dart   # Araç listesi (DataTable)
│   │   ├── add_vehicle_screen.dart    # Araç ekle/düzenle formu
│   │   └── vehicle_detail_screen.dart # Araç detay (2 sütunlu)
│   └── stats/
│       └── stats_screen.dart   # İstatistikler
└── services/
    ├── auth_service.dart       # Kimlik doğrulama servisi
    ├── vehicle_service.dart    # Araç CRUD servisi
    └── expense_service.dart    # Gider servisi
```

### State Management

Framework kullanılmıyor. Şu yaklaşımlar kullanılıyor:
- **`setState()`** — yerel widget state
- **`StreamBuilder`** — Supabase auth state dinleme

### Backend — Supabase

- Bağlantı bilgileri `.env` dosyasında tutulur (güvenlik)
- `.env.example` referans dosyası mevcut
- `supabase_config.dart` → `flutter_dotenv` ile `.env`'den okur

#### Veritabanı Tabloları

| Tablo | Açıklama |
|-------|----------|
| `profiles` | Kullanıcı profili (galeri adı, telefon, adres) |
| `vehicles` | Araç kayıtları (plaka, marka, model, fiyat, durum) |
| `expenses` | Araç giderleri (bakım, boya, sigorta, vergi) |
| `price_estimates` | Fiyat tahminleri (ileride kullanılacak) |

- **RLS (Row Level Security)** aktif — her kullanıcı sadece kendi verisini görür
- `kar` alanı `GENERATED ALWAYS AS (satis_fiyati - alis_fiyati) STORED` ile otomatik hesaplanır
- `durum` alanı: `stokta`, `satildi`, `rezerve`

### Masaüstü UI Yapısı

- **NavigationRail** (yan menü) — ekran 1100px'den genişse etiketler açılır
- **DataTable** — araç listesinde tablo görünümü
- **2 sütunlu düzen** — araç detayda sol: bilgiler, sağ: giderler
- **3 sütunlu form** — araç ekleme/düzenleme
- **Minimum pencere boyutu**: 900x600 piksel
- Login/Register ekranları maksimum 420px genişlik

## Önemli Dosyalar

| Dosya | Açıklama |
|-------|----------|
| `.env` | Supabase URL ve anon key (git'e gitmez) |
| `.env.example` | `.env` şablonu |
| `windows/runner/main.cpp` | Pencere başlığı ve boyutu |
| `windows/runner/flutter_window.cpp` | Minimum pencere boyutu (WM_GETMINMAXINFO) |

## Temel İsimlendirme Kuralları (Türkçe)

| Türkçe | İngilizce |
|--------|-----------|
| `arac` / `vehicle` | vehicle |
| `plaka` | license plate |
| `marka` | brand |
| `alis_fiyati` | purchase price |
| `satis_fiyati` | sale price |
| `kar` | profit |
| `durum` | status |
| `gider` / `expense` | expense |
| `stokta` | in stock |
| `satildi` | sold |
| `galeri` | gallery/dealership |

## Paketler

| Paket | Kullanım |
|-------|----------|
| `supabase_flutter` | Supabase bağlantısı ve auth |
| `flutter_dotenv` | `.env` dosyasından config okuma |
| `google_fonts` | Font yönetimi |
| `intl` | Tarih ve para formatı (tr_TR) |
| `fl_chart` | Grafikler (ileride kullanılacak) |
| `go_router` | Routing (ileride kullanılacak) |
| `shared_preferences` | Yerel tercihler |

## Gelecek Planlar

- [ ] Net kar hesabında giderlerin istatistiklere dahil edilmesi
- [ ] PDF/Excel rapor çıktısı
- [ ] Fiyat tahmini (Sahibinden/Arabam entegrasyonu)
- [ ] Mobil uygulama adaptasyonu
- [ ] Push bildirimler
- [ ] Araç fotoğrafı ekleme
