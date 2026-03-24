# CloakNote - GitHub Senkronizasyonlu Şifreli macOS Not Uygulaması

<p align="center">
  <img src="docs/logo.png" alt="CloakNote logo" width="160">
</p>

https://github.com/user-attachments/assets/7cf03b32-8710-4f6e-91f3-f0cf2253f5a3

[English](README.md)

CloakNote, private GitHub senkronizasyonuna sahip sifreli bir macOS not uygulamasidir.

Notlarin, kendi private GitHub reponda saklanir; yuklenmeden once sifrelenir ve sadece Mac uzerinde cozulur.

[Indir](#indir) · [Ozellikler](#ozellikler) · [Nasil Calisir](#nasil-calisir) · [Build](#lokalde-calistirma)

## Indir

En guncel `.dmg` dosyasini [son release sayfasindan](https://github.com/sarisen/CloakNote/releases/latest) indir.

Veya Homebrew ile kur:

```bash
brew install sarisen/cloaknote/cloaknote
```

1. `CloakNote-<version>.dmg` dosyasini indir
2. DMG'yi ac ve CloakNote'u `Applications` klasorune surukle
3. macOS ilk acilisi engellerse sunu calistir:

```bash
xattr -c /Applications/CloakNote.app
```

Ardindan uygulamaya sag tiklayip `Open` sec.

## Ozellikler

- Yerel passphrase ile uctan uca sifreli notlar
- Kendi GitHub hesabindaki private repo ile senkronizasyon
- Turkce ve Ingilizce arayuz
- Otomatik kilit, tema ve not istatistikleri

## Nasil Calisir

1. CloakNote'u passphrase ile acarsin.
2. Uygulama sifreleme anahtarini Mac uzerinde yerel olarak turetir.
3. Her not yuklenmeden once sifrelenir.
4. Private GitHub reposunda sadece sifreli dosyalar tutulur.
5. Notlarini acarken CloakNote sifreli dosyalari indirir ve passphrase ile cihaz uzerinde cozer.

Yani okunabilir not icerigin GitHub uzerinde duz metin olarak tutulmaz.

## Guvenlik ve Gizlilik

- Notlarin, kendi private GitHub repoda tutulur
- CloakNote duz metin degil, sifreli not dosyalari yukler
- Passphrase ve turetilen anahtar Mac uzerinde yerel kalir
- Passphrase olmadan repo icerigi okunamaz
- Birisi repoya erisse bile anahtar olmadan sadece sifreli veri gorur

## Ilk Kurulum

1. Uygulamayi ac.
2. Onboarding sirasinda dilini sec.
3. Guclu bir passphrase belirle.
4. `repo` scope'una sahip bir GitHub Personal Access Token olustur.
5. Repo bilgilerini gir veya CloakNote'un private repo'yu otomatik olusturmasina izin ver.

## Proje Yapisi

```text
CloakNote/
├── CloakNote.xcodeproj
├── CloakNote/
│   ├── CloakNoteApp.swift
│   ├── Models/
│   ├── Services/
│   ├── Utilities/
│   ├── ViewModels/
│   ├── Views/
│   └── Assets.xcassets/
├── docs/
├── scripts/
├── .github/workflows/
└── README.md
```

### Ana klasorler

- `Models`: not ve sifreli payload modelleri
- `Services`: kripto, GitHub senkronizasyonu ve keychain erisimi
- `Utilities`: sabitler, extension'lar ve coklu dil destegi
- `ViewModels`: uygulama state'i ve ayar mantigi
- `Views`: onboarding, kilit ekrani, editor ve ayarlar gibi SwiftUI ekranlari
- `docs`: README gorselleri ve demo dosyalari
- `scripts`: yerel build ve paketleme yardimcilari
- `.github/workflows`: GitHub Actions release otomasyonu

## Gereksinimler

- macOS 14 veya ustu
- Xcode 16 veya ustu
- Bir GitHub hesabi
- `repo` scope'una sahip GitHub Personal Access Token

## Lokalde Calistirma

```bash
git clone https://github.com/sarisen/CloakNote.git
cd CloakNote
open CloakNote.xcodeproj
```

Veya terminalden build al:

```bash
xcodebuild -project CloakNote.xcodeproj -scheme CloakNote -configuration Debug build
```

Surum tag'leri ile DMG release otomatik olusturulur.

## Lisans

MIT.
