# Mobile — Toko Online Terpadu (Flutter)

Aplikasi customer (Android & iOS) toko busana muslimah **naura**. State management dengan `provider`, HTTP via paket `http`, token disimpan dengan `shared_preferences`, huruf via `google_fonts`.

Fitur: katalog (cari, tab kategori), detail produk (pilih warna & ukuran), keranjang, alamat pengiriman tersimpan (cari kecamatan/kelurahan), checkout dengan pilihan kurir (ongkir RajaOngkir lewat backend), pesanan & instruksi transfer, akun. Navigasi bawah: **Koleksi · Keranjang · Pesanan · Akun**.

## Setup

```bash
flutter pub get
flutter run
```

### Base URL API

Default otomatis:
- **Android emulator** → `http://10.0.2.2:8000/api` (host dari emulator)
- **iOS simulator / desktop** → `http://127.0.0.1:8000/api`

**HP fisik** tidak bisa memakai `10.0.2.2`. Jalankan backend dengan `php artisan serve --host=0.0.0.0 --port=8000`, lalu:

```bash
flutter run --dart-define=API_BASE_URL=http://<IP-komputer>:8000/api
```

Pastikan backend berjalan sebelum membuka aplikasi. Setiap permintaan dibatasi 15 detik; bila server tidak terjangkau, splash menampilkan **Server tidak bisa dihubungi** dengan tombol **Coba lagi** (token tetap tersimpan, tidak perlu login ulang).

> Dev memakai HTTP (cleartext). `android:usesCleartextTraffic="true"` sudah diaktifkan di `AndroidManifest.xml`. Untuk produksi, gunakan HTTPS dan hapus flag tersebut.

## Login / Daftar

Akun customer dari seeder: `customer@naura.test` / `password`.
Atau daftar akun baru lewat tombol **Daftar**.

## Perintah

```bash
flutter pub get          # ambil dependency
flutter analyze          # static analysis
flutter test             # unit/widget test
flutter run              # jalankan di device/emulator
flutter build apk        # build Android APK
flutter build ios        # build iOS (perlu macOS)
```

## Struktur

Model, controller, dan screen dipisah:

```
lib/
├── config/        # base URL API
├── models/        # data + parsing JSON: user, product, category, cart, variant_options,
│                  #   address, destination, shipping_rate, order
├── services/      # panggilan API: api_client (timeout), auth, catalog, cart, address,
│                  #   shipping, order; api_error (pesan error untuk UI)
├── controllers/   # state & logika (ChangeNotifier, tanpa widget): auth, catalog, product_detail,
│                  #   cart, address, destination_search, checkout, orders, order_detail, nav
├── screens/       # UI saja — main_shell (navigasi bawah), home, product_detail, cart,
│                  #   checkout, addresses, address_form, orders, order_detail, account, login…
├── widgets/       # komponen dipakai ulang: product_card, variant_picker, cart_line, total_bar,
│                  #   address_card, rate_option, status_seam, order_row, payment_instructions, …
├── theme/ utils/  # tema naura, format rupiah, kamus warna kain
└── main.dart      # merangkai service → controller
```

Aturan: screen tidak memanggil service langsung dan tidak menangani exception; aksi controller mengembalikan pesan error (`null` = berhasil). Test controller memakai service palsu di `test/fakes/`.
