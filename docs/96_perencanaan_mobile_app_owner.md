# Perencanaan Mobile App Owner — BMS Easton Park

**Status:** F1 (API Backend Tier 1) SELESAI 19 Agustus 2026 (Auth OTP+Sanctum, Dashboard, Tagihan, Riwayat Bayar, Profil, Tiket — semua diverifikasi HTTP asli). F2 (Flutter App Tier 1) MULAI DIKERJAKAN 21 Agustus 2026 — project di-scaffold, layout disesuaikan persis dengan desain resmi, dan berhasil dijalankan di device Android fisik. Lihat update di bagian bawah dokumen.
**Repo mobile app:** [`github.com/sanzuke/owner-easton-mobile`](https://github.com/sanzuke/owner-easton-mobile) (branch `main`).
**Cakupan disepakati user (8 Agustus 2026):** full parity fitur dengan `ownerdev`, backend API baru di Laravel, platform Flutter (cross-platform Android+iOS).
**API Reference untuk tim mobile:** lihat [`docs/96b_api_reference_mobile_owner.md`](96b_api_reference_mobile_owner.md) — kontrak endpoint lengkap (request/response/error) supaya development Flutter bisa jalan paralel tanpa baca source Laravel.

---

## 1. Ringkasan

Membangun aplikasi mobile untuk owner/pemilik unit Easton Park, menggantikan (atau mendampingi) portal web `ownerdev` (CI3 + Tailwind, `opr.eprjatinangor.com` / `owner.eprjatinangor.com`). App dikonsumsi via REST API yang **dibangun baru di Laravel** (`laravel/`), selaras dengan refactoring CI3→Laravel yang sedang berjalan — bukan menempel API tipis di atas CI3 lama yang akan dibongkar lagi nanti.

**Kenapa API-first di Laravel, bukan CI3:** proyek ini sudah dalam proses strangler-fig migration ke Laravel (lihat `docs/10_checklist_pekerjaan.md` — semua modul P1-P7 sudah dikonversi kode-nya). Membangun API di atas CI3 `ownerdev` berarti kerja dua kali: sekali sekarang, sekali lagi saat modul terkait pindah ke Laravel. API langsung di Laravel jadi bagian dari migrasi yang sama, bukan proyek terpisah yang harus disinkronkan ulang.

**Konsekuensi dari pilihan ini:** app tidak bisa mulai development server-side dari nol hari ini — beberapa endpoint API bergantung pada modul Laravel yang levelnya baru "kode jadi, belum diverifikasi end-to-end" (lihat §5 Ketergantungan).

---

## 2. Sumber Kebenaran Fitur

`ownerdev` (CI3, `/home/hasan-qti/Project/easton-park/ownerdev/`) adalah portal owner yang LIVE dipakai user sungguhan sekarang — app mobile harus mengacu ke fitur & alur DI SINI, bukan ke Laravel (Laravel belum punya UI owner-facing sama sekali, cuma modul admin). Ringkasan fitur lengkap ada di `docs/60_ownerdev_summary.md` (28 controller). Poin penting:

- **Autentikasi:** Login via No HP + ID BAST → OTP WhatsApp 4-digit (dikirim dari nomor yang dikonfigurasi di `wa_pengaturan` kode `otp_owner`, BUKAN hardcode). Session-based, bukan token-based — **app butuh mekanisme auth baru** (lihat §4.1).
- **Dashboard:** piutang (dari `cache_rekap_outstanding`), meter air terakhir, info unit/pemilik.
- **Data pemilik:** edit profil, upload KTP/KK/foto, cek NIK duplikat.
- **Unit:** detail BAST, daftar penghuni, alamat surat, histori ganti pemilik, ganti kepemilikan, berkas unit.
- **Billing/Tagihan:** lihat tagihan, invoice (cetak/share/PDF/export), posting billing.
- **Pembayaran:** bayar IPL/Listrik/Lainnya, request pembayaran, cetak bukti.
- **Tiket/Work Order:** 6 tipe (Defect, FO, General/RC, WO, Access, Corrective) — CRUD + approval + jadwal + histori + signature + attachment.
- **Utility/Meter:** input & rekap meter air/listrik, import CSV.
- **Blog/Pengumuman:** daftar & detail post dari management.

**Update 19 Agustus 2026 — Audit Fase 0 (owner vs staf) SELESAI**, dikerjakan langsung dari kode `ownerdev` (bukan cuma baca `docs/60`), 3 sinyal dipakai:

1. **Menu/sidebar yang benar-benar live** (`views/layout/sidebar.php`, Tailwind M3) — cuma 7 item: Dashboard, Invoice, Request, Utility, PBB, Acara, P3SRS.
2. **Aktor per controller** — `session->id_bast`/`session->tipe=='owner'` (dipakai controller owner-facing) vs `session->id_admin` (dipakai controller yang catat "siapa yang proses" — pola khas tools staf).
3. **Dari mana `id_admin` diisi** — ditelusuri ke SATU-SATUNYA tempat: `Login.php` (login OTP owner), dan nilainya **di-hardcode `0`**. Tidak ada controller login staf/admin lain di `ownerdev` sama sekali.

**Temuan tak terduga:** controller "staf" (billing/Master, billing/Tagihan, bayar/Lainnya, bayar/Request, meter/Rekening, sebagian besar tiket/Ajax approval, dll.) dirender pakai layout **BERBEDA** — `views/layout/navbar_rm.php`, brand-nya masih *"PT Nusalima Kelola Sarana — Rental Management System"* (sisa versi lama sebelum di-Tailwind-kan jadi portal OTP-only). Karena `id_admin` cuma pernah bernilai `0` (tidak ada mekanisme login yang mengisinya selain itu), fitur-fitur ini **secara efektif tidak bisa diakses siapa pun** di produk yang live sekarang — kemungkinan besar dead code peninggalan versi lama `ownerdev`, bukan cuma "staf pakai lewat cara lain".

**Klasifikasi final:**

| Kategori | Controller/Method |
|---|---|
| **OWNER** (masuk scope app, self-service) | `Login`, `Auth`, `Home`, `Pemilik` (edit/actions2/ajax_cek_nik), `Bast` (index/huni/surat — VIEW saja), `Notifikasi`, `Blog`, `bayar/Invoice` (bayar/ajax_list/cetak), `bayar/Home`, `billing/Invoice` method view-only (index/ajax_list/print/share/pdf), `tiket/Home` + view/add per 6 tipe tiket, `meter/Home` + `meter/Utility` (view/ajax_add_meter — input meter sendiri), `Pbb`, `Acara` |
| **STAFF — TAPI UNREACHABLE saat ini** (exclude total dari app; kandidat DIBUANG bukan diporting, sampai dikonfirmasi user) | `Profil` (edit admin/username/password), `billing/Tagihan`, `billing/Master`, `billing/Invoice` write-methods (add/add_act*/edit/hapus/export), `bayar/Lainnya`, `bayar/Request`, `bayar/Report`, `meter/Rekening`, `meter/Utility` (rekap/import/koreksi-error), sebagian besar `tiket/Ajax` (approval/hold/reject/close/card/signature), `Bast::ganti_pemilik_act/hapus/berkas` |

**Belum dikonfirmasi ke user (docs/90 #31):** apakah kategori "STAFF unreachable" ini memang benar dead code (aman dibuang dari scope app tanpa kehilangan fungsi apa pun), atau staf sebenarnya memproses hal ini lewat jalur lain yang belum ketahuan (akses DB langsung? tool terpisah? atau memang belum pernah dipakai dari awal). **Sampai dijawab, app dibangun HANYA untuk kategori OWNER di atas** — konsisten dgn 7 menu sidebar live & pendekatan "bangun general dulu, konfirmasi belakangan".

---

## 3. Arsitektur Teknis

```
┌─────────────────┐        HTTPS/JSON         ┌──────────────────────┐
│  Flutter App     │ ────────────────────────▶ │  Laravel API          │
│  (Android+iOS)   │ ◀──────────────────────── │  (laravel/, api.php)  │
└─────────────────┘      REST + Sanctum token   └──────────┬────────────┘
                                                             │
                                                   DB::connection('bms')
                                                             │
                                                   ┌─────────▼─────────┐
                                                   │   MariaDB `bms`    │
                                                   │  (sama dgn CI3 &   │
                                                   │   Laravel admin)   │
                                                   └────────────────────┘
```

- **Auth API:** Laravel Sanctum (token-based, cocok utk mobile — belum ada di `composer.json` project ini, perlu `composer require laravel/sanctum`). Alur: submit No HP + ID BAST → backend kirim OTP via WA (reuse `BlastService`, nomor dari `wa_pengaturan` kode `otp_owner`, SAMA seperti CI3) → verifikasi OTP → terbitkan Sanctum personal access token → app simpan token di secure storage (`flutter_secure_storage`), kirim sebagai `Authorization: Bearer` di tiap request.
- **Biometric/Face unlock (device-level, bukan face-recognition server-side):** setelah login OTP pertama sukses, app tawarkan "aktifkan buka cepat" — fingerprint, Face ID (iOS), atau face unlock/deteksi wajah bawaan Android, semua lewat 1 API yang sama: package Flutter `local_auth`. Matching wajah/sidik jari **sepenuhnya di sistem OS HP**, tidak ada data biometrik yang dikirim/disimpan ke server — dari sisi Laravel ini transparan, cuma jadi gerbang lokal untuk unlock Sanctum token yang sudah tersimpan di secure storage. Ini BUKAN verifikasi identitas ke KTP (yang jauh lebih berat & masuk ranah e-KYC/UU PDP) — cukup pengganti PIN/password buat re-entry, sama kelasnya dengan biometric login di app perbankan pada umumnya. Server tetap butuh: endpoint refresh/revoke token & kebijakan expiry token wajar, supaya "logout paksa dari server" tetap bisa dilakukan admin kalau perlu (device hilang/dicuri, dll).
- **Versioning API:** prefix `/api/v1/...` sejak awal — supaya breaking change ke depan tidak langsung merusak app yang sudah dirilis ke Play Store/App Store (app di HP user tidak bisa dipaksa update instan seperti web).
- **Response envelope konsisten:** `{ "status": bool, "data": ..., "message": string, "errors": {...} }` — hindari format ad-hoc per endpoint (masalah lama di sisi web CI3 yang echo `json_encode` beda-beda struktur per controller).
- **File upload:** KTP/KK/foto profil/bukti pembayaran — pakai `multipart/form-data`, simpan ke disk `bms_upload` yang sama (konsisten dgn convention Laravel yang sudah ada, lihat `config/filesystems.php`).
- **Push notification:** Firebase Cloud Messaging (FCM) — dibutuhkan utk notifikasi tagihan jatuh tempo, status tiket berubah, broadcast pengumuman. Ini KOMPONEN BARU, belum ada infra apa pun untuk ini di project (WA dipakai sebagai notifikasi utama sekarang, bukan push). Butuh: Firebase project baru, `device_token` per user tersimpan di DB, service pengirim FCM di Laravel (queue job, mirip pola `KirimBroadcastWa`).
- **PDF invoice/kwitansi:** app butuh lihat/download PDF — bergantung pada `barryvdh/laravel-dompdf` yang **masih "pending" per checklist P3** (lihat §5).
- **Pembayaran:** app idealnya bisa generate VA/QRIS langsung dari HP — bergantung pada status integrasi gateway BJB yang **baru placeholder** di Laravel (lihat §5).

---

## 4. Cakupan Fitur & Prioritas

Disusun 3 tier berdasarkan value-vs-effort, BUKAN urutan pengerjaan literal per controller CI3 — beberapa controller di `docs/60` digabung/disederhanakan di app (mis. semua jenis tiket jadi 1 form dinamis, bukan 6 controller terpisah).

### Tier 1 — MVP (harus ada di rilis pertama)
- Login OTP WhatsApp
- Buka cepat via biometrik/face unlock device (fingerprint/Face ID/deteksi wajah Android) — opsional, gerbang lokal ke token yang sudah login, bukan mekanisme auth server baru (lihat §3)
- Dashboard (piutang, info unit, meter air terakhir)
- Lihat daftar tagihan/invoice + detail
- Lihat riwayat pembayaran + bukti (kwitansi)
- Profil: lihat & edit data pribadi
- Ajukan tiket (semua tipe, form dinamis) + lihat status/histori
- Notifikasi push (tagihan jatuh tempo, update status tiket)

### Tier 2 — Fase 2
- Bayar langsung dari app (VA display / deep-link ke m-banking; QRIS kalau sudah siap — lihat §5)
- Upload KTP/KK/foto profil
- Lihat PBB (link/PDF)
- Daftar penghuni unit
- Alamat surat menyurat (lihat & update)
- Blog/pengumuman

### Tier 3 — Nice-to-have / butuh keputusan "siapa aktornya" dulu (§2)
- Ganti kepemilikan unit (workflow sensitif, mungkin sebaiknya cuma via web+staf verifikasi manual, bukan self-service app)
- Manajemen berkas unit
- Approval tiket (kemungkinan besar ini **staf**, bukan owner — exclude dari app kecuali dikonfirmasi lain)
- Meter/utility input & rekap + import CSV (**staf**, exclude dari app kecuali dikonfirmasi lain)
- Billing master, posting billing (**staf**, exclude dari app kecuali dikonfirmasi lain)

---

## 5. Ketergantungan & Blocker (dari status refactoring saat ini)

Yang harus dituntaskan/diputuskan DULU sebelum fitur terkait di app bisa jalan penuh:

| Ketergantungan | Status saat ini | Dampak ke app |
|---|---|---|
| PDF invoice/kwitansi (`barryvdh/laravel-dompdf`) | Belum diintegrasi (pending, docs P3) | Fitur "lihat/download PDF invoice" di app tidak bisa jalan sampai ini selesai |
| `share/invoice` route publik | Belum ada — token `{{link}}` yang sudah digenerate 404 (docs/90 #26) | Kalau app pakai link publik yang sama dgn WA (bukan API auth), butuh route ini jadi dulu |
| Payment gateway BJB (VA/QRIS) | Baru placeholder, integrasi penuh ditunda | Fitur "bayar dari app" Tier 2 tertahan sampai ini clear |
| API layer (Sanctum, routes/api.php) | **Belum ada sama sekali** — proyek ini murni web (session-based) sejauh ini | Prasyarat mutlak sebelum app bisa mulai integrasi apa pun |
| Testing (Fase 3) & UAT modul terkait | 0%, belum mulai (lihat `docs/10`) | Endpoint API yang dibangun di atas modul yang "kode jadi tapi belum diverifikasi" berisiko mewarisi bug yang sama |

**Rekomendasi:** jangan build app menunggu SEMUA ini selesai — Tier 1 (§4) sengaja dipilih supaya tidak bergantung ke dompdf/BJB. Tapi PDF & pembayaran (Tier 2) realistis butuh dompdf + keputusan gateway selesai dulu.

---

## 6. Fase Pengembangan (usulan)

| Fase | Isi | Estimasi* |
|---|---|---|
| **F0 — Persiapan & audit scope** | Audit per-fitur ownerdev (owner vs staf, §2), finalisasi wireframe/UX Flutter, setup Firebase project, `composer require laravel/sanctum` | 1-2 minggu |
| **F1 — API Backend Tier 1** | `routes/api.php` + Sanctum auth (OTP flow), endpoint dashboard/tagihan/riwayat-bayar/profil/tiket, response envelope standar, rate-limit OTP | 3-4 minggu |
| **F2 — Flutter App Tier 1** | Setup project, auth flow, dashboard, tagihan, tiket, profil, push notification (FCM) — bisa paralel dgn F1 kalau API di-mock dulu (OpenAPI/Postman contract) | 4-6 minggu |
| **F3 — Internal testing & TestFlight/Internal track** | QA manual, fix bug, submit ke Google Play Internal Testing + TestFlight | 2 minggu |
| **F4 — Rilis Tier 1 ke publik** | Play Store + App Store submission (App Store review bisa makan 1-2 minggu ekstra, siapkan privacy policy, App Store Connect account $99/tahun) | 1-3 minggu (di luar kendali tim, tergantung review Apple) |
| **F5 — API + App Tier 2** | Bayar (tergantung §5 gateway), upload dokumen, PBB, blog | tergantung status blocker §5 |
| **F6 — Tier 3 (kalau dikonfirmasi relevan utk owner)** | Sesuai hasil audit F0 | TBD |

*Estimasi kasar 1 developer backend + 1 developer Flutter bekerja paralel setelah F0. Sesuaikan dgn kapasitas tim sebenarnya — dokumen ini tidak mengasumsikan headcount tertentu.

---

## 7. Risiko

1. **Auth OTP via WA unofficial gateway** — sudah ada riwayat masalah shadow-ban/gateway putus di web (lihat memory `wa-unofficial-gateway-shadow-ban`, `wa-gateway-production-status`). Kalau OTP gagal terkirim, user tidak bisa login sama sekali di app — ini SATU-satunya jalur masuk, jadi risikonya lebih tinggi dari web (web setidaknya punya fallback UX yang sudah teruji). Mitigasi: pastikan monitoring gateway WA (`/monitoring/wa`) mencakup jalur OTP app juga, pertimbangkan fallback SMS OTP kalau volume/kritikalitas naik.
2. **App Store review Apple** — kebijakan Apple lebih ketat soal app yang handle data KTP/KK/pembayaran; siapkan dokumentasi privacy & data-handling sebelum submit, supaya tidak ditolak berkali-kali (bisa makan waktu berminggu-minggu per iterasi review).
3. **Duplikasi effort kalau API dibangun sebelum modul Laravel terkait matang** — mis. kalau endpoint tagihan dibangun sebelum modul Billing Laravel benar-benar diverifikasi (Fase 3 testing di `docs/10` belum jalan), bug di modul itu akan terwarisi ke app. Mitigasi: prioritaskan verifikasi modul P3 (Billing/Payment) sebelum/bersamaan F1.
4. **Scope creep dari "full parity"** — kalau audit F0 tidak dilakukan dengan disiplin, app bisa berakhir membawa menu-menu staf yang membingungkan 99% user biasa. Mitigasi: audit F0 wajib, bukan opsional.

---

## 8. Keputusan Terbuka (perlu dikonfirmasi user sebelum F1 mulai)

1. Hasil audit F0 (§2) — fitur mana dari "full parity" yang benar dipakai owner vs staf?
2. Budget/timeline App Store Developer Program ($99/tahun) & Google Play Developer ($25 sekali bayar) — siapa yang provision akun ini?
3. Firebase project — pakai akun Google organisasi yang mana?
4. Nasib `ownerdev` (web) setelah app rilis — tetap dipertahankan paralel (dual-channel), atau app menggantikan total?
5. Prioritas F5 (fitur bayar) — tunggu keputusan gateway BJB penuh, atau rilis app dulu tanpa fitur bayar (arahkan user ke web/transfer manual sementara)?

---

*Dibuat: 8 Agustus 2026. Dasar: `docs/60_ownerdev_summary.md`, `docs/10_checklist_pekerjaan.md`, `docs/90_catatan_konfirmasi_user.md`, audit langsung `ownerdev/application/controllers/Login.php` (alur OTP) dan `laravel/composer.json`/`routes/` (konfirmasi belum ada API layer).*

---

## Update 19 Agustus 2026 — F1 Auth + Dashboard SELESAI, diverifikasi HTTP asli

**Terpasang:** `composer require laravel/sanctum` (v4.3.3, `php: ^8.2` — cocok constraint project, tidak
mengulang insiden spatie kemarin), migrasi `personal_access_tokens` (dijalankan di `bms_tmp` saja),
`routes/api.php` didaftarkan di `bootstrap/app.php` (`api:` routing baru, sebelumnya cuma `web:`).

**Model `App\Models\Bast`** ditambah `Authenticatable`+`HasApiTokens` (Sanctum) — additive, tidak
mengubah perilaku model ini di modul admin panel yang sudah pakai `Bast` sebelumnya. `id_bast` jadi
identitas login (sama seperti session `id_bast` di `ownerdev`), token diterbitkan SETELAH verifikasi
OTP — tidak pernah lewat `Auth::attempt()`/password.

**Endpoint jadi (prefix `/api/v1`, response envelope `{status,data,message,errors}` sesuai §3):**
- `POST /auth/login` — hp+id_bast → cari `bast` (nomor dev-bypass sama persis dgn daftar di
  `ownerdev/Login.php`, atau cocok `wa_surat`) → cek `wa_pengaturan` kode `otp_owner` (SAMA seperti
  ownerdev, bukan hardcode) → generate OTP, simpan ke `bast_login` (REUSE tabel yang sama dgn ownerdev,
  bukan bikin tabel baru — identitas sama, cuma beda kanal app/web) → kirim WA best-effort (gagal kirim
  TIDAK membatalkan, OTP sudah tersimpan). Rate-limit `throttle:5,1`.
- `POST /auth/verify-otp` — uid+otp → validasi vs `bast_login` (status=0, belum expired) → tandai
  status=1 → terbitkan Sanctum token. Rate-limit `throttle:10,1`.
- `GET /auth/me`, `POST /auth/logout` — protected (`auth:sanctum`).
- `GET /dashboard` — protected; piutang (`cache_rekap_outstanding`), meter air terakhir (`utility`/
  `utility_rekening`), info unit/pemilik — query pola SAMA PERSIS dgn `P3srs\AnggotaController::detail()`
  (admin panel) supaya angkanya konsisten.

**Verifikasi HTTP asli** (`php artisan serve`+curl, bukan tinker) di `bms_tmp`: login→OTP tersimpan
(WA aman, `WA_ENABLED=false` lokal)→verify-otp→token→`/me`+`/dashboard` 200 dgn data asli (piutang
Rp2.143.200, meter air 151, unit A0002)→logout→token lama otomatis 401 setelahnya. Kasus gagal: hp
tidak terdaftar → 404, OTP salah → 401, rate-limit → 429 setelah >5x/menit. Data uji (`bast_login` test
rows) sudah dibersihkan; config `wa_pengaturan`/`db_wa` kode `otp_owner` di `bms_tmp` SEBELUMNYA
`id_wa=NULL` (belum pernah dikonfigurasi meski row-nya sudah ada sejak 20 Jul 2026) — diisi dgn device
dummy utk keperluan tes lokal (aman, `WA_ENABLED=false` mencegah kirim sungguhan).

**Belum:** push notif FCM, refresh-token/rotate policy, deploy ke server manapun (di-HOLD, belum ada
SPK — lihat memory `no-deploy-bms2-until-spk`). Detail lengkap `docs/90` #35.

---

## Update 19 Agustus 2026 (lanjutan) — Tier 1 lengkap: Tagihan, Riwayat Bayar, Profil, Tiket

**Endpoint baru** (semua protected `auth:sanctum`, scoped ke `id_bast` milik token yang login):
- `GET /tagihan`, `GET /tagihan/{id}` — reuse `BillingService::getInvoiceList/getInvoiceDetail/
  getInvoiceItems` (sama persis dgn admin panel `Billing\InvoiceController`), tinggal di-scope
  `bast.id_bast` milik owner yang login + ownership check di `show()`.
- `GET /pembayaran` — riwayat pembayaran dari tabel `bayar` + join `db_via` (nama metode).
- `GET /profil`, `PUT /profil` — lihat & edit data `pemilik` (nama/hp/email/alamat). Upload KTP/KK/foto
  masuk Tier 2 nanti (docs/96 §4).
- `GET /tiket/tipe`, `GET /tiket`, `POST /tiket`, `GET /tiket/{id}` — ajukan tiket LINTAS TIPE via 1
  endpoint (bukan 6 controller terpisah spt admin panel), reuse `TiketService::getTimeline()` yg sudah
  ada. `store()` langsung `post=1` (open, skip draft) — alur mobile yg lebih ringkas dibanding admin.

**🐛 Bug pre-existing SERIUS ditemukan & DIFIX saat build `TiketController::store()` — docs/90 #36:**
`App\Models\Tiket` — kolom `id_tiket` (PRIMARY KEY tapi **BUKAN AUTO_INCREMENT**, digenerate manual via
`AplService::urut('tiket','id_tiket')`) **TIDAK ADA di `$fillable`**. Akibatnya `Tiket::create($data)`
DIAM-DIAM membuang nilai `id_tiket` yang sudah di-assign controller, insert jadi `id_tiket=0` — akan
collide/gagal (duplicate PK) utk tiket KEDUA yang dibuat SIAPA PUN, tipe apa pun (1 tabel `tiket`
dipakai bareng ke-6 tipe). **Pola identik ada di SEMUA 6 controller tiket admin panel** (Wo, Access,
Corrective, Defect, Fo, General — bukan cuma API baru ini) — dicek `grep`, semua pakai
`$data['id_tiket']=$idTiket; Tiket::create($data);`. Tidak pernah ketahuan karena verifikasi P2 Tiket
sebelumnya cuma audit skema kolom-per-kolom terhadap production, BUKAN tes fungsional submit form
"tambah tiket baru" end-to-end sungguhan. Fix 1 baris: tambah `'id_tiket'` ke `$fillable` — otomatis
memperbaiki ke-7 controller sekaligus (6 admin + API baru).

**Verifikasi:** HTTP asli — sebelum fix: tiket tersimpan `id_tiket=0` (dites, dikonfirmasi via query DB
langsung); setelah fix: id tersimpan benar, tiket ke-2 tidak collide, `GET /tiket/{id}` detail sukses,
DAN tes ownership (bast lain coba akses tiket punya bast lain → 404, bukan bocor data). Data uji
dibersihkan (termasuk baris `id_tiket=0` yang sempat kebuat).

**Belum:** push notif FCM, endpoint bayar-langsung (Tier 2, nunggu gateway BJB), deploy ke server
manapun (tetap di-HOLD). Detail lengkap `docs/90` #36.

---

## Update 19 Agustus 2026 (lanjutan lagi) — Upload berkas (tiket + KTP/KK) + fix respons error API

**Endpoint baru:**
- `POST /profil/berkas` — upload/ganti KTP atau Kartu Keluarga (`jenis`: ktp|kk). Disimpan di tabel
  generik `bast_berkas` (`nama`='KTP'/'Kartu Keluarga') — **BUKAN** kolom di `pemilik` (cuma ada `foto`)
  — persis pola `ownerdev::Pemilik::actions2`, supaya data konsisten lintas app+web. Upload versi baru
  otomatis soft-delete versi lama (bukan numpuk banyak file per jenis).
- `POST /tiket/{id}/berkas` — lampirkan foto/dokumen pendukung ke tiket milik sendiri (ownership check).
  `GET /tiket/{id}` sekarang ikut menampilkan daftar berkas.

**🐛 Ditemukan & DIFIX — semua route `/api/*` bisa balas HTML, bukan JSON, saat error tak tertangani:**
Laravel default cuma render JSON kalau `$request->expectsJson()` (bergantung header `Accept` klien).
Curl tanpa header itu (mis. request `multipart/form-data` polos) dapat HALAMAN HTML admin panel penuh
saat terjadi exception — buruk buat mobile app (parser JSON-nya bakal gagal total, bukan cuma dapat
pesan error jelek). Fix: `bootstrap/app.php` — `shouldRenderJsonWhen()` paksa semua path `api/*` selalu
JSON, TERLEPAS header Accept klien. Jangan gantungkan konsistensi response ke asumsi klien berperilaku
benar.

**Gap dev DB (lagi) ditemukan+difix di `bms_tmp` saja:** tabel `tiket_berkas` (dipakai fitur lampiran
di atas) ternyata belum ada di `bms_tmp` — pola sama seperti `tiket_histori`/`tiket_approv` sebelumnya
(skema sudah ada di production per `docs/04_database.md`, cuma belum ada di dev). Bukan bug kode.

**Verifikasi:** HTTP asli penuh dgn file upload sungguhan (PNG dummy) — upload KTP → muncul di profil →
upload KTP ke-2 → versi lama otomatis soft-delete (dicek query DB langsung) → upload lampiran tiket →
muncul di detail tiket → validasi mimetype salah → 422 JSON rapi (bukan HTML, mengkonfirmasi fix
exception handler). Semua file & data uji dibersihkan.

**Tier 1+2 inti kini LENGKAP:** Auth OTP, Dashboard, Tagihan, Riwayat Bayar, Profil (+upload KTP/KK),
Tiket (ajukan lintas-tipe +lampiran). **Sisa dari rencana awal:** push notif FCM (butuh Firebase project
baru, di luar scope backend saja), bayar-langsung (nunggu gateway BJB), deploy ke server (tetap
di-HOLD, belum ada SPK).

---

## Update 21 Agustus 2026 — F2 Flutter App: initial scaffold + layout persis desain resmi

**Project Flutter dibuat dari nol** di repo terpisah [`sanzuke/owner-easton-mobile`](https://github.com/sanzuke/owner-easton-mobile)
(bukan di monorepo ini) — `flutter create` Android+iOS, struktur `lib/core` (theme, network client
Dio + response envelope, secure token storage utk Sanctum, biometric quick-unlock service) dan
`lib/features/<nama>/{data,application,presentation}` per fitur (Riverpod utk state management,
go_router utk navigasi). Konsumsi API mengikuti kontrak di §3 & endpoint yang sudah jadi di F1.

**Desain resmi (Claude Artifact, link dibagikan user) diterapkan persis setelah akses diberikan** —
awalnya sempat coba akses tapi artifact butuh login, user login-kan lalu diverifikasi via browser
otomatis (prototipe interaktif: login → dashboard → tagihan → acara → menu lainnya → request).
Palet warna (olive/gold brand, navy CTA sekunder, pink utk ikon Request, biru utk Utility, badge
hijau/merah muda utk status Payment/Invoice), struktur navigasi 4-tab (Beranda/Tagihan/Acara/Lainnya
— BUKAN 5 tab sesuai asumsi awal; Tiket & Profil ternyata masuk grid menu "Lainnya", bukan tab
sendiri), dan gaya kartu/badge semua disesuaikan ulang setelah user feedback "layout belum sesuai
dengan design artifact nya, mohon di sesuaikan persis sama":
- **Login:** badge ikon olive + logo Easton Park asli (`assets/Easton-logo.png`, dikirim user),
  kartu putih (Selamat Datang → form Nomor WhatsApp + ID BAST/Unit → tombol Masuk → footer "Butuh
  bantuan?" dgn kontak WA/telepon/website).
- **Dashboard:** banner sambutan olive full-width (pengganti app bar), kartu pengumuman acara
  terdekat (bg biru-ungu + tombol "Konfirmasi Kehadiran" navy, otomatis sembunyi kalau tak ada
  acara yang butuh konfirmasi), kartu tagihan & pemakaian air dgn link, kartu info unit.
- **Tagihan:** tab Invoice/Electricity jadi kartu ikon (bukan segmented button generik) + kartu
  "Tagihan Terakhir" di atas daftar.
- **Request (menu Tiket):** dipecah jadi grid kategori dinamis (dari `GET /tiket/tipe`) dgn jumlah
  permintaan per kategori — persis desain — yang mengarah ke daftar tiket terfilter per tipe.
- **Fitur baru "Acara"** (list + konfirmasi kehadiran) dan **"Notifikasi"** (bell icon konsisten di
  semua app bar sub-layar) ditambahkan krn muncul jelas di desain — **endpoint backend
  `/api/v1/acara` dan `/api/v1/notifikasi` BELUM ADA**, jadi kedua fitur ini tampil kosong/gagal-fetch
  di app sampai backend menyusul. Sudah didokumentasikan jelas di komentar kode repository masing-masing.
- **App icon:** digenerate dari ikon daun pada logo resmi (dipotong & dipusatkan pakai
  `flutter_launcher_icons`) — adaptive icon Android (foreground transparan + bg krem `#EDE9E0`) +
  icon iOS (alpha channel dihapus, App Store-compliant).

**Diverifikasi jalan di device Android fisik** (Realme RMX3521, USB debugging) — bukan emulator.
`flutter analyze` bersih di setiap iterasi.

**Isu environment lokal yang ditemukan & difix (bukan bug kode project, dicatat krn kemungkinan
kena lagi kalau setup ulang mesin dev):**
1. **Avast Antivirus SSL/TLS scanning** — root cert Avast dipercaya Windows tapi tidak dipercaya
   Java (JBR bundel Android Studio bahkan tidak punya provider `Windows-ROOT`/`sunmscapi.dll` sama
   sekali). Fix: export root cert Avast dari Windows cert store (`Cert:\LocalMachine\Root`), import
   ke `cacerts` JDK yang dipakai (`keytool -importcert`). Tanpa fix ini, SEMUA download Gradle/Maven
   gagal SSL handshake.
2. **Disk C: berulang kali nyaris/benar-benar penuh** selama build (Android NDK ~2.2GB, Gradle
   caches bengkak ke 9.5GB, ditambah 3.22GB cache installer Visual Studio yang nyangkut di Temp dari
   sesi lama, dan Chrome cache ~5GB) — flutter run gagal dgn "not enough space on the disk". Fix:
   hapus versi NDK yang tidak dipakai project (`flutter.ndkVersion` di `android/app/build.gradle.kts`
   pin ke 1 versi spesifik), hapus cache installer VS lama, hapus Chrome Cache folder, hapus gradle
   wrapper dist versi lama yang tidak dipakai (project pin ke 8.14-all).
3. **2 file dependency besar (`intellij-core-31.11.1.jar`, `kotlin-compiler-31.11.1.jar`, ~88MB
   gabungan) gagal didownload lewat Gradle/Java berkali-kali** (`Read timed out`, bukan soal SSL —
   tetap lambat/gagal meski sudah lewat Avast) — di-download manual via `curl` (jalan normal, <10
   detik) lalu ditaruh manual ke cache Gradle module (`~/.gradle/caches/modules-2/files-2.1/<group>/
   <artifact>/<version>/<sha1-konten-file>/<file>.jar`) supaya Gradle skip network sama sekali utk
   2 file itu.
4. `flutter config --jdk-dir` diset ke JBR Android Studio (`C:\Program Files\Android\Android
   Studio\jbr`, Java 21) — JDK lain yang tersedia di mesin ini (Adoptium JDK 25) TIDAK kompatibel
   dgn Gradle 8.14/AGP (crash "What went wrong: 25" saat start daemon), dan Java 8 lama punya
   cacerts basi/tidak update.

**Belum:** endpoint backend Acara & Notifikasi (lihat di atas), setup Firebase project (push
notif FCM), fitur Tier 2 (bayar langsung, upload KTP/KK dari UI — repository sudah siap tinggal
pasang picker file), grid Request belum pixel-perfect (desain pakai 5 kategori fix dgn ikon
berbeda per kategori, implementasi sekarang pakai 1 ikon generik utk semua kategori dinamis).
