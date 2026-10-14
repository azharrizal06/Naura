# Skema Database — Toko Online Terpadu

Database: **PostgreSQL**. Semua tabel memakai `id bigserial`, `created_at`, `updated_at`. Harga disimpan sebagai **integer (rupiah)** untuk menghindari galat floating-point.

## Diagram Relasi (ringkas)

```
users ──┬─< addresses
        ├─< carts ──< cart_items >── product_variants
        └─< orders ──< order_items
                   ├── payments
                   └── shipments

categories ──< products ──┬─< product_images
                          └─< product_variants

store_settings (singleton)
```

## Tabel

### users
Pengguna sistem (Customer, Admin, Owner).

| kolom              | tipe         | keterangan                               |
|--------------------|--------------|------------------------------------------|
| id                 | bigserial PK |                                          |
| name               | varchar      |                                          |
| email              | varchar uniq |                                          |
| phone              | varchar null |                                          |
| password           | varchar      | hashed (bcrypt)                          |
| role               | varchar      | `customer` \| `admin` \| `owner`         |
| is_active          | boolean      | default true                             |
| email_verified_at  | timestamp    | null                                     |
| remember_token     | varchar null |                                          |
| timestamps         |              |                                          |

### addresses
Alamat pengiriman milik user.

| kolom          | tipe        | keterangan                       |
|----------------|-------------|----------------------------------|
| id             | bigserial PK|                                  |
| user_id        | FK users    | cascade on delete                |
| label          | varchar     | mis. "Rumah", "Kantor"           |
| recipient_name | varchar     |                                  |
| phone          | varchar     |                                  |
| province       | varchar     |                                  |
| city           | varchar     |                                  |
| district       | varchar null|                                  |
| postal_code    | varchar     |                                  |
| address_line   | text        | alamat lengkap                   |
| is_default     | boolean     | default false                    |

### categories
| kolom       | tipe         | keterangan                 |
|-------------|--------------|----------------------------|
| id          | bigserial PK |                            |
| parent_id   | FK categories null | kategori bertingkat  |
| name        | varchar      |                            |
| slug        | varchar uniq |                            |
| description | text null    |                            |
| is_active   | boolean      | default true               |

### products
| kolom        | tipe          | keterangan                          |
|--------------|---------------|-------------------------------------|
| id           | bigserial PK  |                                     |
| category_id  | FK categories |                                     |
| name         | varchar       |                                     |
| slug         | varchar uniq  |                                     |
| description  | text null     |                                     |
| base_price   | integer       | harga dasar (rupiah)                |
| is_active    | boolean       | default true                        |
| weight_grams | integer       | untuk perhitungan ongkir            |

### product_images
| kolom      | tipe        | keterangan                 |
|------------|-------------|----------------------------|
| id         | bigserial PK|                            |
| product_id | FK products | cascade                    |
| path       | varchar     | path storage               |
| is_primary | boolean     | default false              |
| sort_order | integer     | default 0                  |

### product_variants
Varian produk (mis. ukuran/warna). Stok disimpan per-varian.

| kolom       | tipe        | keterangan                        |
|-------------|-------------|-----------------------------------|
| id          | bigserial PK|                                   |
| product_id  | FK products | cascade                           |
| sku         | varchar uniq|                                   |
| name        | varchar     | mis. "Merah / XL"                 |
| price       | integer     | harga varian (override base)      |
| stock       | integer     | default 0                         |
| attributes  | jsonb null  | {"warna":"Merah","ukuran":"XL"}   |
| is_active   | boolean     | default true                      |

### carts
Satu keranjang aktif per user.

| kolom    | tipe       | keterangan        |
|----------|------------|-------------------|
| id       | bigserial PK|                  |
| user_id  | FK users   | uniq, cascade     |

### cart_items
| kolom              | tipe              | keterangan                |
|--------------------|-------------------|---------------------------|
| id                 | bigserial PK      |                           |
| cart_id            | FK carts          | cascade                   |
| product_variant_id | FK product_variants |                         |
| quantity           | integer           | >= 1                      |
| unit_price         | integer           | snapshot harga saat tambah|

### orders
| kolom            | tipe         | keterangan                                           |
|------------------|--------------|------------------------------------------------------|
| id               | bigserial PK |                                                      |
| order_number     | varchar uniq | mis. INV-20261013-0001                               |
| user_id          | FK users     |                                                      |
| address_id       | FK addresses null | snapshot alamat juga disimpan                   |
| status           | varchar      | pending/paid/processing/shipped/completed/cancelled  |
| subtotal         | integer      |                                                      |
| shipping_cost    | integer      |                                                      |
| discount         | integer      | default 0                                            |
| total            | integer      |                                                      |
| shipping_address | jsonb        | snapshot alamat                                      |
| notes            | text null    |                                                      |

### order_items
| kolom              | tipe        | keterangan                      |
|--------------------|-------------|---------------------------------|
| id                 | bigserial PK|                                 |
| order_id           | FK orders   | cascade                         |
| product_variant_id | FK product_variants null | (set null bila varian dihapus) |
| product_name       | varchar     | snapshot                        |
| variant_name       | varchar     | snapshot                        |
| unit_price         | integer     | snapshot                        |
| quantity           | integer     |                                 |
| subtotal           | integer     | unit_price * quantity           |

### payments
| kolom          | tipe        | keterangan                                   |
|----------------|-------------|----------------------------------------------|
| id             | bigserial PK|                                              |
| order_id       | FK orders   | cascade                                      |
| method         | varchar     | manual_transfer/midtrans/cod/...             |
| status         | varchar     | pending/paid/failed/expired/refunded         |
| amount         | integer     |                                              |
| reference      | varchar null| nomor referensi / transaksi gateway          |
| proof_path     | varchar null| bukti transfer (upload manual)               |
| paid_at        | timestamp null |                                           |
| meta           | jsonb null  | payload gateway                              |

### shipments
| kolom           | tipe        | keterangan                               |
|-----------------|-------------|------------------------------------------|
| id              | bigserial PK|                                          |
| order_id        | FK orders   | cascade                                  |
| courier         | varchar null| mis. JNE, J&T                            |
| tracking_number | varchar null|                                          |
| status          | varchar     | preparing/shipped/in_transit/delivered   |
| shipped_at      | timestamp null |                                       |
| delivered_at    | timestamp null |                                       |

### store_settings
Pengaturan toko (singleton, 1 baris).

| kolom           | tipe        | keterangan                      |
|-----------------|-------------|---------------------------------|
| id              | bigserial PK|                                 |
| store_name      | varchar     |                                 |
| store_email     | varchar null|                                 |
| store_phone     | varchar null|                                 |
| store_address   | text null   |                                 |
| currency        | varchar     | default IDR                     |
| flat_shipping_cost | integer  | ongkir flat default (fase awal) |
| bank_accounts   | jsonb null  | daftar rekening transfer        |

## Status Pesanan (alur)

```
pending ─(bayar)→ paid ─(admin proses)→ processing ─(kirim)→ shipped ─(sampai)→ completed
   └────────────────────── cancelled ──────────────────────┘
```
