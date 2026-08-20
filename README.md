# Owner Easton Park — Mobile App

Aplikasi mobile Flutter untuk owner/pemilik unit Easton Park — pengganti/pendamping
portal web `ownerdev` (CI3). Dikonsumsi via REST API Laravel baru (prefix `/api/v1`,
Sanctum token auth). Lihat [`docs/96_perencanaan_mobile_app_owner.md`](docs/96_perencanaan_mobile_app_owner.md)
untuk rencana lengkap (scope, arsitektur, fase, risiko, keputusan terbuka).

## Status

Initial scaffold — struktur project, tema, networking layer, dan layar Tier 1
(lihat docs/96 §4) sudah dibuat mengikuti kontrak API yang sudah jadi & terverifikasi
di backend (Auth OTP, Dashboard, Tagihan, Riwayat Bayar, Profil, Tiket).

**Desain visual (Figma/Claude Artifact) belum diterapkan** — link desain yang dibagikan
butuh login untuk diakses, jadi tema saat ini pakai Material 3 generik
(`lib/core/theme/app_theme.dart`) sebagai placeholder. Ganti `seedColor` di sana begitu
desain resmi bisa diakses.

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
