<?php

namespace Database\Seeders;

use App\Enums\UserRole;
use App\Models\Address;
use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\StoreSetting;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Data demo "toko ramai 60 hari": ±30 produk, 15 customer, ±120 pesanan di semua status.
 * Deterministik (mt_srand) dan relatif terhadap hari dijalankan — laporan selalu terisi.
 *
 *   php artisan migrate:fresh --seed --seeder=DemoSeeder
 */
class DemoSeeder extends Seeder
{
    private const SEED = 2026;

    private const DAYS = 60;

    private const ORDERS = 120;

    private const BANKS = [
        ['bank' => 'BCA', 'number' => '1234567890', 'holder' => 'Toko Naura'],
        ['bank' => 'Mandiri', 'number' => '0987654321', 'holder' => 'Toko Naura'],
        ['bank' => 'BSI', 'number' => '7123456789', 'holder' => 'Toko Naura'],
    ];

    /** kategori => [nama => [harga, [warna], [ukuran], berat gram]] — warna dari kamus swatch. */
    private const CATALOG = [
        'Gamis' => [
            'Gamis Ceruti Alesha' => [289000, ['Mocca', 'Dusty Pink', 'Hitam'], ['M', 'L', 'XL'], 450],
            'Gamis Linen Raya' => [325000, ['Sage', 'Milo', 'Navy'], ['M', 'L', 'XL'], 500],
            'Gamis Crinkle Aira' => [259000, ['Lilac', 'Army', 'Broken White'], ['M', 'L', 'XL'], 420],
            'Gamis Polo Syifa' => [215000, ['Maroon', 'Navy', 'Abu'], ['M', 'L', 'XL'], 430],
            'Gamis Satin Kayla' => [349000, ['Emerald', 'Taro', 'Hitam'], ['M', 'L', 'XL'], 480],
            'Abaya Hitam Madinah' => [399000, ['Hitam'], ['M', 'L', 'XL'], 550],
            'Gamis Anak Zahra' => [145000, ['Dusty Pink', 'Mint', 'Lilac'], ['S', 'M'], 250],
        ],
        'Hijab' => [
            'Pashmina Voal Nadia' => [69000, ['Taro', 'Army', 'Broken White', 'Maroon'], [], 150],
            'Bergo Jersey Instan' => [55000, ['Hitam', 'Coksu', 'Abu'], [], 140],
            'Segi Empat Paris Premium' => [39000, ['Mocca', 'Sage', 'Navy', 'Mustard', 'Putih'], [], 100],
            'Pashmina Ceruti Babydoll' => [59000, ['Dusty Pink', 'Lavender', 'Cream'], [], 120],
            'Khimar Syar\'i Wolfis' => [89000, ['Hitam', 'Milo', 'Army'], [], 200],
            'Bergo Maryam Tali' => [49000, ['Navy', 'Maroon', 'Tosca'], [], 130],
            'Inner Ninja Rajut' => [25000, ['Hitam', 'Putih', 'Coksu'], [], 60],
        ],
        'Atasan' => [
            'Tunik Katun Salma' => [175000, ['Olive', 'Mustard', 'Putih'], ['M', 'L'], 300],
            'Blouse Rayon Hana' => [139000, ['Sage', 'Dusty Blue', 'Krem'], ['M', 'L', 'XL'], 250],
            'Kemeja Linen Laila' => [199000, ['Broken White', 'Khaki', 'Navy'], ['M', 'L', 'XL'], 320],
            'Outer Rajut Nisa' => [165000, ['Abu', 'Mocca', 'Terracotta'], ['All Size'], 350],
            'Cardigan Panjang Wardah' => [185000, ['Hitam', 'Milo', 'Sage'], ['All Size'], 380],
        ],
        'Bawahan' => [
            'Rok Plisket Premium' => [119000, ['Hitam', 'Mocca', 'Navy', 'Sage'], ['All Size'], 280],
            'Kulot Linen Rania' => [149000, ['Krem', 'Hitam', 'Olive'], ['M', 'L', 'XL'], 300],
            'Rok Span Jersey' => [99000, ['Hitam', 'Abu', 'Navy'], ['M', 'L'], 220],
            'Celana Kulot Highwaist' => [129000, ['Coksu', 'Hitam', 'Army'], ['M', 'L', 'XL'], 300],
        ],
        'Mukena' => [
            'Mukena Rayon Bali Kirana' => [235000, ['Lilac', 'Putih', 'Sage'], [], 600],
            'Mukena Katun Jepang Aisyah' => [289000, ['Putih', 'Cream', 'Dusty Pink'], [], 650],
            'Mukena Traveling Parasut' => [179000, ['Navy', 'Maroon', 'Abu'], [], 400],
            'Mukena Anak Bordir Mini' => [129000, ['Putih', 'Peach', 'Mint'], ['S', 'M'], 300],
            'Sajadah Travel Lipat' => [65000, ['Hijau', 'Maroon', 'Biru'], [], 250],
        ],
    ];

    /** [nama, kota, provinsi, kecamatan, kelurahan, kode pos] */
    private const CUSTOMERS = [
        ['Budi Customer', 'Bandung', 'Jawa Barat', 'Sumur Bandung', 'Braga', '40111'],
        ['Siti Aminah', 'Cirebon', 'Jawa Barat', 'Kejaksan', 'Kesenden', '45121'],
        ['Rina Kartika', 'Bandung', 'Jawa Barat', 'Coblong', 'Dago', '40135'],
        ['Dewi Lestari', 'Bekasi', 'Jawa Barat', 'Bekasi Selatan', 'Kayuringin Jaya', '17144'],
        ['Fitri Handayani', 'Bogor', 'Jawa Barat', 'Bogor Tengah', 'Paledang', '16122'],
        ['Nurul Hidayah', 'Jakarta Selatan', 'DKI Jakarta', 'Tebet', 'Tebet Barat', '12810'],
        ['Aulia Rahma', 'Depok', 'Jawa Barat', 'Beji', 'Kemiri Muka', '16423'],
        ['Indah Permata', 'Semarang', 'Jawa Tengah', 'Semarang Tengah', 'Pekunden', '50134'],
        ['Laila Sari', 'Yogyakarta', 'DI Yogyakarta', 'Gondokusuman', 'Terban', '55223'],
        ['Maya Fauziah', 'Tasikmalaya', 'Jawa Barat', 'Cihideung', 'Tugujaya', '46126'],
        ['Annisa Putri', 'Kuningan', 'Jawa Barat', 'Kuningan', 'Cijoho', '45513'],
        ['Hana Zulfa', 'Surabaya', 'Jawa Timur', 'Gubeng', 'Airlangga', '60286'],
        ['Yuni Astuti', 'Majalengka', 'Jawa Barat', 'Majalengka', 'Majalengka Kulon', '45418'],
        ['Rahmawati', 'Indramayu', 'Jawa Barat', 'Indramayu', 'Lemahmekar', '45212'],
        ['Salsabila', 'Jakarta Timur', 'DKI Jakarta', 'Duren Sawit', 'Pondok Bambu', '13430'],
    ];

    private const COURIERS = [['jne', 'REG'], ['jnt', 'EZ'], ['sicepat', 'REG'], ['jne', 'YES']];

    public function run(): void
    {
        mt_srand(self::SEED);

        DB::transaction(function () {
            $this->seedStore();
            $variants = $this->seedCatalog();
            $customers = $this->seedCustomers();
            $this->seedOrders($customers, $variants);
        });
    }

    private function seedStore(): void
    {
        StoreSetting::current()->update([
            'store_name' => 'Naura Fashion',
            'store_email' => 'cs@naura.test',
            'store_phone' => '0812-2000-1234',
            'store_address' => 'Jl. Sunan Gunung Jati No. 12, Ciperna, Talun, Kab. Cirebon',
            'currency' => 'IDR',
            'flat_shipping_cost' => 15000,
            'shipping_origin_id' => 17131,
            'shipping_origin_label' => 'CIPERNA, TALUN (CIREBON SELATAN), CIREBON, JAWA BARAT, 45171',
            'bank_accounts' => self::BANKS,
        ]);

        foreach ([
            ['owner@naura.test', 'Hj. Nur Aisyah', UserRole::Owner, '081200000001'],
            ['admin@naura.test', 'Admin Toko', UserRole::Admin, '081200000002'],
            ['admin2@naura.test', 'Rizka (Admin Gudang)', UserRole::Admin, '081200000004'],
        ] as [$email, $name, $role, $phone]) {
            User::updateOrCreate(['email' => $email], [
                'name' => $name, 'password' => 'password', 'role' => $role->value, 'phone' => $phone, 'is_active' => true,
            ]);
        }
    }

    /** @return list<ProductVariant> varian aktif */
    private function seedCatalog(): array
    {
        $variants = [];
        foreach (self::CATALOG as $categoryName => $products) {
            $category = Category::updateOrCreate(['slug' => Str::slug($categoryName)], ['name' => $categoryName, 'is_active' => true]);

            foreach ($products as $name => [$price, $colors, $sizes, $weight]) {
                $product = Product::updateOrCreate(['slug' => Str::slug($name)], [
                    'category_id' => $category->id,
                    'name' => $name,
                    'description' => 'Bahan adem, jatuh lembut, dan tidak menerawang. Nyaman dipakai seharian, dari kajian sampai kondangan.',
                    'base_price' => $price,
                    'weight_grams' => $weight,
                    'is_active' => true,
                ]);

                $i = 0;
                foreach ($colors as $color) {
                    foreach ($sizes ?: [null] as $size) {
                        $i++;
                        $variants[] = ProductVariant::updateOrCreate(['sku' => Str::upper(Str::slug($name)).'-'.$i], [
                            'product_id' => $product->id,
                            'name' => $size ? "{$color} / {$size}" : $color,
                            'price' => $price + ($size === 'XL' ? 15000 : 0),
                            // Sebagian habis/menipis agar label stok terlihat.
                            'stock' => [0, 3, 8, 15, 24, 24, 40, 40][mt_rand(0, 7)],
                            'attributes' => array_filter(['warna' => $color, 'ukuran' => $size]),
                            'is_active' => true,
                        ]);
                    }
                }
            }
        }

        return $variants;
    }

    /** @return list<User> */
    private function seedCustomers(): array
    {
        $customers = [];
        foreach (self::CUSTOMERS as $i => [$name, $city, $province, $district, $subdistrict, $postal]) {
            $email = $i === 0 ? 'customer@naura.test' : Str::slug(Str::before($name, ' ').' '.($i + 1), '.').'@contoh.test';
            $user = User::updateOrCreate(['email' => $email], [
                'name' => $name,
                'password' => 'password',
                'role' => UserRole::Customer->value,
                'phone' => '0813'.str_pad((string) (40000000 + $i * 7919), 8, '0', STR_PAD_LEFT),
                'is_active' => true,
            ]);
            Address::updateOrCreate(['user_id' => $user->id, 'label' => 'Rumah'], [
                'recipient_name' => $name,
                'phone' => $user->phone,
                'province' => $province,
                'city' => $city,
                'district' => $district,
                'subdistrict' => $subdistrict,
                'postal_code' => $postal,
                'address_line' => 'Jl. Melati No. '.mt_rand(1, 120).', RT 0'.mt_rand(1, 9).'/RW 0'.mt_rand(1, 9),
                'is_default' => true,
            ]);
            $customers[] = $user;
        }

        return $customers;
    }

    /**
     * @param  list<User>  $customers
     * @param  list<ProductVariant>  $variants
     */
    private function seedOrders(array $customers, array $variants): void
    {
        $now = CarbonImmutable::now();
        $plans = [];
        for ($n = 0; $n < self::ORDERS; $n++) {
            // Lebih banyak pesanan di minggu-minggu terakhir (toko sedang tumbuh).
            $daysAgo = (int) floor(self::DAYS * (mt_rand(0, 1000) / 1000) ** 1.6);
            $createdAt = $now->subDays($daysAgo)->setTime(mt_rand(7, 21), mt_rand(0, 59));
            if ($createdAt->isFuture()) {
                $createdAt = $now->subMinutes(mt_rand(10, 300));
            }
            $plans[] = ['at' => $createdAt, 'customer' => $customers[mt_rand(0, count($customers) - 1)]];
        }
        // Customer demo punya pesanan "menunggu bayar" dan "dikirim" untuk dicoba.
        $plans[] = ['at' => $now->subHours(3), 'customer' => $customers[0], 'status' => Order::STATUS_PENDING];
        $plans[] = ['at' => $now->subDays(2)->setTime(10, 15), 'customer' => $customers[0], 'status' => Order::STATUS_SHIPPED];
        // Setiap tab status di dashboard punya isi untuk dicoba admin.
        foreach ([[1, Order::STATUS_PENDING], [5, Order::STATUS_PAID], [8, Order::STATUS_PAID], [20, Order::STATUS_PROCESSING]] as $i => [$hours, $status]) {
            $plans[] = ['at' => $now->subHours($hours), 'customer' => $customers[3 + $i], 'status' => $status];
        }

        usort($plans, fn ($a, $b) => $a['at'] <=> $b['at']);

        $perDay = [];
        foreach ($plans as $plan) {
            $at = $plan['at'];
            $status = $plan['status'] ?? $this->statusFor($at->diffInHours($now));
            $day = $at->format('Ymd');
            $perDay[$day] = ($perDay[$day] ?? 0) + 1;

            $this->createOrder(
                'INV-'.$day.'-'.str_pad((string) $perDay[$day], 4, '0', STR_PAD_LEFT),
                $plan['customer'],
                $variants,
                $status,
                $at,
                $now,
            );
        }
    }

    /** Pesanan lama umumnya selesai; pesanan baru masih di tengah alur. */
    private function statusFor(float $hoursAgo): string
    {
        $r = mt_rand(1, 100);
        if ($hoursAgo > 24 * 7) {
            return $r <= 88 ? Order::STATUS_COMPLETED : Order::STATUS_CANCELLED;
        }
        if ($hoursAgo > 24 * 3) {
            return $r <= 55 ? Order::STATUS_COMPLETED : ($r <= 90 ? Order::STATUS_SHIPPED : Order::STATUS_CANCELLED);
        }

        return match (true) {
            $r <= 25 => Order::STATUS_PENDING,
            $r <= 45 => Order::STATUS_PAID,
            $r <= 65 => Order::STATUS_PROCESSING,
            $r <= 90 => Order::STATUS_SHIPPED,
            default => Order::STATUS_CANCELLED,
        };
    }

    /** @param  list<ProductVariant>  $variants */
    private function createOrder(string $number, User $customer, array $variants, string $status, CarbonImmutable $at, CarbonImmutable $now): void
    {
        $address = $customer->addresses()->first();
        $lines = [];
        foreach ((array) array_rand($variants, mt_rand(1, 3)) as $index) {
            $lines[] = [$variants[$index], mt_rand(1, 100) <= 80 ? 1 : 2];
        }
        if ($lines === []) {
            $lines[] = [$variants[array_rand($variants)], 1];
        }

        $subtotal = array_sum(array_map(fn ($l) => $l[0]->price * $l[1], $lines));
        $shipping = [9000, 10000, 12000, 14000, 18000, 22000][mt_rand(0, 5)];
        [$courier, $service] = self::COURIERS[mt_rand(0, count(self::COURIERS) - 1)];

        $paid = in_array($status, [Order::STATUS_PAID, Order::STATUS_PROCESSING, Order::STATUS_SHIPPED, Order::STATUS_COMPLETED], true);
        $shipped = in_array($status, [Order::STATUS_SHIPPED, Order::STATUS_COMPLETED], true);
        $paidAt = $paid ? $this->notAfter($at->addMinutes(mt_rand(20, 600)), $now) : null;
        $shippedAt = $shipped ? $this->notAfter($paidAt->addHours(mt_rand(6, 30)), $now) : null;
        $deliveredAt = $status === Order::STATUS_COMPLETED ? $this->notAfter($shippedAt->addHours(mt_rand(24, 72)), $now) : null;

        $order = new Order([
            'order_number' => $number,
            'user_id' => $customer->id,
            'address_id' => $address->id,
            'status' => $status,
            'subtotal' => $subtotal,
            'shipping_cost' => $shipping,
            'discount' => 0,
            'total' => $subtotal + $shipping,
            'shipping_address' => $address->toSnapshot(),
            'notes' => mt_rand(1, 100) <= 15 ? 'Mohon dibungkus rapi, untuk hadiah.' : null,
        ]);
        $order->created_at = $at;
        $order->updated_at = $deliveredAt ?? $shippedAt ?? $paidAt ?? $at;
        $order->save();

        foreach ($lines as [$variant, $qty]) {
            $order->items()->create([
                'product_variant_id' => $variant->id,
                'product_name' => $variant->product->name,
                'variant_name' => $variant->name,
                'unit_price' => $variant->price,
                'quantity' => $qty,
                'subtotal' => $variant->price * $qty,
            ]);
        }

        $order->payment()->create([
            'method' => 'manual_transfer',
            'status' => $paid ? 'paid' : ($status === Order::STATUS_CANCELLED ? 'cancelled' : 'pending'),
            'amount' => $order->total,
            'paid_at' => $paidAt,
            'meta' => ['bank' => self::BANKS[mt_rand(0, count(self::BANKS) - 1)]],
        ]);

        $order->shipment()->create([
            'courier' => $courier,
            'service' => $service,
            'status' => $status === Order::STATUS_COMPLETED ? 'delivered' : ($shipped ? 'shipped' : 'preparing'),
            'tracking_number' => $shipped ? strtoupper($courier).mt_rand(100000000, 999999999) : null,
            'shipped_at' => $shippedAt,
            'delivered_at' => $deliveredAt,
        ]);
    }

    private function notAfter(CarbonImmutable $time, CarbonImmutable $now): CarbonImmutable
    {
        return $time->greaterThan($now) ? $now->subMinutes(mt_rand(1, 30)) : $time;
    }
}
