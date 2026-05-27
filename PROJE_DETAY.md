# GaleriPro - Proje Detay Dokümanı

## Proje Tanımı

GaleriPro, oto galeri sahiplerinin araç alım-satım süreçlerini dijital ortamda takip etmelerini sağlayan bir yönetim uygulamasıdır. Galericiler; hangi aracı ne zaman aldığını, ne kadara aldığını, ne kadara sattığını, masraflarını ve net karını tek bir yerden takip edebilir.

## Hedef Kitle

- Küçük ve orta ölçekli oto galeri sahipleri
- Bireysel araç alım-satım yapan kişiler
- Araç ticareti ile uğraşan girişimciler

## Platform Stratejisi

| Faz | Platform | Durum |
|-----|----------|-------|
| **Faz 1** | Windows Masaüstü | Aktif geliştirme |
| **Faz 2** | Android / iOS Mobil | Planlandı |
| **Faz 3** | Web Uygulaması | Planlandı |

Tüm platformlar aynı Supabase backend'ini kullanacak. Bir galerici masaüstünden girdiği veriyi mobilde de görebilecek.

---

## Mevcut Özellikler (v1.0)

### Kullanıcı Yönetimi
- E-posta ile kayıt ve giriş
- Galeri adı tanımlama
- Her galerici kendi verilerini görür (RLS ile izole)

### Araç Yönetimi
- Araç ekleme (plaka, marka, model, yıl, renk, kilometre)
- Araç düzenleme ve silme
- Alış fiyatı ve alış tarihi kaydı
- Araç satış işlemi (satış fiyatı + tarihi)
- Durum takibi: Stokta / Satıldı / Rezerve

### Gider Takibi
- Araç bazlı gider ekleme
- Gider türleri: Bakım, Boya, Sigorta, Vergi, Diğer
- Toplam gider hesabı
- Net kar = Brüt Kar - Toplam Gider

### Dashboard
- Stoktaki araç sayısı
- Satılan araç sayısı
- Toplam kar
- Toplam stok yatırımı
- Hızlı işlem butonları

### Araç Listesi
- Tablo görünümü (DataTable)
- Arama: Plaka, marka veya model ile filtreleme
- Durum filtresi: Tümü / Stokta / Satıldı

### İstatistikler
- Genel özet kartları
- Satış geçmişi tablosu

---

## Planlanan Özellikler

### Faz 2 — Gelişmiş Özellikler
- [x] **Net kar hesabının istatistiklere dahil edilmesi** — İstatistik ekranında ve satış geçmişi tablosunda net kar gösteriliyor
- [ ] **Araç fotoğrafı ekleme** — Supabase Storage ile araç görselleri *(Supabase'de `vehicle-photos` bucket oluşturulması gerekiyor)*
- [x] **Gider düzenleme/güncelleme** — Gider listesinde düzenle ve sil butonları eklendi
- [x] **Sayısal alan doğrulama** — Fiyat/km/yıl alanlarına harf girilmesi engellendi, validator eklendi
- [x] **Hata bildirimi iyileştirme** — Sessiz catch blokları kullanıcıya SnackBar ile gösteriyor

### Faz 3 — Raporlama
- [x] **PDF rapor çıktısı** — İstatistik ekranından yazdır/kaydet (Google Fonts ile Türkçe karakter desteği)
- [x] **Excel dışa aktarma** — Araç listesini Downloads klasörüne .xlsx olarak kaydeder
- [x] **Grafikler** — Aylık net kâr bar grafiği + en çok satılan markalar yatay bar grafiği

### Faz 4 — Fiyat Tahmini
- [ ] **Piyasa fiyat araştırması** — Marka/model/yıl bazlı ortalama piyasa fiyatı
- [ ] **Veri kaynakları** — Sahibinden.com / Arabam.com entegrasyonu (web scraping veya API)
- [ ] **Alış/satış fiyat önerisi** — Piyasa verilerine göre kar marjı tahmini

### Faz 5 — Mobil Uygulama
- [ ] **Flutter mobil adaptasyon** — Aynı kod tabanıyla Android/iOS
- [ ] **Push bildirimler** — Stokta uzun süre kalan araç hatırlatması
- [ ] **Offline destek** — İnternet olmadığında yerel kayıt, sonra senkronizasyon

### Faz 6 — İleri Seviye
- [ ] **Çoklu kullanıcı desteği** — Galeri sahibi + çalışan rolleri
- [ ] **Müşteri yönetimi** — Alıcı/satıcı bilgileri ve geçmişi
- [ ] **Takas takibi** — Takas işlemlerinin kaydı
- [ ] **Kasko/sigorta hatırlatıcı** — Araç sigortası bitiş tarihi uyarısı
- [ ] **Web dashboard** — Tarayıcıdan erişim

---

## Teknoloji Yığını

| Katman | Teknoloji |
|--------|-----------|
| Frontend | Flutter (Dart) |
| Backend | Supabase (PostgreSQL + Auth + Storage) |
| Veritabanı | PostgreSQL (Supabase üzerinde) |
| Auth | Supabase Auth (e-posta/şifre) |
| Config | flutter_dotenv (.env) |
| Raporlama | fl_chart (planlandı) |

## Veritabanı Şeması

```
profiles (1) ──── (N) vehicles
                        │
                        ├── (N) expenses
                        │
                        └── (N) price_estimates (planlandı)
```

### Araç Durumları
- **stokta** — Araç galeride, satışa hazır
- **satildi** — Araç satıldı, kar/zarar hesaplandı
- **rezerve** — Araç rezerve edildi (henüz kullanılmıyor)

### Kar Hesaplama
```
Brüt Kar = Satış Fiyatı - Alış Fiyatı (veritabanında otomatik)
Net Kar  = Brüt Kar - Toplam Giderler (uygulama tarafında)
```

---

## Bilinen Sorunlar ve Teknik Borç

1. ~~**İstatistiklerde gider hesabı yok**~~ — Düzeltildi: `getStats()` net karı hesaplıyor
2. ~~**Gider güncellenemiyor**~~ — Düzeltildi: `updateExpense()` eklendi, UI'da düzenleme butonu var
3. ~~**Sayısal alan validasyonu eksik**~~ — Düzeltildi: `FilteringTextInputFormatter` + validator eklendi
4. ~~**Sessiz hata yönetimi**~~ — Düzeltildi: catch blokları SnackBar gösteriyor
5. ~~**Rezerve durumu kullanılmıyor**~~ — Düzeltildi: Araç formunda seçilebilir, detay ekranında Rezerve Et / İptal Et butonları eklendi
6. **go_router kullanılmıyor** — Paket eklendi ama Navigator kullanılıyor

---

## Geliştirme Notları

- Supabase anahtarları `.env` dosyasında, asla koda yazılmamalı
- `.env.example` şablon olarak kullanılmalı
- Windows minimum pencere boyutu: 900x600 piksel
- UI dili tamamen Türkçe, değişken adları İngilizce-Türkçe karışık
- Supabase ücretsiz plan limitleri: 500MB DB, 1GB Storage, 60 eşzamanlı bağlantı

---

## Supabase Kurulum — Profil Otomatik Oluşturma (önerilen)

Kayıt sırasında `profiles` satırının atomik şekilde oluşması için Supabase
SQL editöründe aşağıdaki trigger'ı bir kez çalıştırın. Bu kurulum yapılmazsa
uygulama yine çalışır — Dart tarafı fallback olarak profili oluşturur — ancak
"Confirm email" açıkken kullanıcı zombi hesap riski taşır.

```sql
-- 1) auth.users tablosuna yeni satır eklendiğinde otomatik profil oluştur
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, galeri_adi)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'galeri_adi', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- 2) Trigger'ı tetikleyici olarak bağla
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```

Trigger devrede iken `auth_service.dart`'taki insert duplicate hatası
verirse (`23505`) bu beklenen davranıştır — kod bunu yutar.
