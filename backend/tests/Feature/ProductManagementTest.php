<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProductManagementTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        return User::factory()->admin()->create();
    }

    public function test_customer_cannot_manage_products(): void
    {
        $customer = User::factory()->create();
        $category = Category::factory()->create();

        $this->actingAs($customer)
            ->postJson('/api/dashboard/products', [
                'category_id' => $category->id,
                'name' => 'Produk Baru',
                'base_price' => 50000,
            ])
            ->assertStatus(403);
    }

    public function test_admin_can_create_product_with_auto_slug(): void
    {
        $category = Category::factory()->create();

        $response = $this->actingAs($this->admin())
            ->postJson('/api/dashboard/products', [
                'category_id' => $category->id,
                'name' => 'Kaos Polos Katun',
                'base_price' => 75000,
                'weight_grams' => 200,
            ]);

        $response->assertCreated()
            ->assertJsonPath('data.slug', 'kaos-polos-katun')
            ->assertJsonPath('data.base_price', 75000);

        $this->assertDatabaseHas('products', ['name' => 'Kaos Polos Katun']);
    }

    public function test_admin_can_update_product(): void
    {
        $product = Product::factory()->create();

        $this->actingAs($this->admin())
            ->patchJson("/api/dashboard/products/{$product->id}", ['base_price' => 99000])
            ->assertOk()
            ->assertJsonPath('data.base_price', 99000);
    }

    public function test_admin_can_delete_product(): void
    {
        $product = Product::factory()->create();

        $this->actingAs($this->admin())
            ->deleteJson("/api/dashboard/products/{$product->id}")
            ->assertOk();

        $this->assertDatabaseMissing('products', ['id' => $product->id]);
    }

    public function test_admin_can_add_variant_and_adjust_stock(): void
    {
        $product = Product::factory()->create();
        $admin = $this->admin();

        $variantResponse = $this->actingAs($admin)
            ->postJson("/api/dashboard/products/{$product->id}/variants", [
                'sku' => 'SKU-001',
                'name' => 'Merah / XL',
                'price' => 80000,
                'stock' => 10,
            ])
            ->assertCreated()
            ->assertJsonPath('data.stock', 10);

        $variantId = $variantResponse->json('data.id');

        // set absolut
        $this->actingAs($admin)
            ->patchJson("/api/dashboard/products/{$product->id}/variants/{$variantId}/stock", [
                'mode' => 'set', 'value' => 25,
            ])
            ->assertOk()
            ->assertJsonPath('data.stock', 25);

        // adjust (kurangi 5)
        $this->actingAs($admin)
            ->patchJson("/api/dashboard/products/{$product->id}/variants/{$variantId}/stock", [
                'mode' => 'adjust', 'value' => -5,
            ])
            ->assertOk()
            ->assertJsonPath('data.stock', 20);
    }

    public function test_stock_cannot_go_negative(): void
    {
        $product = Product::factory()->create();
        $variant = ProductVariant::factory()->create([
            'product_id' => $product->id,
            'stock' => 3,
        ]);

        $this->actingAs($this->admin())
            ->patchJson("/api/dashboard/products/{$product->id}/variants/{$variant->id}/stock", [
                'mode' => 'adjust', 'value' => -10,
            ])
            ->assertOk()
            ->assertJsonPath('data.stock', 0);
    }

    public function test_category_with_products_cannot_be_deleted(): void
    {
        $category = Category::factory()->create();
        Product::factory()->create(['category_id' => $category->id]);

        $this->actingAs($this->admin())
            ->deleteJson("/api/dashboard/categories/{$category->id}")
            ->assertStatus(422);
    }
}
