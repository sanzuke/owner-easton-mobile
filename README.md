# Owner Easton Park — Mobile App

Aplikasi mobile Flutter untuk owner/pemilik unit Easton Park — pengganti/pendamping
portal web `ownerdev` (CI3). Dikonsumsi via REST API Laravel baru (prefix `/api/v1`,
Sanctum token auth). Lihat [`docs/96_perencanaan_mobile_app_owner.md`](docs/96_perencanaan_mobile_app_owner.md)
untuk rencana lengkap (scope, arsitektur, fase, risiko, keputusan terbuka).

## Status

Initial scaffold — struktur project, tema, networking layer, dan layar Tier 1
(lihat docs/96 §4) sudah dibuat mengikuti kontrak API yang sudah jadi & terverifikasi
di backend (Auth OTP, Dashboard, Tagihan, Riwayat Bayar, Profil, Tiket).

**Desain visual diterapkan** (21 Agustus 2026, setelah akses ke
[Claude Artifact desain](https://claude.ai/code/artifact/1b3217fc-0637-4364-b51e-0b33c66be321)
diberikan) — palet warna, struktur navigasi, dan gaya kartu/badge mengikuti prototipe
resmi. Lihat `lib/core/theme/app_colors.dart` untuk catatan sumber warna (estimasi visual
dari screenshot, bukan token resmi — update lagi kalau ada file token Figma).

Struktur navigasi mengikuti desain: bottom nav **4 tab** — Beranda, Tagihan, Acara,
Lainnya. Tiket ("Request") dan Profil diakses dari dalam tab **Lainnya**; Riwayat
Pembayaran diakses dari ikon jam di AppBar tab **Tagihan** (desain tidak punya tab
terpisah untuk keduanya).

**Belum sepenuhnya pixel-match:** layar "Request" di desain menampilkan grid 5 kategori
tiket dengan jumlah permintaan per kategori; scaffold ini masih pakai daftar tiket flat
+ tombol "Ajukan Tiket" (fungsional, beda tata letak). Utility/PBB/P3SRS/Pengaturan di
tab Lainnya masih placeholder "segera hadir" karena API-nya belum ada di backend (lihat
docs/96 §5) — begitu juga fitur **Acara** (`lib/features/acara/`), yang endpoint-nya
(`/api/v1/acara`) belum dibangun sama sekali, jadi tab ini akan gagal fetch sampai
backend menyusul.

## Stack

- **Flutter** (Android + iOS) — `flutter create --platforms=android,ios`
- **State management:** Riverpod (`flutter_riverpod`)
- **Routing:** `go_router`
- **HTTP:** `dio` (base URL dari `.env`, lihat `.env.example`)
- **Auth token:** `flutter_secure_storage` (Sanctum bearer token, bukan session)
- **Biometrik/buka cepat:** `local_auth` (device-level, lihat docs/96 §3)
- **Push notification:** `firebase_messaging` (perlu setup project Firebase dulu —
  belum dikonfigurasi, lihat docs/96 §8)

## Struktur folder

```
lib/
  app/            # Router, shell (bottom nav), splash screen
  core/           # Konstanta, env, tema, network client, storage, util
  features/
    auth/         # Login OTP + verifikasi OTP
    dashboard/    # Ringkasan piutang, unit, meter air
    tagihan/      # Daftar & detail invoice
    pembayaran/   # Riwayat pembayaran
    profil/       # Lihat/edit profil, upload berkas
    tiket/        # Ajukan & lihat tiket lintas tipe
```

Tiap fitur dibagi `data/` (repository + model), `application/` (Riverpod provider),
`presentation/` (screen/widget) — supaya gampang ditambah fitur Tier 2/3 tanpa
mengubah struktur.

## Menjalankan

```bash
cp .env.example .env
# sesuaikan API_BASE_URL di .env ke Laravel API lokal/staging
flutter pub get
flutter run
```

## Yang belum dikerjakan (lihat docs/96 §4, §8)

- Desain visual final (menunggu akses desain)
- Setup Firebase project untuk push notification (FCM)
- Fitur Tier 2: bayar langsung dari app, upload KTP/KK/foto (repository sudah
  siap di `profil_repository.dart`, tinggal UI picker file), PBB, blog/pengumuman
- Fitur Tier 3: menunggu keputusan scope (lihat docs/96 §2, §8)

## Build dengan nomor build otomatis

Nomor build (android `versionCode`, iOS `CFBundleVersion`) dibuat otomatis naik dari waktu build
(menit sejak 1 Jan 2026 UTC), jadi APK baru selalu bisa dipasang di atas yang lama dan tidak perlu
mengedit `pubspec.yaml` tiap build. Nama versi (`1.0.0`) tetap dari `version:` di `pubspec.yaml`.

- Windows: `.\scripts\build.ps1 apk --debug` (atau `appbundle --release`)
- Linux/macOS/WSL: `scripts/build.sh apk --debug`

`flutter run` tidak melewati skrip ini dan memakai angka build dari `pubspec.yaml`; untuk mencoba di
perangkat cukup begitu. Pakai skrip ini untuk APK/AAB yang dibagikan atau diunggah.
