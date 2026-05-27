# GaleriPro — Dağıtım ve Kurulum Rehberi

Bu belge, GaleriPro masaüstü uygulamasının **başka PC'lere kurulabilir bir
`setup.exe`** olarak nasıl paketleneceğini anlatır.

> **Önemli:** Uygulamayı derlemek (`flutter build windows`) için makinede
> **Visual Studio + "Desktop development with C++"** iş yükü kurulu olmalıdır.
> Bu olmadan ne derleme ne de paketleme yapılabilir. Kullanıcının başka
> PC'sinde ise hiçbir şey kurmaya gerek yoktur — sadece `setup.exe`'yi çalıştırır.

---

## Yöntem 1 — Inno Setup ile profesyonel kurulum dosyası (önerilen)

Tek bir `GaleriPro_Kurulum_1.0.0.exe` üretir: Başlat menüsü + masaüstü kısayolu,
"Program Ekle/Kaldır" listesinde görünür, kaldırma desteği vardır.

### Tek seferlik hazırlık
1. **Inno Setup**'ı indirip kurun: https://jrsoftware.org/isdl.php

### Her sürümde yapılacaklar
1. Sürüm derlemesini alın (geliştirme makinesinde, repo kök dizininde):
   ```powershell
   flutter pub get
   flutter build windows --release
   ```
   Çıktı: `build\windows\x64\runner\Release\`
   (içinde `oto_galeri_app.exe`, DLL'ler ve `data\` klasörü)

2. Kurulum betiğini derleyin:
   - `installer\galeri_pro_setup.iss` dosyasına çift tıklayın → **Build > Compile**
   - veya komut satırından:
     ```powershell
     & "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\galeri_pro_setup.iss
     ```

3. Üretilen dosya:
   ```
   installer\Output\GaleriPro_Kurulum_1.0.0.exe
   ```
   Bu dosyayı diğer PC'lere kopyalayıp çalıştırmanız yeterli.

### Sürüm yükseltirken
- `pubspec.yaml` içindeki `version:` ve `galeri_pro_setup.iss` içindeki
  `#define AppVersion` değerini birlikte güncelleyin.
- `AppId` GUID'ini **değiştirmeyin** — aynı kalması, eski sürümün üzerine
  düzgün güncelleme yapılmasını sağlar.

---

## Yöntem 2 — Taşınabilir (portable) klasör (kurulum gerektirmez)

En hızlı yol; kurulum sihirbazı olmadan dağıtmak için.

1. `flutter build windows --release`
2. `build\windows\x64\runner\Release\` klasörünün **tamamını** ZIP'leyin.
3. ZIP'i hedef PC'ye kopyalayın, açın, `oto_galeri_app.exe`'yi çalıştırın.

> Klasördeki `data\` dahil **tüm** dosyalar birlikte taşınmalıdır; yalnızca
> `.exe`'yi kopyalamak çalışmaz.

---

## Hedef PC'de gereksinimler

- **Windows 10/11 64-bit.**
- Ayrı bir çalışma zamanı (runtime) kurulumu **gerekmez** — gerekli Visual C++
  DLL'leri Release çıktısıyla birlikte gelir.
- Uygulama internet bağlantısı ister (Supabase). İlk açılışta giriş/kayıt yapılır.

---

## Notlar

- **`.env` / Supabase anahtarı:** `.env` dosyası `pubspec.yaml`'da asset olarak
  tanımlı olduğundan derleme sırasında `data\flutter_assets\.env` içine gömülür
  ve kurulumla birlikte dağıtılır. İçindeki `SUPABASE_ANON_KEY` herkese açık
  (public) anon anahtardır; veri güvenliği Supabase tarafında **RLS** ile
  sağlanır, dolayısıyla uygulamayla dağıtılması normaldir.
- **Yerel yedek konumu:** Uygulama, her PC'de `Belgeler\GaleriPro\yedek.json`
  altında yerel yedek tutar (bkz. `lib/services/local_backup_service.dart`).
- **Excel/PDF çıktıları:** Kullanıcının `İndirilenler` klasörüne yazılır.
- **Kod imzalama (opsiyonel):** İmzasız `setup.exe`'de Windows SmartScreen
  "Bilinmeyen yayımcı" uyarısı gösterebilir. Uyarıyı kaldırmak için bir kod
  imzalama sertifikası (Authenticode) ile `signtool` kullanılabilir.
