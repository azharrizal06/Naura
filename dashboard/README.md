# Dashboard — React 18 + TS + Vite (Admin & Owner)

```bash
npm install && cp .env.example .env   # VITE_API_BASE_URL, VITE_DEMO_MODE (true = akun demo di halaman masuk)
npm run dev      # harus port 5173 (CORS backend); bila pindah ke 5174, kosongkan 5173
npm run build    # type-check + build
```

Login: `owner@naura.test` / `admin@naura.test`, password `password` (terisi otomatis hanya saat dev/demo). Customer ditolak (`ProtectedRoute`). Permintaan lambat >4 dtk → `ServerWakeBanner` "Server sedang dinyalakan…"; GET yang gagal karena server belum siap dicoba ulang (`lib/api.ts`). Deploy Vercel: `vercel.json` (rewrite SPA).

## Rute

- Publik: `/login`, `/forgot-password`
- Admin & Owner: `/`, `/products`, `/products/:id`, `/categories`, `/orders` (`?status=`), `/orders/:id`, `/profile` (klik nama di sidebar)
- Owner: `/reports`, `/admins`, `/settings`

## Struktur `src/`

- `lib/` — `api.ts` (axios + Bearer token + `apiErrorMessage`), `catalog.ts`, `orders.ts`, `owner.ts`, `account.ts`, `format.ts` (rupiah, tanggal), `swatch.ts` (kamus warna = mobile)
- `auth/` — `AuthContext` (user, login, logout, setUser), `ProtectedRoute`
- `components/` — Modal, Spinner, Swatch (Status, Stock, Thumb), OrderStatusBadge, DailySalesChart (SVG tanpa library), LoginPanel
- `pages/` — satu file per rute; `layouts/DashboardLayout.tsx` (sidebar); `index.css` (token warna & tipografi); `types.ts`

Konvensi: panggilan API hanya di `lib/`; error ditampilkan lewat `apiErrorMessage(err, fallback)`; konfirmasi aksi berbahaya pakai `confirm()` atau `Modal`.
