# Mobile — Flutter (Customer)

`provider`, `http`, `shared_preferences` (token), `google_fonts`. Navigasi bawah: Koleksi · Keranjang · Pesanan · Akun.

Fitur: katalog & detail (warna/ukuran), keranjang, alamat (cari kecamatan RajaOngkir), checkout (kurir + rekening dari `GET /store`), pesanan (instruksi transfer, batal saat belum bayar, "Pesanan diterima"), akun (ubah profil, ganti password, lupa password kode email).

```bash
flutter pub get && flutter run      # emulator Android → http://10.0.2.2:8000/api; iOS/desktop → 127.0.0.1
flutter run --dart-define=API_BASE_URL=http://<IP-komputer>:8000/api   # HP fisik (backend --host=0.0.0.0)
flutter analyze && flutter test     # 96 test
```

Akun seeder: `customer@naura.test` / `password` (terisi otomatis hanya saat debug atau `--dart-define=DEMO_MODE=true`, yang juga menampilkan kotak akun demo). Permintaan timeout 15 detik; server tidur → splash "Server sedang dinyalakan…" dan coba ulang otomatis (±1,5 menit), lalu "Server tidak bisa dihubungi" + Coba lagi. Tanpa token, aplikasi memanggil `/store` untuk membangunkan server. Dev memakai HTTP (`usesCleartextTraffic` di `AndroidManifest.xml`) — hapus untuk produksi.

## Struktur `lib/`

`config/` base URL · `models/` data + `fromJson` · `services/` panggilan API (`api_client` dengan timeout, `api_error`) · `controllers/` ChangeNotifier tanpa widget · `screens/` UI · `widgets/` komponen dipakai ulang · `theme/`, `utils/` (rupiah, kamus warna = dashboard) · `main.dart` merangkai service → controller.

Aturan: screen tidak memanggil service langsung dan tidak menangani exception; aksi controller mengembalikan pesan error (`null` = berhasil). Test controller memakai service palsu di `test/fakes/`.
