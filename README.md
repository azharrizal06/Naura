# Toko Online Terpadu (naura)

Aplikasi e-commerce satu toko (single store) yang terintegrasi antara **mobile app (Flutter)**, **dashboard web (React + TypeScript)**, **backend REST API (Laravel)**, dan **database PostgreSQL**.

- **Customer** berbelanja melalui aplikasi **Flutter**.
- **Admin** & **Owner** mengelola operasional toko melalui dashboard **React**.

## Struktur Monorepo

```
naura/
├── backend/      # Laravel REST API + PostgreSQL
├── dashboard/    # React + TypeScript (Admin & Owner)
├── mobile/       # Flutter (Customer app)
└── docs/         # Dokumentasi (schema DB, API, dll)
```

## Tech Stack

| Komponen      | Teknologi                      |
| ------------- | ------------------------------ |
| Database      | PostgreSQL 18                  |
| Backend       | Laravel 12 (REST API, Sanctum) |
| Dashboard Web | React 18 + TypeScript + Vite   |
| Mobile App    | Flutter 3 (Android & iOS)      |

## Role & Hak Akses

| Role     | Akses                                                       |
| -------- | ----------------------------------------------------------- |
| Customer | Mobile app: katalog, keranjang, checkout, pesanan, profil   |
| Admin    | Dashboard: kelola produk/kategori/stok, proses pesanan      |
| Owner    | Dashboard: semua akses Admin + laporan, omzet, kelola admin |

## Roadmap (Fase)

| #   | Fase                     | Cakupan                                          | Status                        |
| --- | ------------------------ | ------------------------------------------------ | ----------------------------- |
| 1   | **Fondasi Sistem**       | setup proyek, schema DB, auth & role, middleware | ✅ Selesai                    |
| 2   | **Katalog Produk**       | produk, kategori, foto, varian, stok             | ✅ Selesai                    |
| 3   | **Keranjang & Checkout** | cart, alamat, kalkulasi total                    | 🚧 Hampir selesai (sisa: API pengaturan toko) |
| 4   | **Pesanan & Pembayaran** | order, pembayaran, pelacakan                     | 🚧 Sebagian (sisa: bukti transfer, input resi, batal pesanan) |
| 5   | **Dashboard Admin**      | manajemen operasional                            | ⏸️ Belum dimulai              |
| 6   | **Dashboard Owner**      | laporan & analitik                               | ⏸️ Belum dimulai              |
| 7   | **Akun & Profil**        | registrasi, login, reset password, profil        | ⏸️ Belum dimulai              |
| 8   | **Testing & Deployment** | pengujian & rilis                                | ⏸️ Belum dimulai              |

## Progres — Fase 3 & 4 Sedang Dikerjakan (14 Oktober 2026)

### Fase 1 — Fondasi Sistem ✅

- Monorepo `backend/`, `dashboard/`, `mobile/`, `docs/`.
- Backend **Laravel 12** (dinaikkan dari 11 karena advisory keamanan Composer memblokir 11.x) + Sanctum.
- Schema DB lengkap (user, kategori, produk, varian, order, payment, shipment, store settings) + seeder.
- Auth berbasis **Bearer token** (Sanctum personal access token) dan middleware role (`role:admin,owner`).
- Dashboard React: halaman login + layout terproteksi. Mobile Flutter: splash, login, register.

### Fase 2 — Katalog Produk ✅

- **API publik**: `GET /api/catalog/products`, `GET /api/catalog/categories`.
- **API Admin/Owner**: `/api/dashboard/products` & `/api/dashboard/categories` — CRUD, varian, stok, upload foto.
- **Dashboard**: halaman Produk (list, cari, filter, CRUD), Detail Produk (varian & stok), Kategori.
- **Mobile**: grid katalog (cari, tab kategori, infinite scroll) + detail produk (pilih warna & ukuran).

### Identitas visual ✅

- Toko **busana muslimah** (gamis, hijab, atasan, mukena). Palet kain: Kabut `#F3F1F5`, Terong `#2B1830`, Plum `#6E2F63`, Kuningan `#9C7A3C`.
- Huruf: **Marcellus** (logo & judul) + **Plus Jakarta Sans** (teks & angka).
- Swatch warna kain dari nama varian ("Mocca / L") — kamus warna di `dashboard/src/lib/swatch.ts` dan `mobile/lib/utils/swatch.dart` (harus sama).
- Dashboard & mobile didesain ulang; seeder berisi katalog busana muslimah dengan varian warna/ukuran.

### Fase 3 — Keranjang & Checkout 🚧

Selesai:

- **API keranjang** (khusus Customer): `GET /api/cart`, `POST /api/cart/items`, `PATCH|DELETE /api/cart/items/{id}` — gabung varian yang sama, batas stok, tolak varian/produk nonaktif.
- **Mobile**: keranjang (tersimpan di server), checkout (alamat tersimpan, pilihan kurir, transfer bank, ringkasan total), angka jumlah barang di tab Keranjang.
- **Mobile direfactor** ke model / service / controller / screen / widget terpisah (lihat `mobile/README.md`).
- **Alamat pengiriman tersimpan**: `/api/addresses` (CRUD, satu alamat utama). Di aplikasi: menu Akun → Alamat pengiriman, cari kecamatan/kelurahan lalu kolom wilayah terisi otomatis.
- **Ongkir RajaOngkir (Komerce)**: `GET /api/shipping/destinations`, `POST /api/shipping/rates` — berat dari `weight_grams` × jumlah, hasil di-cache (kuota harian terbatas). Checkout menampilkan pilihan kurir (termurah terpilih), dan ongkir **dihitung ulang di server** saat pesanan dibuat. Tanpa API key → satu pilihan "Kurir toko" dengan ongkir flat.

Belum:

- **API pengaturan toko**: rekening bank di layar checkout masih ditulis di kode aplikasi. Bila `store_settings.bank_accounts` diubah, aplikasi harus ikut diubah — kalau tidak, server menolak bank yang dipilih (422).

### Fase 4 — Pesanan & Pembayaran 🚧

Selesai:

- **API pesanan** (khusus Customer): `POST /api/orders` membuat pesanan dari keranjang (snapshot barang & alamat, ongkir, payment transfer + rekening tujuan), mengosongkan keranjang, dan memesan stok — dalam satu transaksi dengan kunci baris stok. `GET /api/orders`, `GET /api/orders/{id}` (hanya milik sendiri).
- **Mobile**: navigasi bawah (Koleksi, Keranjang, Pesanan, Akun), daftar pesanan, detail pesanan dengan garis status, instruksi transfer (salin nomor rekening), info resi.

Belum:

- **Bukti transfer**: customer belum bisa mengunggah bukti (kolom `payments.proof_path` sudah ada).
- **Pembatalan pesanan** + pengembalian stok: belum ada (stok sudah dikurangi saat pesanan dibuat).
- **Pelacakan**: aplikasi sudah menampilkan kurir & resi, tetapi belum ada cara mengisinya — menunggu dashboard admin (Fase 5).
- **Konfirmasi pembayaran** oleh admin (status `pending` → `paid`): Fase 5.
- Alur checkout → pesanan belum dicoba langsung dari aplikasi ke server (baru lewat test).

### Verifikasi

- 71 test backend lulus (`php artisan test`): keranjang 12, pesanan 13, alamat 6, ongkir 16, perintah origin 2. Semua panggilan RajaOngkir di test dipalsukan (`Http::fake`); `phpunit.xml` mengosongkan key agar test tidak memakai kuota.
- Dashboard `npm run build` hijau; Flutter `analyze` bersih + 67 test lulus.
- **RajaOngkir diverifikasi dengan API key asli** (14 Okt 2026): header `key`, body form, kurir gabungan `jne:jnt`, dan pencarian lewat `/api/shipping/destinations` berjalan; key tidak muncul di respons.
- **Lokasi asal toko**: Ciperna, Talun (Cirebon Selatan), Kab. Cirebon — ID RajaOngkir 17131 (`store_settings.shipping_origin_id`). Ongkir end-to-end lewat Laravel terverifikasi, mis. 900 g ke Braga, Bandung: J&T EZ Rp10.000, JNE REG Rp14.000.
- Dicoba langsung: backend (`:8000`), dashboard (`:5173`), dan aplikasi Flutter di emulator Android — katalog tampil dari API.

### Perbaikan saat uji coba

- **Dashboard tidak bisa login (419 CSRF token mismatch)** — `statefulApi()` dihapus dari `backend/bootstrap/app.php`, karena dashboard memakai Bearer token, bukan cookie session.
- **Mobile tertahan di splash pada instalasi baru** — `AuthProvider.bootstrap()` tidak memanggil `notifyListeners()` saat belum ada token; sudah diperbaiki.
- **Sesi hilang saat reload (dashboard & mobile)** — respons `/api/auth/me` dibungkus `data` tetapi dibaca langsung; admin ditolak setelah reload dan customer otomatis logout. Sudah diperbaiki di `AuthContext.tsx` dan `auth_service.dart`.
- **Mobile tertahan di splash saat server mati** — permintaan HTTP tidak punya batas waktu, jadi `/auth/me` menggantung. Sekarang semua permintaan timeout 15 detik dan splash menampilkan "Server tidak bisa dihubungi" + **Coba lagi** (token tetap tersimpan).
- **Panggilan HTTPS dari Laravel gagal (`cURL error 60`)** — PHP lokal tidak punya bundel sertifikat CA. `curl.cainfo` & `openssl.cafile` di `php.ini` diarahkan ke `cacert.pem` di folder PHP (verifikasi SSL tetap aktif).
- **Login dashboard diblokir CORS** — dev server pindah ke port 5174 karena 5173 terpakai; CORS hanya mengizinkan 5173. Pastikan port 5173 kosong sebelum `npm run dev`.

### Catatan untuk lanjut nanti

- Data seeder belum punya foto produk (tampil sebagai lipatan kain berwarna). Foto `/storage/products/placeholder.png` membalas 403 — cek `php artisan storage:link` sebelum upload foto asli.
- DB development lama masih berisi produk contoh sebelumnya; `php artisan migrate:fresh --seed` untuk katalog bersih (menghapus semua data).
- Alamat "Rumah" milik `customer@naura.test` diisi manual sebelum RajaOngkir aktif (belum punya ID wilayah) — ubah di aplikasi dan pilih kecamatan dari pencarian agar ongkir kurir bisa dihitung.
- Daftar tarif RajaOngkir ikut memuat layanan yang tidak relevan untuk busana (POS Dangerous/Valuable Goods, Kargo, JNE Trucking) — pertimbangkan filter layanan.
- Lanjutan: sisa **Fase 3** (API pengaturan toko) dan sisa **Fase 4** (bukti transfer, batal pesanan), lalu **Fase 5 — Dashboard Admin** untuk konfirmasi pembayaran & input resi.

### Akun seeder (development)

| Role     | Email               | Password   |
| -------- | ------------------- | ---------- |
| Owner    | owner@naura.test    | `password` |
| Admin    | admin@naura.test    | `password` |
| Customer | customer@naura.test | `password` |

## Prasyarat Development

| Tool          | Versi minimal | Status di mesin ini  |
| ------------- | ------------- | -------------------- |
| PHP           | 8.2+          | ✅ (8.3, via winget) |
| Composer      | 2.x           | ✅                   |
| Node.js + npm | 20+ / 10+     | ✅ (Node 24)         |
| Flutter       | 3.x           | ✅ (3.41)            |
| PostgreSQL    | 14+           | ✅ (v18)             |

### Cara install PHP + Composer (Windows)

Opsi tercepat — gunakan **Laragon** (sudah bundle PHP, Composer, Node):

1. Download https://laragon.org/download/
2. Install, lalu PHP & Composer otomatis tersedia di PATH.

Atau manual:

1. PHP: https://windows.php.net/download/ (pilih **Thread Safe x64**), ekstrak ke `C:\php`, tambahkan ke PATH.
   Aktifkan ekstensi di `php.ini`: `pdo_pgsql`, `pgsql`, `mbstring`, `openssl`, `fileinfo`, `curl`.
2. Composer: https://getcomposer.org/Composer-Setup.exe

## Menjalankan

Lihat `backend/README.md`, `dashboard/README.md`, dan `mobile/README.md`.

Ringkas:

```bash
# Backend
cd backend
composer install
cp .env.example .env         # isi DB_*, dan RAJAONGKIR_API_KEY bila memakai ongkir kurir
php artisan key:generate
php artisan migrate --seed
php artisan storage:link
php artisan store:shipping-origin "<kecamatan toko>"   # lokasi asal ongkir (sekali saja)
php artisan serve            # http://127.0.0.1:8000
# HP fisik di jaringan yang sama: php artisan serve --host=0.0.0.0 --port=8000

# Dashboard
cd dashboard
npm install
npm run dev                  # http://127.0.0.1:5173

# Mobile
cd mobile
flutter pub get
flutter run                  # Android emulator otomatis memakai http://10.0.2.2:8000/api
# HP fisik: flutter run --dart-define=API_BASE_URL=http://<IP-komputer>:8000/api
```

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
