<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Product;
use App\Models\ProductImage;
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

    public function test_image_urls_follow_the_host_the_app_used(): void
    {
        // APP_URL di .env = 127.0.0.1, tetapi HP di jaringan lokal memanggil lewat IP komputer.
        config(['app.url' => 'http://127.0.0.1:8000']);
        $product = Product::factory()->create(['is_active' => true, 'slug' => 'gamis-x']);
        ProductImage::create(['product_id' => $product->id, 'path' => 'demo/gamis-x-1.jpg', 'is_primary' => true]);

        $this->getJson('http://192.168.1.5:8000/api/catalog/products')
            ->assertJsonPath('data.0.primary_image', 'http://192.168.1.5:8000/demo/gamis-x-1.jpg');

        $this->getJson('http://10.0.2.2:8000/api/catalog/products/gamis-x')
            ->assertJsonPath('data.images.0.url', 'http://10.0.2.2:8000/demo/gamis-x-1.jpg');
    }
}
