; ============================================================================
;  GaleriPro — Inno Setup kurulum betiği
;  Bu betik, "flutter build windows" çıktısını tek bir setup.exe'ye paketler.
;
;  Kullanım:
;    1) Visual Studio (Desktop development with C++) kurulu bir makinede
;         flutter build windows --release
;    2) Inno Setup'ı kurun: https://jrsoftware.org/isdl.php
;    3) Bu dosyaya çift tıklayın → "Build > Compile" (veya ISCC ile derleyin)
;    4) Üretilen kurulum dosyası: installer\Output\GaleriPro_Kurulum_1.0.0.exe
;
;  Ayrıntılar için: installer\KURULUM_REHBERI.md
; ============================================================================

#define AppName "GaleriPro"
#define AppVersion "1.0.0"
#define AppPublisher "OtoGaleri"
#define AppExeName "oto_galeri_app.exe"

; flutter build windows --release çıktısının bu .iss dosyasına göre yolu
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
; AppId uygulamayı benzersiz tanımlar — GÜNCELLEME'lerin doğru çalışması için
; bu GUID'i ASLA değiştirmeyin.
AppId={{8F3A1C2D-5B4E-4A6F-9C7D-1E2F3A4B5C6D}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
OutputDir=Output
OutputBaseFilename=GaleriPro_Kurulum_{#AppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
; Uygulama 64-bit; yalnızca x64 Windows'a kurulur
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Program Files'a yazmak için yönetici izni gerekir
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
; Türkçe sihirbaz için: Inno Setup'ın resmi olmayan Turkish.isl dosyasını
; "Languages" klasörüne ekleyip aşağıdaki satırı etkinleştirin:
; Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"

[Tasks]
Name: "desktopicon"; Description: "Masaüstü kısayolu oluştur"; GroupDescription: "Ek kısayollar:"

[Files]
; Release klasörünün tamamı (exe + DLL'ler + data\ klasörü) kopyalanır.
; data\flutter_assets içinde .env de gömülü gelir — ayrıca kopyalamaya gerek yok.
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\{#AppName} Kaldır"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "GaleriPro'yu başlat"; Flags: nowait postinstall skipifsilent
