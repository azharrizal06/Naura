# Backend — Toko Online Terpadu (Laravel REST API)

REST API (Laravel 12) untuk aplikasi e-commerce satu toko. Autentikasi **Laravel Sanctum** (Bearer token untuk mobile Flutter, cookie SPA untuk dashboard React). Database **PostgreSQL**.

## Prasyarat

- PHP **8.2+** dengan ekstensi: `pdo_pgsql`, `pgsql`, `mbstring`, `openssl`, `fileinfo`, `curl`, `ctype`, `bcmath`
- Composer 2.x
- PostgreSQL 14+ (di mesin ini: v18)

## Setup

```bash
# 1. Install dependency
composer install

# 2. Siapkan environment
cp .env.example .env
php artisan key:generate

# 3. Buat database PostgreSQL bernama "naura"
#    (psql ada di: C:\Program Files\PostgreSQL\18\bin\psql.exe)
createdb -U postgres naura
#   atau via psql:  CREATE DATABASE naura;

# 4. Sesuaikan kredensial DB di .env (DB_USERNAME / DB_PASSWORD)

# 5. Migrasi + seed data awal
php artisan migrate --seed

# 6. Symlink storage (agar foto produk dapat diakses publik)
php artisan storage:link

# 7. Jalankan server
php artisan serve         # http://127.0.0.1:8000
```

## Akun Default (hasil seeder)

| Role     | Email               | Password   |
|----------|---------------------|------------|
| Owner    | owner@naura.test    | `password` |
| Admin    | admin@naura.test    | `password` |
| Customer | customer@naura.test | `password` |

## Autentikasi

### Mobile / API client (token)
```http
POST /api/auth/register      # customer baru
POST /api/auth/login         # { email, password, device_name? } -> { token }
GET  /api/auth/me            # Authorization: Bearer <token>
POST /api/auth/logout
POST /api/auth/logout-all
```

Kirim header `Authorization: Bearer <token>` untuk endpoint terproteksi.

### Role & Authorization

Middleware `role:` membatasi akses:

```php
Route::middleware('role:admin,owner')->group(...);  // dashboard
Route::middleware('role:owner')->group(...);        // khusus owner
Route::middleware('role:customer')->group(...);     // khusus customer
```

Endpoint contoh (Fase 1):
- `GET /api/ping/customer` — hanya Customer
- `GET /api/dashboard/ping` — Admin & Owner
- `GET /api/owner/ping` — hanya Owner

## Katalog (Fase 2)

```http
GET /api/catalog/products?q=&category=&page=   # publik
GET /api/catalog/products/{slug}
GET /api/catalog/categories
/api/dashboard/products|categories             # CRUD Admin/Owner + varian, stok, foto
```

## Keranjang (Fase 3, khusus Customer)

```http
GET    /api/cart                      # isi + count, subtotal, shipping_cost, total
POST   /api/cart/items                # { variant_id, quantity? } — digabung bila varian sama
PATCH  /api/cart/items/{id}           # { quantity >= 1 }
DELETE /api/cart/items/{id}
```

- 422 bila jumlah melebihi stok, atau varian/produk nonaktif.
- `unit_price` = snapshot harga saat ditambah; ongkir = `store_settings.flat_shipping_cost` (0 bila kosong).
- Item milik customer lain → 404; Admin/Owner → 403.

## Alamat & Ongkir (Fase 3, khusus Customer)

```http
GET|POST /api/addresses              # alamat pertama otomatis jadi utama
PATCH|DELETE /api/addresses/{id}     # hapus alamat utama → alamat lain jadi utama
GET  /api/shipping/destinations?search=braga   # cari kecamatan/kelurahan (RajaOngkir)
POST /api/shipping/rates { address_id }        # pilihan kurir untuk isi keranjang
```

Konfigurasi `.env`: `RAJAONGKIR_BASE_URL` (`https://rajaongkir.komerce.id/api/v1/`), `RAJAONGKIR_API_KEY` (key **Shipping Cost**, dikirim lewat header `key`, tidak pernah ke client), `RAJAONGKIR_COURIERS` (mis. `jne:jnt:sicepat:pos` — terverifikasi bisa digabung dengan `:`).

Lokasi asal toko disimpan di **`store_settings.shipping_origin_id`**, diisi dari hasil pencarian (ID tidak bisa dikarang):

```bash
php artisan store:shipping-origin "nama kecamatan/kelurahan toko"          # pilih dari daftar
php artisan store:shipping-origin "braga" --id=4949                        # tanpa interaksi
```

`POST /api/shipping/rates` menerima `courier` opsional (harus salah satu kurir toko). Tanpa key/origin → satu pilihan `toko`/`REG` (ongkir flat); pencarian tanpa key → 503 (aplikasi beralih ke isi manual). Rute yang tidak dilayani kurir → daftar kosong; RajaOngkir gagal/timeout (connect 5 dtk, total 10 dtk) → 502. Cache: pencarian 1 hari, tarif 30 menit.

> **Windows/PHP**: bila log berisi `cURL error 60: unable to get local issuer certificate`, isi `curl.cainfo` dan `openssl.cafile` di `php.ini` dengan bundel CA (mis. `cacert.pem`). Jangan mematikan verifikasi SSL.

## Pesanan (Fase 4, khusus Customer)

```http
GET  /api/orders            # milik sendiri, terbaru dulu
POST /api/orders            # { address_id, courier, service, payment_method: manual_transfer, bank, notes? }
GET  /api/orders/{id}       # milik customer lain → 404
```

- Pesanan dibuat dari isi keranjang dalam satu transaksi: snapshot barang & alamat tersimpan, ongkir **dihitung ulang** dari layanan kurir yang dipilih, baris `shipments` (`courier`, `service`, status `preparing`), payment `pending` dengan rekening tujuan (`payments.meta.bank`), keranjang dikosongkan, stok dikurangi.
- 422: keranjang kosong / stok tidak cukup (`cart`), layanan kurir tidak tersedia (`service`), rekening tidak ada di `store_settings.bank_accounts` (`bank`). Alamat milik customer lain → 404.

## Testing

```bash
# Buat database test
createdb -U postgres naura_testing

php artisan test          # 71 test (auth, katalog, manajemen produk, keranjang, alamat, ongkir, pesanan)
```

## Struktur Direktori

```
app/
├── Enums/UserRole.php                 # customer | admin | owner
├── Http/
│   ├── Controllers/Api/               # Auth, Catalog, Cart, Address, Shipping, Order, Admin/* (produk, kategori, varian, foto)
│   ├── Middleware/EnsureUserHasRole.php
│   ├── Requests/                      # Auth/, Catalog/, Cart/, Address/, Shipping/, Order/ — validasi
│   └── Resources/                     # User, Product*, Category, Cart, CartItem, Address, Order
├── Console/Commands/SetShippingOrigin.php  # store:shipping-origin
├── Services/Shipping/                 # RajaOngkir (klien API + cache), ShippingRateService (berat & tarif)
├── Models/                            # User, Product, Order, dst (semua fase)
database/
├── migrations/                        # schema lengkap semua fase
├── factories/                         # User, Category, Product, ProductVariant
└── seeders/DatabaseSeeder.php         # akun default + katalog busana muslimah
routes/api.php                         # endpoint API
tests/Feature/                         # AuthTest, CatalogTest, ProductManagementTest, CartTest, AddressTest, ShippingTest, ShippingOriginCommandTest, OrderTest
```

## Konvensi

- **Harga** disimpan sebagai `integer` (rupiah) — hindari float.
- Response error API selalu JSON `{ "message": ..., "errors"?: {...} }`.
- Validasi via Form Request; transformasi output via API Resource.
