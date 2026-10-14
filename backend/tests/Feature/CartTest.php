<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\StoreSetting;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CartTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_sees_empty_cart_without_shipping_cost(): void
    {
        $this->actingAs(User::factory()->create())
            ->getJson('/api/cart')
            ->assertOk()
            ->assertExactJson(['data' => [
                'items' => [],
                'count' => 0,
                'subtotal' => 0,
                'shipping_cost' => 0,
                'total' => 0,
            ]]);
    }

    private function variant(array $attrs = []): ProductVariant
    {
        $product = Product::factory()->create(['name' => 'Gamis Ceruti Alesha', 'is_active' => true]);

        return ProductVariant::factory()->create(array_merge([
            'product_id' => $product->id,
            'name' => 'Mocca / L',
            'price' => 289000,
            'stock' => 10,
            'is_active' => true,
        ], $attrs));
    }

    public function test_customer_adds_variant_with_price_snapshot_and_flat_shipping(): void
    {
        StoreSetting::current()->update(['flat_shipping_cost' => 15000]);
        $variant = $this->variant();

        $this->actingAs(User::factory()->create())
            ->postJson('/api/cart/items', ['variant_id' => $variant->id, 'quantity' => 2])
            ->assertCreated()
            ->assertJsonPath('data.items.0.variant_id', $variant->id)
            ->assertJsonPath('data.items.0.variant_name', 'Mocca / L')
            ->assertJsonPath('data.items.0.product.name', 'Gamis Ceruti Alesha')
            ->assertJsonPath('data.items.0.unit_price', 289000)
            ->assertJsonPath('data.items.0.quantity', 2)
            ->assertJsonPath('data.items.0.stock', 10)
            ->assertJsonPath('data.items.0.line_total', 578000)
            ->assertJsonPath('data.count', 2)
            ->assertJsonPath('data.subtotal', 578000)
            ->assertJsonPath('data.shipping_cost', 15000)
            ->assertJsonPath('data.total', 593000);
    }

    public function test_adding_same_variant_merges_quantity(): void
    {
        $variant = $this->variant();
        $customer = User::factory()->create();

        $this->actingAs($customer)->postJson('/api/cart/items', ['variant_id' => $variant->id]);
        $this->actingAs($customer)
            ->postJson('/api/cart/items', ['variant_id' => $variant->id, 'quantity' => 3])
            ->assertCreated()
            ->assertJsonCount(1, 'data.items')
            ->assertJsonPath('data.items.0.quantity', 4);
    }

    public function test_cannot_add_more_than_stock_including_cart_quantity(): void
    {
        $variant = $this->variant(['stock' => 3]);
        $customer = User::factory()->create();

        $this->actingAs($customer)
            ->postJson('/api/cart/items', ['variant_id' => $variant->id, 'quantity' => 2])
            ->assertCreated();
        $this->actingAs($customer)
            ->postJson('/api/cart/items', ['variant_id' => $variant->id, 'quantity' => 2])
            ->assertStatus(422)
            ->assertJsonValidationErrors('quantity');

        $this->actingAs($customer)->getJson('/api/cart')->assertJsonPath('data.items.0.quantity', 2);
    }

    private function cartItemId(User $customer, ProductVariant $variant): int
    {
        return $this->actingAs($customer)
            ->postJson('/api/cart/items', ['variant_id' => $variant->id])
            ->json('data.items.0.id');
    }

    public function test_customer_sets_item_quantity(): void
    {
        $customer = User::factory()->create();
        $id = $this->cartItemId($customer, $this->variant(['stock' => 10]));

        $this->actingAs($customer)
            ->patchJson("/api/cart/items/{$id}", ['quantity' => 5])
            ->assertOk()
            ->assertJsonPath('data.items.0.quantity', 5)
            ->assertJsonPath('data.subtotal', 289000 * 5);
    }

    public function test_cannot_set_quantity_above_stock(): void
    {
        $customer = User::factory()->create();
        $id = $this->cartItemId($customer, $this->variant(['stock' => 3]));

        $this->actingAs($customer)
            ->patchJson("/api/cart/items/{$id}", ['quantity' => 4])
            ->assertStatus(422)
            ->assertJsonValidationErrors('quantity');
    }

    public function test_customer_removes_item(): void
    {
        $customer = User::factory()->create();
        $id = $this->cartItemId($customer, $this->variant());

        $this->actingAs($customer)
            ->deleteJson("/api/cart/items/{$id}")
            ->assertOk()
            ->assertJsonCount(0, 'data.items')
            ->assertJsonPath('data.total', 0);
    }

    public function test_customer_cannot_touch_another_customers_item(): void
    {
        $owner = User::factory()->create();
        $id = $this->cartItemId($owner, $this->variant());
        $other = User::factory()->create();

        $this->actingAs($other)->patchJson("/api/cart/items/{$id}", ['quantity' => 2])->assertNotFound();
        $this->actingAs($other)->deleteJson("/api/cart/items/{$id}")->assertNotFound();
        $this->actingAs($owner)->getJson('/api/cart')->assertJsonPath('data.items.0.quantity', 1);
    }

    public function test_admin_has_no_cart(): void
    {
        $this->actingAs(User::factory()->admin()->create())
            ->getJson('/api/cart')
            ->assertForbidden();
    }

    public function test_guest_must_log_in_to_use_cart(): void
    {
        $this->getJson('/api/cart')->assertUnauthorized();
    }

    public function test_cannot_add_inactive_variant(): void
    {
        $variant = $this->variant(['is_active' => false]);

        $this->actingAs(User::factory()->create())
            ->postJson('/api/cart/items', ['variant_id' => $variant->id])
            ->assertStatus(422)
            ->assertJsonValidationErrors('variant_id');
    }

    public function test_cannot_add_variant_of_inactive_product(): void
    {
        $variant = $this->variant();
        $variant->product->update(['is_active' => false]);

        $this->actingAs(User::factory()->create())
            ->postJson('/api/cart/items', ['variant_id' => $variant->id])
            ->assertStatus(422)
            ->assertJsonValidationErrors('variant_id');
    }
}
