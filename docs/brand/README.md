# Logo Naura Fashion

`logo-source.jpeg` (dari WhatsApp, latar putih) → `make-logo.ps1` (PowerShell + System.Drawing, tanpa dependency):

```powershell
.\docs\brand\make-logo.ps1 -Source .\docs\brand\logo-source.jpeg -OutDir $env:TEMP\naura-logo
```

Hasil & tujuan salin:

| Berkas | Dipakai di |
| ------ | ---------- |
| `logo.png` (berwarna, transparan) | mobile `assets/images/logo.png` — latar terang (beranda) |
| `logo-light.png` (teks putih) | dashboard `src/assets/logo-light.png`, mobile `assets/images/logo_light.png` — latar Terong |
| `favicon-64.png`, `icon-512.png` | dashboard `public/favicon.png`, `public/apple-touch-icon.png` |
| `mipmap-*/ic_launcher.png` | mobile `android/app/src/main/res/mipmap-*/` |

Latar dihapus dengan "un-blend dari putih" (tepi tetap halus). Area simbol/kupu-kupu ditentukan dengan pecahan lebar/tinggi logo hasil potong — sesuaikan `InSymbol`/`InButterfly` bila sumber berganti. Sumber hanya ±340 px lebar: minta versi resolusi tinggi/SVG untuk hasil tajam di layar besar.
