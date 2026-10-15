# Deploy demo gratis

Neon (PostgreSQL) → Vercel (backend PHP + dashboard) → APK. Semua paket gratis tanpa kartu kredit. Produksi: API `https://naura-api.vercel.app`, dashboard `https://naura-dashboard.vercel.app` (Singapore).

Batasan: filesystem Vercel hanya-baca (kecuali `/tmp`) → foto yang diunggah admin tidak tersimpan permanen (foto demo aman, statis di `public/demo`); tidak ada cron (token kedaluwarsa tidak dibersihkan otomatis). Server tidak tidur, hanya cold start ±1–3 detik — pinger tidak perlu.

## 0. Push ke GitHub (✅ sudah: `github.com/azharrizal06/Naura`, branch `master`)

Untuk perubahan berikutnya cukup `git push`. Pertama kali (repo kosong), dari folder `naura/`:

```bash
git remote add origin https://github.com/<user>/naura.git
git push -u origin master
```

## 1. Neon — database (✅ sudah: project `blue-tooth-39169704`, branch `production`, Singapore, data demo terisi)

Disiapkan dengan Neon CLI (`neon.ts` + `.neon` di root): `neon login` → `neon deploy` menulis `DATABASE_URL` (pooled) dan `DATABASE_URL_UNPOOLED` (direct) ke `.env.local` di root (diabaikan git — **rahasia**).

Laravel: `DB_URL` = pooled (aplikasi), `DB_URL_UNPOOLED` = direct (migrasi/seeder, koneksi `pgsql_direct`).

**Reset demo** ke kondisi awal (menghapus semua data di Neon), dari root repo (Git Bash):

```bash
set -a && . ./.env.local && set +a && cd backend && \
DB_URL="$DATABASE_URL" DB_URL_UNPOOLED="$DATABASE_URL_UNPOOLED" DB_SSLMODE=require \
php artisan migrate:fresh --database=pgsql_direct --seed --seeder=DemoSeeder --force
```

## 2. Vercel — backend (✅ `naura-api`)

Runtime `vercel-php` (`backend/vercel.json`, `backend/api/index.php`); env non-rahasia ada di `vercel.json`. CLI: `npm i -g vercel` → `vercel login`, lalu dari `backend/`:

```bash
vercel link --yes --project naura-api
vercel env add APP_KEY production --sensitive        # php artisan key:generate --show
vercel env add DB_URL production --sensitive         # DATABASE_URL (pooled) + endpoint ID, lihat bawah
vercel env add DB_URL_UNPOOLED production --sensitive
vercel env add APP_URL production                    # https://naura-api.vercel.app
vercel env add CORS_ALLOWED_ORIGINS production       # https://naura-dashboard.vercel.app
vercel deploy --prod
```

**Wajib untuk Neon**: libpq di runtime Vercel tidak mendukung SNI → password di `DB_URL*` diberi awalan endpoint ID: `postgresql://user:endpoint%3Dep-xxx%3B<password>@ep-xxx-pooler...` (ID = bagian pertama host tanpa `-pooler`). `DB_DISABLE_PREPARES=true` (di `vercel.json`) wajib untuk koneksi pooled — prepared statement bernama gagal di dalam transaksi PgBouncer.

Cek: `/up` (200), `/api/store`, `/api/catalog/products`. Alternatif tanpa Vercel: `render.yaml` + `backend/Dockerfile` (Render, perlu kartu).

## 3. Vercel — dashboard (✅ `naura-dashboard`)

Dari `dashboard/`: `vercel link --yes --project naura-dashboard`, env `VITE_API_BASE_URL=https://naura-api.vercel.app/api` dan `VITE_DEMO_MODE=true` (production), lalu `vercel deploy --prod`. Env `VITE_*` tertanam saat build → ubah env = deploy ulang.

## 4. APK — aplikasi customer

```bash
cd mobile
flutter build apk --release --dart-define=API_BASE_URL=https://naura-api.vercel.app/api --dart-define=DEMO_MODE=true
```

Hasil: `mobile/build/app/outputs/flutter-apk/app-release.apk`. Bagikan lewat **GitHub → Releases** (lampirkan APK) atau Google Drive. Penerima perlu mengizinkan "instal dari sumber tidak dikenal". APK ditandatangani kunci debug — cukup untuk demo, tidak untuk Play Store.

## Akun demo (password `password`)

| Peran | Email | Di mana |
| ----- | ----- | ------- |
| Owner | owner@naura.test | dashboard (laporan, admin, pengaturan) |
| Admin | admin@naura.test | dashboard (pesanan, produk) |
| Customer | customer@naura.test | APK |

`DEMO_MODE=true` mencegah pengunjung mengganti password/email akun-akun ini, reset password, atau menonaktifkan admin demo. Fitur lain (checkout, proses pesanan, ubah pengaturan) bisa dicoba — reset dengan langkah 1.

## Bila ada masalah

- **Dashboard: "Network Error" / CORS** → `CORS_ALLOWED_ORIGINS` harus sama persis dengan URL Vercel (https, tanpa `/`).
- **500 di Vercel** → log terpotong; deploy preview (terproteksi) dengan `vercel deploy -e APP_DEBUG=true -e ...` lalu `vercel curl <url>/api/store` untuk melihat pesan error. Ubah env = `vercel deploy --prod` ulang.
- **APK tidak bisa login** → pastikan dibangun dengan `--dart-define=API_BASE_URL=...` dan URL diakhiri `/api`.
