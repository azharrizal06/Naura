<?php

namespace Database\Seeders;

use App\Enums\UserRole;
use App\Models\Category;
use App\Models\Product;
use App\Models\ProductImage;
use App\Models\ProductVariant;
use App\Models\StoreSetting;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // --- Pengaturan toko --------------------------------------------
        StoreSetting::firstOrCreate([], [
            'store_name' => 'Toko Online Terpadu',
            'store_email' => 'cs@naura.test',
            'store_phone' => '0800-1234-5678',
            'currency' => 'IDR',
            'flat_shipping_cost' => 15000,
            'bank_accounts' => [
                ['bank' => 'BCA', 'number' => '1234567890', 'holder' => 'Toko Naura'],
                ['bank' => 'Mandiri', 'number' => '0987654321', 'holder' => 'Toko Naura'],
            ],
        ]);

        // --- Akun default ------------------------------------------------
        User::updateOrCreate(
            ['email' => 'owner@naura.test'],
            [
                'name' => 'Pemilik Toko',
                'password' => 'password',
                'role' => UserRole::Owner->value,
                'phone' => '081200000001',
                'is_active' => true,
            ]
        );

        User::updateOrCreate(
            ['email' => 'admin@naura.test'],
            [
                'name' => 'Admin Toko',
                'password' => 'password',
                'role' => UserRole::Admin->value,
                'phone' => '081200000002',
                'is_active' => true,
            ]
        );

        User::updateOrCreate(
            ['email' => 'customer@naura.test'],
            [
                'name' => 'Budi Customer',
                'password' => 'password',
                'role' => UserRole::Customer->value,
                'phone' => '081200000003',
                'is_active' => true,
            ]
        );

        // --- Contoh katalog ---------------------------------------------
        $this->seedCatalog();
    }

    private function seedCatalog(): void
    {
        // kategori => [nama produk => [harga dasar, [warna], [ukuran]]]
        $catalog = [
            'Gamis' => [
                'Gamis Ceruti Alesha' => [289000, ['Mocca', 'Dusty Pink', 'Hitam'], ['M', 'L', 'XL']],
                'Gamis Linen Raya' => [325000, ['Sage', 'Milo', 'Navy'], ['M', 'L', 'XL']],
            ],
            'Hijab' => [
                'Pashmina Voal Nadia' => [69000, ['Taro', 'Army', 'Broken White', 'Maroon'], []],
                'Bergo Jersey Instan' => [55000, ['Hitam', 'Coksu', 'Abu'], []],
            ],
            'Atasan' => [
                'Tunik Katun Salma' => [175000, ['Olive', 'Mustard', 'Putih'], ['M', 'L']],
            ],
            'Mukena' => [
                'Mukena Rayon Bali Kirana' => [235000, ['Lilac', 'Putih', 'Sage'], []],
            ],
        ];

        foreach ($catalog as $categoryName => $products) {
            $category = Category::updateOrCreate(
                ['slug' => Str::slug($categoryName)],
                ['name' => $categoryName, 'is_active' => true]
            );

            foreach ($products as $productName => [$basePrice, $colors, $sizes]) {
                $product = Product::updateOrCreate(
                    ['slug' => Str::slug($productName)],
                    [
                        'category_id' => $category->id,
                        'name' => $productName,
                        'description' => 'Jatuh lembut, tidak menerawang, dan nyaman dipakai seharian.',
                        'base_price' => $basePrice,
                        'weight_grams' => $sizes ? 450 : 150,
                        'is_active' => true,
                    ]
                );

                if ($product->images()->count() === 0) {
                    ProductImage::create([
                        'product_id' => $product->id,
                        'path' => 'products/placeholder.png',
                        'is_primary' => true,
                        'sort_order' => 0,
                    ]);
                }

                if ($product->variants()->count() > 0) {
                    continue;
                }

                $i = 0;
                foreach ($colors as $color) {
                    foreach ($sizes ?: [null] as $size) {
                        $i++;
                        ProductVariant::create([
                            'product_id' => $product->id,
                            'sku' => Str::upper(Str::slug($productName)).'-'.$i,
                            'name' => $size ? "{$color} / {$size}" : $color,
                            'price' => $basePrice + ($size === 'XL' ? 15000 : 0),
                            'stock' => fake()->randomElement([0, 4, 12, 25, 40]),
                            'attributes' => array_filter(['warna' => $color, 'ukuran' => $size]),
                            'is_active' => true,
                        ]);
                    }
                }
            }
        }
    }
}
