<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Product;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CatalogTest extends TestCase
{
    use RefreshDatabase;

    public function test_public_can_list_active_products(): void
    {
        Product::factory()->count(3)->create();
        Product::factory()->inactive()->create();

        $response = $this->getJson('/api/catalog/products');

        $response->assertOk()
            ->assertJsonStructure(['data', 'links', 'meta'])
            ->assertJsonCount(3, 'data');
    }

    public function test_public_can_view_product_detail_by_slug(): void
    {
        $product = Product::factory()->create(['slug' => 'kaos-keren']);

        $this->getJson('/api/catalog/products/kaos-keren')
            ->assertOk()
            ->assertJsonPath('data.slug', 'kaos-keren');
    }

    public function test_inactive_product_detail_returns_404(): void
    {
        Product::factory()->inactive()->create(['slug' => 'produk-nonaktif']);

        $this->getJson('/api/catalog/products/produk-nonaktif')->assertStatus(404);
    }

    public function test_products_can_be_searched_by_name(): void
    {
        Product::factory()->create(['name' => 'Sepatu Lari', 'slug' => 'sepatu-lari']);
        Product::factory()->create(['name' => 'Topi Pantai', 'slug' => 'topi-pantai']);

        $this->getJson('/api/catalog/products?q=sepatu')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.slug', 'sepatu-lari');
    }

    public function test_products_can_be_filtered_by_category_slug(): void
    {
        $catA = Category::factory()->create(['slug' => 'pakaian']);
        $catB = Category::factory()->create(['slug' => 'elektronik']);
        Product::factory()->count(2)->create(['category_id' => $catA->id]);
        Product::factory()->create(['category_id' => $catB->id]);

        $this->getJson('/api/catalog/products?category=pakaian')
            ->assertOk()
            ->assertJsonCount(2, 'data');
    }

    public function test_public_can_list_active_categories(): void
    {
        Category::factory()->count(2)->create();
        Category::factory()->inactive()->create();

        $this->getJson('/api/catalog/categories')
            ->assertOk()
            ->assertJsonCount(2, 'data');
    }

    public function test_per_page_is_capped(): void
    {
        $this->getJson('/api/catalog/products?per_page=1000000')
            ->assertOk()
            ->assertJsonPath('meta.per_page', 100);

        $this->getJson('/api/catalog/products?per_page=0')
            ->assertOk()
            ->assertJsonPath('meta.per_page', 1);
    }
}
