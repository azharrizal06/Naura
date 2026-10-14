<?php

namespace Database\Factories;

use App\Models\Product;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\ProductVariant>
 */
class ProductVariantFactory extends Factory
{
    public function definition(): array
    {
        return [
            'product_id' => Product::factory(),
            'sku' => strtoupper(Str::random(8)),
            'name' => fake()->randomElement(['Standar', 'Besar', 'Kecil', 'Merah', 'Biru']),
            'price' => fake()->numberBetween(1, 100) * 10000,
            'stock' => fake()->numberBetween(0, 100),
            'attributes' => ['ukuran' => fake()->randomElement(['S', 'M', 'L', 'XL'])],
            'is_active' => true,
        ];
    }

    public function outOfStock(): static
    {
        return $this->state(fn () => ['stock' => 0]);
    }
}
