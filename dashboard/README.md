# Dashboard — Toko Online Terpadu (React + TypeScript)

Dashboard web untuk **Admin** dan **Owner**. Dibangun dengan Vite + React 18 + TypeScript. Autentikasi via token Sanctum ke backend Laravel.

## Setup

```bash
npm install
cp .env.example .env     # set VITE_API_BASE_URL (default http://127.0.0.1:8000/api)
npm run dev              # http://127.0.0.1:5173
```

Pastikan backend berjalan (`php artisan serve`) sebelum login.

## Login

Gunakan akun Admin/Owner dari seeder backend:

| Role  | Email            | Password   |
|-------|------------------|------------|
| Owner | owner@naura.test | `password` |
| Admin | admin@naura.test | `password` |

Akun Customer **tidak** bisa masuk dashboard (ditolak di `ProtectedRoute`).

## Perintah

```bash
npm run dev       # dev server
npm run build     # type-check + build produksi (dist/)
npm run preview   # preview hasil build
```

## Struktur

```
src/
├── lib/
│   ├── api.ts              # axios + interceptor Bearer token
│   ├── catalog.ts          # API produk, kategori, varian, stok
│   ├── format.ts           # format rupiah
│   └── swatch.ts           # kamus warna kain (sama dengan mobile)
├── auth/
│   ├── AuthContext.tsx     # state login, me(), logout()
│   └── ProtectedRoute.tsx  # guard rute berdasarkan role
├── components/             # Modal, Spinner, Swatch (Status, Stock, Thumb)
├── layouts/DashboardLayout.tsx  # sidebar + info user
├── pages/
│   ├── LoginPage.tsx
│   ├── DashboardHome.tsx       # ringkasan (jumlah produk aktif)
│   ├── ProductsPage.tsx        # list, cari, filter, CRUD
│   ├── ProductDetailPage.tsx   # warna tersedia, varian & stok
│   ├── CategoriesPage.tsx
│   └── PlaceholderPage.tsx     # modul yang belum dibuat
├── index.css               # token warna & tipografi naura
├── types.ts
└── App.tsx                 # definisi rute
```

## Routing & Role

- `/login` — publik
- `/`, `/products`, `/products/:id`, `/categories`, `/orders` — Admin & Owner
- `/reports`, `/settings` — khusus Owner

Produk & kategori (Fase 2) sudah aktif. Pesanan (Fase 4–5) dan laporan/pengaturan (Fase 6) masih placeholder.

> Dev server harus di port **5173** — CORS backend hanya mengizinkan origin itu. Bila Vite pindah ke 5174, hentikan proses lain di 5173 lalu jalankan ulang.
