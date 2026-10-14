<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\StoreSetting;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class OrderTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        StoreSetting::current()->update([
            'flat_shipping_cost' => 15000,
            'bank_accounts' => [
                ['bank' => 'BCA', 'number' => '1234567890', 'holder' => 'Toko Naura'],
                ['bank' => 'Mandiri', 'number' => '0987654321', 'holder' => 'Toko Naura'],
            ],
        ]);
    }

    private function variant(int $stock = 10): ProductVariant
    {
        $product = Product::factory()->create(['name' => 'Gamis Ceruti Alesha', 'is_active' => true]);

        return ProductVariant::factory()->create([
            'product_id' => $product->id,
            'name' => 'Mocca / L',
            'price' => 289000,
            'stock' => $stock,
            'is_active' => true,
        ]);
    }

    /** @var array<int, int> alamat milik tiap customer test */
    private array $addressOf = [];

    /** Customer dengan [quantity] varian di keranjang dan satu alamat tersimpan. */
    private function customerWithCart(ProductVariant $variant, int $quantity = 2): User
    {
        $customer = User::factory()->create();
        $this->actingAs($customer)
            ->postJson('/api/cart/items', ['variant_id' => $variant->id, 'quantity' => $quantity])
            ->assertCreated();
        $this->addressOf[$customer->id] = $this->actingAs($customer)->postJson('/api/addresses', [
            'label' => 'Rumah',
            'recipient_name' => 'Budi Customer',
            'phone' => '081200000003',
            'address_line' => 'Jl. Merdeka 1',
            'subdistrict' => 'Braga',
            'district' => 'Sumur Bandung',
            'city' => 'Bandung',
            'province' => 'Jawa Barat',
            'postal_code' => '40111',
            'destination_id' => 4949,
        ])->json('data.id');

        return $customer;
    }

    /** Isi checkout; tanpa RajaOngkir, satu-satunya pilihan adalah kurir toko (ongkir flat). */
    private function checkout(User $customer, array $overrides = []): array
    {
        return array_merge([
            'address_id' => $this->addressOf[$customer->id],
            'courier' => 'toko',
            'service' => 'REG',
            'payment_method' => 'manual_transfer',
            'bank' => 'BCA',
            'notes' => 'Bungkus rapi',
        ], $overrides);
    }

    public function test_customer_places_order_from_cart(): void
    {
        $customer = $this->customerWithCart($this->variant());

        $this->actingAs($customer)
            ->postJson('/api/orders', $this->checkout($customer))
            ->assertCreated()
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.subtotal', 578000)
            ->assertJsonPath('data.shipping_cost', 15000)
            ->assertJsonPath('data.total', 593000)
            ->assertJsonPath('data.notes', 'Bungkus rapi')
            ->assertJsonPath('data.shipping_address.city', 'Bandung')
            ->assertJsonPath('data.items.0.product_name', 'Gamis Ceruti Alesha')
            ->assertJsonPath('data.items.0.variant_name', 'Mocca / L')
            ->assertJsonPath('data.items.0.unit_price', 289000)
            ->assertJsonPath('data.items.0.quantity', 2)
            ->assertJsonPath('data.items.0.subtotal', 578000)
            ->assertJsonPath('data.payment.method', 'manual_transfer')
            ->assertJsonPath('data.payment.status', 'pending')
            ->assertJsonPath('data.payment.amount', 593000)
            ->assertJsonPath('data.payment.bank.number', '1234567890')
            ->assertJsonPath('data.shipping_address.subdistrict', 'Braga')
            ->assertJsonPath('data.shipment.courier', 'toko')
            ->assertJsonPath('data.shipment.service', 'REG')
            ->assertJsonPath('data.shipment.status', 'preparing')
            ->assertJsonPath('data.shipment.tracking_number', null);

        $this->assertDatabaseHas('orders', ['user_id' => $customer->id, 'total' => 593000]);
    }

    public function test_placing_order_empties_cart(): void
    {
        $customer = $this->customerWithCart($this->variant());

        $this->actingAs($customer)->postJson('/api/orders', $this->checkout($customer))->assertCreated();

        $this->actingAs($customer)->getJson('/api/cart')->assertJsonPath('data.count', 0);
    }

    public function test_placing_order_reserves_stock(): void
    {
        $variant = $this->variant(stock: 10);
        $customer = $this->customerWithCart($variant, quantity: 3);

        $this->actingAs($customer)->postJson('/api/orders', $this->checkout($customer))->assertCreated();

        $this->assertSame(7, $variant->fresh()->stock);
    }

    public function test_cannot_order_with_empty_cart(): void
    {
        $customer = $this->customerWithCart($this->variant());
        $itemId = $this->actingAs($customer)->getJson('/api/cart')->json('data.items.0.id');
        $this->actingAs($customer)->deleteJson("/api/cart/items/{$itemId}")->assertOk();

        $this->actingAs($customer)
            ->postJson('/api/orders', $this->checkout($customer))
            ->assertStatus(422)
            ->assertJsonValidationErrors('cart');

        $this->assertDatabaseCount('orders', 0);
    }

    public function test_stock_shortage_rejects_whole_order_and_keeps_cart(): void
    {
        $variant = $this->variant(stock: 10);
        $customer = $this->customerWithCart($variant, quantity: 3);
        $variant->update(['stock' => 2]); // terjual ke pembeli lain

        $this->actingAs($customer)
            ->postJson('/api/orders', $this->checkout($customer))
            ->assertStatus(422)
            ->assertJsonValidationErrors('cart');

        $this->assertDatabaseCount('orders', 0);
        $this->assertSame(2, $variant->fresh()->stock);
        $this->actingAs($customer)->getJson('/api/cart')->assertJsonPath('data.count', 3);
    }

    public function test_unknown_bank_is_rejected(): void
    {
        $customer = $this->customerWithCart($this->variant());

        $this->actingAs($customer)
            ->postJson('/api/orders', $this->checkout($customer, ['bank' => 'Bank Antah']))
            ->assertStatus(422)
            ->assertJsonValidationErrors('bank');
    }

    private function placeOrder(User $customer): int
    {
        return $this->actingAs($customer)
            ->postJson('/api/orders', $this->checkout($customer))
            ->assertCreated()
            ->json('data.id');
    }

    public function test_customer_lists_own_orders_newest_first(): void
    {
        $variant = $this->variant(stock: 20);
        $customer = $this->customerWithCart($variant);
        $first = $this->placeOrder($customer);
        $this->travel(1)->minutes();
        $this->actingAs($customer)->postJson('/api/cart/items', ['variant_id' => $variant->id]);
        $second = $this->placeOrder($customer);

        $other = $this->customerWithCart($variant);
        $this->placeOrder($other);

        $this->actingAs($customer)
            ->getJson('/api/orders')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.id', $second)
            ->assertJsonPath('data.1.id', $first)
            ->assertJsonPath('data.0.items.0.variant_name', 'Mocca / L');
    }

    public function test_customer_sees_own_order_detail(): void
    {
        $customer = $this->customerWithCart($this->variant());
        $id = $this->placeOrder($customer);

        $this->actingAs($customer)
            ->getJson("/api/orders/{$id}")
            ->assertOk()
            ->assertJsonPath('data.id', $id)
            ->assertJsonPath('data.payment.bank.bank', 'BCA');
    }

    public function test_customer_cannot_see_another_customers_order(): void
    {
        $id = $this->placeOrder($this->customerWithCart($this->variant()));

        $this->actingAs(User::factory()->create())
            ->getJson("/api/orders/{$id}")
            ->assertNotFound();
    }

    public function test_admin_cannot_use_customer_orders(): void
    {
        $this->actingAs(User::factory()->admin()->create())
            ->getJson('/api/orders')
            ->assertForbidden();
    }

    public function test_unavailable_shipping_service_is_rejected(): void
    {
        $customer = $this->customerWithCart($this->variant());

        $this->actingAs($customer)
            ->postJson('/api/orders', $this->checkout($customer, ['courier' => 'jne', 'service' => 'YES']))
            ->assertStatus(422)
            ->assertJsonValidationErrors('service');

        $this->assertDatabaseCount('orders', 0);
    }

    public function test_another_customers_address_cannot_be_used(): void
    {
        $owner = $this->customerWithCart($this->variant());
        $customer = $this->customerWithCart($this->variant());

        $this->actingAs($customer)
            ->postJson('/api/orders', $this->checkout($customer, ['address_id' => $this->addressOf[$owner->id]]))
            ->assertNotFound();
    }

    public function test_courier_rate_is_recalculated_by_server(): void
    {
        config([
            'services.rajaongkir.key' => 'test-key',
            'services.rajaongkir.couriers' => 'jne:jnt',
        ]);
        StoreSetting::current()->update(['shipping_origin_id' => 501]);
        Http::fake(['*/calculate/domestic-cost' => Http::response(['data' => [
            ['name' => 'JNE', 'code' => 'jne', 'service' => 'REG', 'description' => 'Reguler', 'cost' => 18000, 'etd' => '2-3 day'],
        ]])]);
        $customer = $this->customerWithCart($this->variant());

        $this->actingAs($customer)
            ->postJson('/api/orders', $this->checkout($customer, ['courier' => 'jne', 'service' => 'REG', 'shipping_cost' => 1]))
            ->assertCreated()
            ->assertJsonPath('data.shipping_cost', 18000)
            ->assertJsonPath('data.total', 578000 + 18000)
            ->assertJsonPath('data.shipment.courier', 'jne')
            ->assertJsonPath('data.shipment.service', 'REG');
    }

    public function test_customer_cancels_pending_order(): void
    {
        $customer = $this->customerWithCart($this->variant());
        $id = $this->placeOrder($customer);

        $this->actingAs($customer)
            ->postJson("/api/orders/{$id}/cancel")
            ->assertOk()
            ->assertJsonPath('data.id', $id)
            ->assertJsonPath('data.status', 'cancelled')
            ->assertJsonPath('data.payment.status', 'cancelled');
    }

    public function test_cancelling_order_returns_stock(): void
    {
        $variant = $this->variant(stock: 10);
        $customer = $this->customerWithCart($variant, quantity: 3);
        $id = $this->placeOrder($customer);
        $this->assertSame(7, $variant->fresh()->stock);

        $this->actingAs($customer)->postJson("/api/orders/{$id}/cancel")->assertOk();

        $this->assertSame(10, $variant->fresh()->stock);
    }

    public function test_cancelled_order_cannot_be_cancelled_again(): void
    {
        $variant = $this->variant(stock: 10);
        $customer = $this->customerWithCart($variant, quantity: 3);
        $id = $this->placeOrder($customer);
        $this->actingAs($customer)->postJson("/api/orders/{$id}/cancel")->assertOk();

        $this->actingAs($customer)
            ->postJson("/api/orders/{$id}/cancel")
            ->assertStatus(422)
            ->assertJsonValidationErrors('order');

        // Stok tidak dikembalikan dua kali.
        $this->assertSame(10, $variant->fresh()->stock);
    }

    public function test_paid_order_cannot_be_cancelled_by_customer(): void
    {
        $variant = $this->variant(stock: 10);
        $customer = $this->customerWithCart($variant, quantity: 3);
        $id = $this->placeOrder($customer);
        Order::find($id)->update(['status' => 'paid']);

        $this->actingAs($customer)
            ->postJson("/api/orders/{$id}/cancel")
            ->assertStatus(422)
            ->assertJsonValidationErrors('order');

        $this->assertSame(7, $variant->fresh()->stock);
        $this->assertDatabaseHas('orders', ['id' => $id, 'status' => 'paid']);
    }

    public function test_customer_cannot_cancel_another_customers_order(): void
    {
        $id = $this->placeOrder($this->customerWithCart($this->variant()));

        $this->actingAs(User::factory()->create())
            ->postJson("/api/orders/{$id}/cancel")
            ->assertNotFound();

        $this->assertDatabaseHas('orders', ['id' => $id, 'status' => 'pending']);
    }

    public function test_cancel_skips_items_whose_variant_was_deleted(): void
    {
        $variant = $this->variant(stock: 10);
        $customer = $this->customerWithCart($variant, quantity: 3);
        $id = $this->placeOrder($customer);
        $variant->delete();

        $this->actingAs($customer)
            ->postJson("/api/orders/{$id}/cancel")
            ->assertOk()
            ->assertJsonPath('data.status', 'cancelled');
    }

    public function test_customer_confirms_shipped_order_received(): void
    {
        $customer = $this->customerWithCart($this->variant());
        $id = $this->placeOrder($customer);
        Order::find($id)->update(['status' => 'shipped']);

        $this->actingAs($customer)
            ->postJson("/api/orders/{$id}/complete")
            ->assertOk()
            ->assertJsonPath('data.status', 'completed')
            ->assertJsonPath('data.shipment.status', 'delivered');
    }

    public function test_customer_cannot_complete_order_that_is_not_shipped(): void
    {
        $customer = $this->customerWithCart($this->variant());
        $id = $this->placeOrder($customer);

        $this->actingAs($customer)
            ->postJson("/api/orders/{$id}/complete")
            ->assertStatus(422)
            ->assertJsonValidationErrors('order');
    }

    public function test_customer_cannot_complete_another_customers_order(): void
    {
        $id = $this->placeOrder($this->customerWithCart($this->variant()));
        Order::find($id)->update(['status' => 'shipped']);

        $this->actingAs(User::factory()->create())
            ->postJson("/api/orders/{$id}/complete")
            ->assertNotFound();
    }

    public function test_price_change_since_added_to_cart_is_rejected_and_cart_repriced(): void
    {
        $variant = $this->variant(stock: 10); // 289.000
        $customer = $this->customerWithCart($variant, quantity: 2);
        $variant->update(['price' => 310000]);

        $this->actingAs($customer)
            ->postJson('/api/orders', $this->checkout($customer))
            ->assertStatus(422)
            ->assertJsonValidationErrors('cart')
            ->assertJsonPath('errors.cart.0', 'Harga Mocca / L berubah menjadi Rp310.000. Periksa keranjang lalu pesan lagi.');

        $this->assertDatabaseCount('orders', 0);
        $this->assertSame(10, $variant->fresh()->stock);
        $this->actingAs($customer)->getJson('/api/cart')->assertJsonPath('data.items.0.unit_price', 310000);

        // Setelah melihat harga baru, pesanan kedua memakai harga sekarang.
        $this->actingAs($customer)
            ->postJson('/api/orders', $this->checkout($customer))
            ->assertCreated()
            ->assertJsonPath('data.items.0.unit_price', 310000)
            ->assertJsonPath('data.subtotal', 620000);
    }

    public function test_inactive_product_in_cart_cannot_be_ordered(): void
    {
        $variant = $this->variant(stock: 10);
        $customer = $this->customerWithCart($variant);
        $variant->product->update(['is_active' => false]);

        $this->actingAs($customer)
            ->postJson('/api/orders', $this->checkout($customer))
            ->assertStatus(422)
            ->assertJsonPath('errors.cart.0', 'Gamis Ceruti Alesha (Mocca / L) sudah tidak dijual. Hapus dari keranjang lalu pesan lagi.');

        $this->assertDatabaseCount('orders', 0);
        $this->assertSame(10, $variant->fresh()->stock);
    }

    public function test_inactive_variant_in_cart_cannot_be_ordered(): void
    {
        $variant = $this->variant(stock: 10);
        $customer = $this->customerWithCart($variant);
        $variant->update(['is_active' => false]);

        $this->actingAs($customer)
            ->postJson('/api/orders', $this->checkout($customer))
            ->assertStatus(422)
            ->assertJsonValidationErrors('cart');

        $this->assertDatabaseCount('orders', 0);
    }

    public function test_order_numbers_are_sequential_per_day(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-10-14 09:00:00'));
        $variant = $this->variant(stock: 20);

        $numbers = [];
        foreach (range(1, 3) as $_) {
            $customer = $this->customerWithCart($variant, quantity: 1);
            $numbers[] = $this->actingAs($customer)->postJson('/api/orders', $this->checkout($customer))
                ->assertCreated()
                ->json('data.order_number');
        }
        $this->assertSame(['INV-20261014-0001', 'INV-20261014-0002', 'INV-20261014-0003'], $numbers);

        // Hari berikutnya mulai dari 0001 lagi.
        Carbon::setTestNow(Carbon::parse('2026-10-15 08:00:00'));
        $customer = $this->customerWithCart($variant, quantity: 1);
        $this->actingAs($customer)->postJson('/api/orders', $this->checkout($customer))
            ->assertCreated()
            ->assertJsonPath('data.order_number', 'INV-20261015-0001');
    }
}
