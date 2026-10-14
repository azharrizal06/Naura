<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class AdminOrderTest extends TestCase
{
    use RefreshDatabase;

    private ProductVariant $variant;

    private int $seq = 0;

    protected function setUp(): void
    {
        parent::setUp();

        $product = Product::factory()->create(['name' => 'Gamis Ceruti Alesha']);
        $this->variant = ProductVariant::factory()->create([
            'product_id' => $product->id,
            'name' => 'Mocca / L',
            'price' => 289000,
            'stock' => 8, // 10 awal, 2 sudah dipesan oleh pesanan di bawah
        ]);
    }

    private function admin(): User
    {
        return User::factory()->admin()->create();
    }

    /** Pesanan 2 × varian (stok sudah dikurangi) dengan payment & shipment sesuai [status]. */
    private function order(string $status = 'pending', ?User $customer = null, ?string $number = null): Order
    {
        $customer ??= User::factory()->create(['name' => 'Budi Customer']);
        $order = Order::create([
            // Nomor berurutan: generateNumber() acak dan bisa bentrok di banyak pesanan.
            'order_number' => $number ?? 'INV-TEST-'.str_pad((string) ++$this->seq, 4, '0', STR_PAD_LEFT),
            'user_id' => $customer->id,
            'status' => $status,
            'subtotal' => 578000,
            'shipping_cost' => 15000,
            'discount' => 0,
            'total' => 593000,
            'shipping_address' => ['recipient_name' => $customer->name, 'city' => 'Bandung'],
        ]);
        $order->items()->create([
            'product_variant_id' => $this->variant->id,
            'product_name' => 'Gamis Ceruti Alesha',
            'variant_name' => 'Mocca / L',
            'unit_price' => 289000,
            'quantity' => 2,
            'subtotal' => 578000,
        ]);
        $order->payment()->create([
            'method' => 'manual_transfer',
            'status' => $status === 'pending' || $status === 'cancelled' ? 'pending' : 'paid',
            'amount' => 593000,
            'meta' => ['bank' => ['bank' => 'BCA', 'number' => '1234567890', 'holder' => 'Toko Naura']],
        ]);
        $order->shipment()->create([
            'courier' => 'jne',
            'service' => 'REG',
            'status' => in_array($status, ['shipped', 'completed'], true) ? 'shipped' : 'preparing',
            'tracking_number' => in_array($status, ['shipped', 'completed'], true) ? 'JNE123' : null,
        ]);

        return $order;
    }

    // --- Akses ----------------------------------------------------------

    public function test_customer_cannot_access_dashboard_orders(): void
    {
        $order = $this->order();

        $this->actingAs(User::factory()->create())->getJson('/api/dashboard/orders')->assertForbidden();
        $this->actingAs(User::factory()->create())
            ->postJson("/api/dashboard/orders/{$order->id}/confirm-payment")
            ->assertForbidden();
    }

    public function test_owner_can_access_dashboard_orders(): void
    {
        $this->order();

        $this->actingAs(User::factory()->owner()->create())
            ->getJson('/api/dashboard/orders')
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    // --- Daftar & detail -----------------------------------------------

    public function test_admin_lists_all_orders_newest_first_with_customer(): void
    {
        $old = $this->order(customer: User::factory()->create(['name' => 'Siti Aminah']));
        $old->forceFill(['created_at' => now()->subDay()])->save();
        $new = $this->order();

        $this->actingAs($this->admin())
            ->getJson('/api/dashboard/orders')
            ->assertOk()
            ->assertJsonPath('data.0.id', $new->id)
            ->assertJsonPath('data.0.customer.name', 'Budi Customer')
            ->assertJsonPath('data.1.id', $old->id)
            ->assertJsonPath('data.1.customer.name', 'Siti Aminah')
            ->assertJsonPath('meta.total', 2);
    }

    public function test_admin_filters_orders_by_status(): void
    {
        $this->order('pending');
        $paid = $this->order('paid');

        $this->actingAs($this->admin())
            ->getJson('/api/dashboard/orders?status=paid')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $paid->id);
    }

    public function test_admin_searches_by_order_number_or_customer_name(): void
    {
        $this->order(number: 'INV-20261014-0001');
        $siti = $this->order(customer: User::factory()->create(['name' => 'Siti Aminah']), number: 'INV-20261014-0002');

        $this->actingAs($this->admin())
            ->getJson('/api/dashboard/orders?q=0002')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $siti->id);

        $this->actingAs($this->admin())
            ->getJson('/api/dashboard/orders?q=siti')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $siti->id);
    }

    public function test_admin_sees_order_detail(): void
    {
        $order = $this->order();

        $this->actingAs($this->admin())
            ->getJson("/api/dashboard/orders/{$order->id}")
            ->assertOk()
            ->assertJsonPath('data.id', $order->id)
            ->assertJsonPath('data.customer.name', 'Budi Customer')
            ->assertJsonPath('data.items.0.variant_name', 'Mocca / L')
            ->assertJsonPath('data.payment.bank.bank', 'BCA');
    }

    // --- Alur status ----------------------------------------------------

    public function test_confirm_payment_marks_order_and_payment_paid(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-10-14 10:00:00', 'UTC'));
        $order = $this->order('pending');

        $this->actingAs($this->admin())
            ->postJson("/api/dashboard/orders/{$order->id}/confirm-payment")
            ->assertOk()
            ->assertJsonPath('data.status', 'paid')
            ->assertJsonPath('data.payment.status', 'paid')
            ->assertJsonPath('data.payment.paid_at', '2026-10-14T10:00:00.000000Z');
    }

    public function test_process_moves_paid_order_to_processing(): void
    {
        $order = $this->order('paid');

        $this->actingAs($this->admin())
            ->postJson("/api/dashboard/orders/{$order->id}/process")
            ->assertOk()
            ->assertJsonPath('data.status', 'processing');
    }

    public function test_ship_requires_tracking_number(): void
    {
        $order = $this->order('processing');

        $this->actingAs($this->admin())
            ->postJson("/api/dashboard/orders/{$order->id}/ship", [])
            ->assertStatus(422)
            ->assertJsonValidationErrors('tracking_number');

        $this->assertSame('processing', $order->fresh()->status);
    }

    public function test_ship_stores_tracking_number(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-10-14 13:00:00', 'UTC'));
        $order = $this->order('processing');

        $this->actingAs($this->admin())
            ->postJson("/api/dashboard/orders/{$order->id}/ship", ['tracking_number' => ' JP1234567890 '])
            ->assertOk()
            ->assertJsonPath('data.status', 'shipped')
            ->assertJsonPath('data.shipment.status', 'shipped')
            ->assertJsonPath('data.shipment.tracking_number', 'JP1234567890')
            ->assertJsonPath('data.shipment.courier', 'jne')
            ->assertJsonPath('data.shipment.shipped_at', '2026-10-14T13:00:00.000000Z');
    }

    public function test_ship_can_correct_courier(): void
    {
        $order = $this->order('processing');

        $this->actingAs($this->admin())
            ->postJson("/api/dashboard/orders/{$order->id}/ship", ['tracking_number' => 'JP1', 'courier' => 'jnt'])
            ->assertOk()
            ->assertJsonPath('data.shipment.courier', 'jnt');
    }

    public function test_complete_marks_shipped_order_delivered(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-10-16 09:00:00', 'UTC'));
        $order = $this->order('shipped');

        $this->actingAs($this->admin())
            ->postJson("/api/dashboard/orders/{$order->id}/complete")
            ->assertOk()
            ->assertJsonPath('data.status', 'completed')
            ->assertJsonPath('data.shipment.status', 'delivered')
            ->assertJsonPath('data.shipment.delivered_at', '2026-10-16T09:00:00.000000Z');
    }

    public function test_actions_out_of_order_are_rejected(): void
    {
        $admin = $this->admin();
        $cases = [
            ['pending', 'process'],
            ['pending', 'ship'],
            ['paid', 'confirm-payment'],
            ['paid', 'ship'],
            ['processing', 'complete'],
            ['shipped', 'cancel'],
            ['completed', 'cancel'],
            ['cancelled', 'confirm-payment'],
        ];

        foreach ($cases as [$status, $action]) {
            $order = $this->order($status);
            $this->actingAs($admin)
                ->postJson("/api/dashboard/orders/{$order->id}/{$action}", ['tracking_number' => 'X1'])
                ->assertStatus(422)
                ->assertJsonValidationErrors('order');
            $this->assertSame($status, $order->fresh()->status, "{$action} dari {$status}");
        }
    }

    // --- Batal oleh admin -------------------------------------------------

    public function test_admin_cancels_unpaid_order_and_returns_stock(): void
    {
        $order = $this->order('pending');

        $this->actingAs($this->admin())
            ->postJson("/api/dashboard/orders/{$order->id}/cancel")
            ->assertOk()
            ->assertJsonPath('data.status', 'cancelled')
            ->assertJsonPath('data.payment.status', 'cancelled');

        $this->assertSame(10, $this->variant->fresh()->stock);
    }

    public function test_admin_cancels_paid_order_payment_stays_paid_for_manual_refund(): void
    {
        $order = $this->order('processing');

        $this->actingAs($this->admin())
            ->postJson("/api/dashboard/orders/{$order->id}/cancel")
            ->assertOk()
            ->assertJsonPath('data.status', 'cancelled')
            ->assertJsonPath('data.payment.status', 'paid');

        $this->assertSame(10, $this->variant->fresh()->stock);
    }

    // --- Ringkasan beranda -------------------------------------------------

    public function test_summary_counts_today_and_orders_needing_action(): void
    {
        Carbon::setTestNow('2026-10-14 15:00:00');
        $this->order('pending');
        $this->order('paid');
        $this->order('paid');
        $this->order('processing');
        $this->order('cancelled');
        $this->order('shipped')->forceFill(['created_at' => now()->subDays(3)])->save();

        $this->actingAs($this->admin())
            ->getJson('/api/dashboard/summary')
            ->assertOk()
            ->assertExactJson(['data' => [
                'orders_today' => 4,
                'awaiting_payment' => 1,
                'to_process' => 2,
                'to_ship' => 1,
            ]]);
    }

    public function test_per_page_is_capped(): void
    {
        $this->actingAs($this->admin())
            ->getJson('/api/dashboard/orders?per_page=5000')
            ->assertOk()
            ->assertJsonPath('meta.per_page', 100);
    }
}
