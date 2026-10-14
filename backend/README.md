# Backend — Laravel 12 REST API

Sanctum **Bearer token** untuk mobile & dashboard (tanpa cookie session — jangan pasang `statefulApi()`). PostgreSQL. Error selalu JSON `{ message, errors? }`.

## Setup & test

```bash
composer install && cp .env.example .env && php artisan key:generate
createdb -U postgres naura          # psql: C:\Program Files\PostgreSQL\18\bin
php artisan migrate --seed && php artisan storage:link && php artisan serve
createdb -U postgres naura_testing && php artisan test   # 174 test
```

`.env` penting: `DB_*` (`DB_URL` pooled + `DB_URL_UNPOOLED` direct untuk Neon; migrasi produksi pakai `--database=pgsql_direct`), `APP_TIMEZONE=Asia/Jakarta`, `RAJAONGKIR_API_KEY` (key Shipping Cost, header `key`), `RAJAONGKIR_COURIERS` (mis. `jne:jnt:sicepat:pos`), `SANCTUM_TOKEN_EXPIRATION` (menit, default 43200 = 30 hari), `CORS_ALLOWED_ORIGINS`, `MAIL_MAILER=log` (dev: email masuk `storage/logs/laravel.log`), `DEMO_MODE` (lindungi akun demo), `DB_SSLMODE` (`require` untuk Neon), `TRUSTED_PROXIES` (`*` di Render).

## Endpoint (`/api`)

```http
# Publik (auth/* kena throttle:auth)
POST /auth/register | /auth/login | /auth/forgot-password {email} | /auth/reset-password {email,code,password,password_confirmation}
GET  /catalog/products?q=&category=&sort=&per_page= | /catalog/products/{slug} | /catalog/categories
GET  /store                                   # info toko + bank_accounts[{bank,number,holder}]

# Login (auth:sanctum + active)
GET /auth/me · POST /auth/logout | /auth/logout-all
PATCH /auth/profile {name?,phone?,email?,current_password? (wajib bila email diganti)}
PUT   /auth/password {current_password,password,password_confirmation}

# role:customer
GET /cart · POST /cart/items {variant_id,quantity?} · PATCH|DELETE /cart/items/{id}
GET|POST /addresses · PATCH|DELETE /addresses/{id}
GET /shipping/destinations?search= · POST /shipping/rates {address_id,courier?}   # + throttle:shipping
GET|POST /orders {address_id,courier,service,payment_method:manual_transfer,bank,notes?} · GET /orders/{id}
POST /orders/{id}/cancel (pending) · POST /orders/{id}/complete (shipped)

# role:admin,owner — prefix /dashboard
apiResource products, categories · products/{p}/variants (CRUD, PATCH …/stock) · products/{p}/images (POST, PATCH …/primary, DELETE)
GET summary                                   # orders_today, awaiting_payment, to_process, to_ship (+ revenue_this_month untuk owner)
GET orders?status=&q= · GET orders/{id}
POST orders/{id}/confirm-payment | process | ship {tracking_number,courier?} | complete | cancel

# role:owner — prefix /owner
GET reports/sales?from=&to=                   # default 30 hari, maks 366
GET|POST admins · PATCH admins/{id} {name?,email?,phone?,password?,is_active?}
GET|PATCH settings {store_name,store_email?,store_phone?,store_address?,flat_shipping_cost,bank_accounts[]}
```

## Aturan bisnis

- **Status pesanan** hanya lewat `Services/Orders/OrderWorkflow` (kunci baris, salah urutan → 422 `order`): `pending → paid → processing → shipped → completed`; batal customer dari `pending`, admin dari `pending/paid/processing`. Stok dikurangi saat dibuat, dikembalikan saat batal. Batal sesudah bayar → payment tetap `paid`.
- **Checkout** (`OrderController::store`, satu transaksi + `lockForUpdate` varian): harga dari varian saat itu; harga keranjang beda / barang nonaktif → 422 `cart` dan keranjang disamakan; ongkir dihitung ulang server; rekening harus ada di `store_settings.bank_accounts` (disimpan di `payments.meta.bank`).
- **Ongkir**: tanpa key/origin → satu pilihan `toko`/`REG` (ongkir flat); pencarian tanpa key → 503; RajaOngkir gagal → 502. Cache pencarian 1 hari, tarif 30 menit. Asal toko di `store_settings.shipping_origin_id` via `php artisan store:shipping-origin "<kecamatan>" [--id=]`.
- **Omzet** (`Services/Reports/SalesReport`): pesanan paid–completed menurut `payments.paid_at`; `cancelled` dihitung menurut tanggal dibuat.
- **Reset password**: kode 6 digit ter-hash di `password_reset_tokens` (+`attempts`), 15 menit, sekali pakai, hangus setelah 5 salah; jawaban forgot selalu sama; berhasil → semua token dicabut. Ganti password → token lain dicabut. Admin dinonaktifkan → tokennya dicabut; akun nonaktif → 403 di semua rute login (middleware `active`).
- **Nomor pesanan** berurutan per hari `INV-YYYYMMDD-NNNN` (`Order::generateNumber`, advisory lock — panggil di dalam transaksi).
- **DEMO_MODE** (`config/demo.php`, `Support/Demo`): akun demo tidak bisa ganti password/email, menerima kode reset, atau dinonaktifkan → 403.
- **Kelola admin** hanya akun ber-role admin (owner/customer → 404). **Pengaturan**: nama bank unik, nomor 4–30 digit; `shipping_origin_*` tidak bisa diubah lewat API.
- **Rate limit** (`AppServiceProvider`): api 120/mnt per user/IP; `auth` 5/mnt per email+IP & 20/mnt per IP; `shipping` 30/mnt per user → 429 + `Retry-After`.

## Konvensi

- Harga `integer` rupiah. Validasi di Form Request, output via API Resource.
- Paginasi: `$this->perPage($request, $default)` (dijepit 1–100).
- PostgreSQL tidak mengindeks FK otomatis — kolom FK baru wajib `->index()`.
- `jsonb` mengacak urutan key — resource menyusun ulang bila urutan penting.
- Test waktu: `Carbon::parse('…', 'UTC')` karena aplikasi WIB. RajaOngkir di test selalu `Http::fake` (`phpunit.xml` mengosongkan key).
- Windows `cURL error 60` → set `curl.cainfo`/`openssl.cafile` di `php.ini`, jangan matikan SSL.

## Struktur

`app/Http/Controllers/Api` (+`Admin/`, `Owner/`) · `Http/Requests/{Auth,Catalog,Cart,Address,Shipping,Order,Owner}` · `Http/Resources` · `Http/Middleware/{EnsureUserHasRole,EnsureUserIsActive}` · `Services/{Orders,Reports,Shipping}` · `Notifications/PasswordResetCode` · `Console/Commands/SetShippingOrigin` · `tests/Feature/*Test.php` (satu file per modul). Seeder: akun default + katalog busana muslimah.

## Deploy & demo

Gambar produk: URL dari host permintaan (`asset()`, bukan `APP_URL`) agar terjangkau dari HP/emulator. Gambar demo: `php artisan demo:images [--force]` (butuh GD; hasil di-commit).

`Dockerfile` (php:8.3-apache, `docker/entrypoint.sh`: Apache di `$PORT`, `config:cache`, `migrate --force`) + `render.yaml` di root. Data demo: `php artisan migrate:fresh --seed --seeder=DemoSeeder` (deterministik, juga untuk reset). Langkah lengkap: `docs/deploy.md`.
