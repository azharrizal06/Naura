# Skema Database (PostgreSQL)

Semua tabel punya `id bigserial`, `created_at`, `updated_at`. Harga **integer rupiah**. `?` = nullable. FK berindeks (PostgreSQL tidak otomatis).

```
users ─< addresses · users ─ carts ─< cart_items >─ product_variants
users ─< orders ─< order_items · orders ─ payments (1:1) · orders ─ shipments (1:1)
categories ─< products ─< product_images, product_variants · store_settings (1 baris)
```

| Tabel | Kolom |
| ----- | ----- |
| users | name, email (uniq), phone?, password (hash), role `customer\|admin\|owner`, is_active (true), email_verified_at? (belum dipakai), remember_token? |
| password_reset_tokens | email (PK), token (hash kode 6 digit), attempts, created_at |
| addresses | user_id (cascade), label, recipient_name, phone, province, city, district? (kecamatan), subdistrict? (kelurahan), postal_code, destination_id? (ID RajaOngkir), address_line, is_default |
| categories | parent_id?, name, slug (uniq), description?, is_active |
| products | category_id, name, slug (uniq), description?, base_price, is_active, weight_grams |
| product_images | product_id (cascade), path, is_primary, sort_order |
| product_variants | product_id (cascade), sku (uniq), name ("Merah / XL"), price, stock, attributes? jsonb, is_active |
| carts | user_id (uniq, cascade) |
| cart_items | cart_id (cascade), product_variant_id (cascade), quantity ≥ 1, unit_price (disamakan ke harga varian saat checkout) |
| orders | order_number (uniq, `INV-YYYYMMDD-NNNN`), user_id, address_id?, status (lihat alur), subtotal, shipping_cost, discount, total, shipping_address jsonb (snapshot), notes? |
| order_items | order_id (cascade), product_variant_id? (null bila varian dihapus), product_name, variant_name, unit_price, quantity, subtotal — snapshot |
| payments | order_id (uniq), method `manual_transfer`, status `pending\|paid\|cancelled` (+failed/expired/refunded cadangan), amount, reference?, proof_path? (tidak dipakai), paid_at?, meta? jsonb (`bank` tujuan) |
| shipments | order_id (uniq), courier? (`jne`, `jnt`, `toko`), service? (`REG`), tracking_number?, status `preparing\|shipped\|delivered`, shipped_at?, delivered_at? |
| store_settings | store_name, store_email?, store_phone?, store_address?, currency (IDR), flat_shipping_cost, shipping_origin_id?, shipping_origin_label?, bank_accounts? jsonb `[{bank,number,holder}]` |

## Alur status pesanan

```
pending ─(admin konfirmasi bayar)→ paid ─(proses)→ processing ─(resi)→ shipped ─(customer/admin diterima)→ completed
pending ─(customer/admin)→ cancelled · paid/processing ─(admin)→ cancelled
```

- `paid`: payment `paid` + `paid_at`. `shipped`: resi + `shipped_at`. `completed`: shipment `delivered` + `delivered_at`.
- Stok dikurangi saat dibuat, dikembalikan saat batal. Batal saat `pending` → payment `cancelled`; batal setelah bayar → payment tetap `paid` (refund manual).
