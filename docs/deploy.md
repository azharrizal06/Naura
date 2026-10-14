# Deploy demo gratis

Neon (PostgreSQL) → Render (backend Docker) → Vercel (dashboard) → APK → pinger. Semua paket gratis tanpa kartu kredit; login pakai akun GitHub. Ganti `naura-api` / `naura-dashboard` bila nama sudah dipakai orang lain.

Batasan paket gratis: backend tidur setelah 15 menit sepi (bangun ±1 menit — dicegah pinger, langkah 5); foto yang diunggah admin hilang saat container restart (disk tidak permanen); tidak ada cron (token kedaluwarsa tidak dibersihkan otomatis).

## 0. Push ke GitHub (✅ sudah: `github.com/azharrizal06/Naura`, branch `master`)

Untuk perubahan berikutnya cukup `git push`. Pertama kali (repo kosong), dari folder `naura/`:

```bash
git remote add origin https://github.com/<user>/naura.git
git push -u origin master
```

## 1. Neon — database

1. neon.com → **New project**, region **AWS Asia Pacific (Singapore)**, Postgres 17/18.
2. **Connect** → matikan **Connection pooling** → salin connection string, bentuknya
   `postgresql://<user>:<pass>@ep-xxx.ap-southeast-1.aws.neon.tech/neondb?sslmode=require`.
3. Isi data demo dari komputer ini (PowerShell, folder `backend/`):

```powershell
$env:DB_URL = "postgresql://...neon.tech/neondb?sslmode=require"
$env:DB_SSLMODE = "require"
php artisan migrate:fresh --seed --seeder=DemoSeeder --force
Remove-Item Env:DB_URL; Remove-Item Env:DB_SSLMODE
```

Jalankan perintah yang sama kapan pun demo perlu **di-reset** ke kondisi awal (menghapus semua data di Neon).

## 2. Render — backend

1. Buat APP_KEY: `php artisan key:generate --show` (folder `backend/`), salin hasilnya (`base64:...`).
2. render.com → **New → Blueprint** → pilih repo → Render membaca `render.yaml`.
3. Isi nilai yang diminta:
   - `APP_KEY` = hasil langkah 1
   - `DB_URL` = connection string Neon
   - `APP_URL` = `https://naura-api.onrender.com`
   - `CORS_ALLOWED_ORIGINS` = isi sementara `https://naura-dashboard.vercel.app`, perbaiki setelah langkah 3
4. **Apply** → tunggu build (±5–10 menit). Cek `https://naura-api.onrender.com/up` (halaman hijau) dan `.../api/store` (JSON info toko).

## 3. Vercel — dashboard

1. vercel.com → **Add New → Project** → pilih repo.
2. **Root Directory** = `dashboard` (framework terdeteksi Vite).
3. Environment Variables: `VITE_API_BASE_URL` = `https://naura-api.onrender.com/api`, `VITE_DEMO_MODE` = `true`.
4. **Deploy** → salin URL produksi (mis. `https://naura-dashboard.vercel.app`).
5. Kembali ke Render → service `naura-api` → **Environment** → set `CORS_ALLOWED_ORIGINS` ke URL itu persis (tanpa `/` di akhir) → Save (otomatis redeploy).

## 4. APK — aplikasi customer

```bash
cd mobile
flutter build apk --release --dart-define=API_BASE_URL=https://naura-api.onrender.com/api --dart-define=DEMO_MODE=true
```

Hasil: `mobile/build/app/outputs/flutter-apk/app-release.apk`. Bagikan lewat **GitHub → Releases → Draft a new release** (lampirkan APK) atau Google Drive. Penerima perlu mengizinkan "instal dari sumber tidak dikenal". APK ditandatangani kunci debug — cukup untuk demo, tidak untuk Play Store.

## 5. Pinger — agar backend tidak tidur

uptimerobot.com (atau cron-job.org) → **New monitor** → HTTP(s) → URL `https://naura-api.onrender.com/up` → interval **5–10 menit**. `/up` tidak menyentuh database, jadi kuota Neon tidak terpakai. Satu service menyala terus ≈ 744 jam/bulan, masih di bawah kuota 750 jam Render.

## Akun demo (password `password`)

| Peran | Email | Di mana |
| ----- | ----- | ------- |
| Owner | owner@naura.test | dashboard (laporan, admin, pengaturan) |
| Admin | admin@naura.test | dashboard (pesanan, produk) |
| Customer | customer@naura.test | APK |

`DEMO_MODE=true` mencegah pengunjung mengganti password/email akun-akun ini, reset password, atau menonaktifkan admin demo. Fitur lain (checkout, proses pesanan, ubah pengaturan) bisa dicoba — reset dengan langkah 1.3.

## Bila ada masalah

- **Dashboard: "Network Error" / CORS** → `CORS_ALLOWED_ORIGINS` harus sama persis dengan URL Vercel (https, tanpa `/`).
- **Render gagal start** → buka **Logs**; pesan `SQLSTATE` = `DB_URL` salah atau `DB_SSLMODE` bukan `require`.
- **500 setelah ganti env** → Render redeploy otomatis menjalankan ulang `config:cache`; tunggu sampai status **Live**.
- **APK tidak bisa login** → pastikan dibangun dengan `--dart-define=API_BASE_URL=...` dan URL diakhiri `/api`.
