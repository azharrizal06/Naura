# Toko Online Terpadu (naura)

E-commerce satu toko busana muslimah. Customer belanja lewat **Flutter**; Admin & Owner mengelola toko lewat dashboard **React**; **Laravel 12** REST API (Sanctum Bearer token) + **PostgreSQL 18**.

```
backend/    Laravel API        → backend/README.md (endpoint, aturan, struktur)
dashboard/  React 18 + TS + Vite (Admin & Owner) → dashboard/README.md
mobile/     Flutter 3 (Customer)                 → mobile/README.md
docs/       database-schema.md, deploy.md (panduan deploy gratis)
```

| Role     | Akses                                                          |
| -------- | -------------------------------------------------------------- |
| Customer | Mobile: katalog, keranjang, checkout, pesanan, profil          |
| Admin    | Dashboard: produk/kategori/stok, proses pesanan                |
| Owner    | Admin + laporan omzet, kelola admin, pengaturan toko           |

## Roadmap

| # | Fase                 | Status |
| - | -------------------- | ------ |
| 1 | Fondasi (auth, role, schema) | ✅ |
| 2 | Katalog (produk, varian, stok, foto) | ✅ |
| 3 | Keranjang & checkout (alamat, ongkir RajaOngkir, info toko) | ✅ |
| 4 | Pesanan & pembayaran (transfer manual, batal) | ✅ |
| 5 | Dashboard admin (alur status, resi, ringkasan) | ✅ |
| 6 | Dashboard owner (laporan, admin, pengaturan) | ✅ |
| 7 | Akun & profil (lupa password OTP, profil, ganti password) | ✅ |
| 8 | Testing & deployment (data demo, Docker, deploy gratis) | 🚧 |

## Keputusan produk (jangan diusulkan ulang)

- **Tanpa unggah bukti transfer** — admin mencocokkan mutasi lalu konfirmasi. `payments.proof_path` tidak dipakai.
- **Omzet** = pesanan dibayar (paid → completed) menurut tanggal konfirmasi bayar; batal tidak dihitung.
- **Selesai** bisa ditandai customer ("Pesanan diterima") atau admin. **Batal**: customer saat `pending`; admin saat `pending/paid/processing` (sudah bayar → payment tetap `paid`, refund manual).
- **Kelola admin**: tambah/ubah/nonaktifkan, tanpa hapus permanen.
- **Reset password** via kode 6 digit email; **tanpa verifikasi email** saat daftar.
- **Harga berubah / barang nonaktif** di keranjang → checkout ditolak (422) dan keranjang disamakan; customer tidak ditagih diam-diam.
- **Logo Naura Fashion** (`docs/brand/`): varian teks putih di latar Terong (sidebar & login dashboard, splash & login mobile), berwarna di latar terang (beranda mobile); simbol hijab untuk favicon & ikon Android.
- Identitas visual: palet kain (Kabut `#F3F1F5`, Terong `#2B1830`, Plum `#6E2F63`, Kuningan `#9C7A3C`), Marcellus + Plus Jakarta Sans, swatch dari nama varian ("Mocca / L") — kamus `dashboard/src/lib/swatch.ts` = `mobile/lib/utils/swatch.dart`.

## Status verifikasi (14 Okt 2026)

- Backend 174 test, Flutter 96 test + `analyze` bersih, dashboard `npm run build` hijau.
- Image Docker diuji lokal dengan konfigurasi produksi + PostgreSQL bersih: migrasi, `DemoSeeder`, `/up`, CORS, laporan, pengaman demo jalan.
- RajaOngkir terverifikasi dengan key asli; asal toko Ciperna, Talun, Kab. Cirebon (ID 17131).
- **Belum dicoba langsung**: checkout → pesanan dari aplikasi ke server; layar dashboard Fase 5–8 di browser; layar mobile Fase 4–8 di emulator.

## Fase 8 — demo & deploy (🚧 GitHub ✅ · Neon ✅ · Vercel backend ✅ · Vercel dashboard ✅ · APK ⏳)

- Produksi (15 Okt 2026): API https://naura-api.vercel.app · dashboard https://naura-dashboard.vercel.app · DB Neon `blue-tooth-39169704` branch `production` (Singapore). Env rahasia di Vercel & `.env.local` root (diabaikan git). Berikutnya: build & bagikan APK — langkah di `docs/deploy.md`.
- Data demo: `php artisan migrate:fresh --seed --seeder=DemoSeeder` (±30 produk, 15 customer, ±125 pesanan 60 hari; deterministik; juga untuk reset demo).
- `DEMO_MODE=true` (backend) / `VITE_DEMO_MODE` / `--dart-define=DEMO_MODE=true`: akun demo tampil di login dan tidak bisa dikunci (password/email/reset/nonaktif → 403).
- Server tidur (cold start): mobile splash "Server sedang dinyalakan…" + coba ulang ±1,5 menit, aplikasi membangunkan server saat dibuka; dashboard banner + coba ulang GET.

## Sisa sebelum rilis sungguhan

- SMTP asli (`MAIL_*`; demo memakai `log`) dan cron `schedule:run` (hapus token kedaluwarsa) — Vercel Hobby tanpa cron sesering itu.
- Token dashboard di `localStorage` (rawan bila ada XSS); APK masih ditandatangani kunci debug (perlu keystore untuk Play Store).
- Foto yang diunggah admin perlu penyimpanan permanen (mis. S3/R2) — filesystem Vercel hanya-baca, unggahan admin gagal/hilang. Foto demo aman: statis di `backend/public/demo`.
- Tarif RajaOngkir ikut memuat layanan tak relevan (Dangerous Goods, Kargo, Trucking) — pertimbangkan filter.

## Menjalankan

```bash
# Backend (PHP 8.2+, ekstensi pdo_pgsql/mbstring/openssl/fileinfo/curl)
cd backend && composer install && cp .env.example .env   # isi DB_*, RAJAONGKIR_API_KEY (opsional)
php artisan key:generate && php artisan migrate --seed && php artisan storage:link
php artisan store:shipping-origin "<kecamatan toko>"     # sekali saja
php artisan serve                                         # :8000 (HP fisik: --host=0.0.0.0)

# Dashboard — harus port 5173 (CORS)
cd dashboard && npm install && npm run dev

# Mobile — emulator otomatis http://10.0.2.2:8000/api
cd mobile && flutter pub get && flutter run   # HP fisik: --dart-define=API_BASE_URL=http://<IP>:8000/api
```

Akun seeder (password `password`): `owner@naura.test`, `admin@naura.test`, `customer@naura.test`.

**Masalah yang pernah terjadi**: login dashboard 419 → jangan pasang `statefulApi()`; CORS gagal → Vite pindah ke 5174, kosongkan port 5173; `cURL error 60` di Windows → `curl.cainfo`/`openssl.cafile` di `php.ini` ke `cacert.pem` (jangan matikan SSL); foto 403 → `php artisan storage:link`.

# Aturan Coding

- Baca hanya file yang relevan dengan tugas yang sedang dikerjakan.
- Berikan respons yang singkat, jelas, dan langsung pada inti.
- Hindari refactoring yang tidak diperlukan.
- Pertahankan arsitektur dan konvensi penamaan yang sudah ada.
- Jangan menambahkan dependency baru tanpa alasan yang jelas.
- Gunakan kembali widget, service, dan utilitas yang sudah tersedia.
- Untuk tugas kecil, langsung implementasikan tanpa perencanaan yang panjang.
- Untuk fitur kompleks, buat rencana implementasi singkat terlebih dahulu.
- Jalankan hanya pengujian dan pemeriksaan yang relevan.
- Jangan pernah menyatakan pengujian berhasil jika pengujian tersebut belum benar-benar dijalankan.
- Rangkum file yang diubah dan hasil verifikasi secara singkat.
