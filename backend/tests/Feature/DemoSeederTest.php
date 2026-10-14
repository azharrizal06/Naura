<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Database\Seeders\DemoSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DemoSeederTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DemoSeeder::class);
    }

    public function test_seeds_a_busy_store(): void
    {
        $this->assertGreaterThanOrEqual(25, Product::where('is_active', true)->count());
        $this->assertGreaterThanOrEqual(15, User::where('role', 'customer')->count());
        $this->assertGreaterThanOrEqual(100, Order::count());

        foreach (['pending', 'paid', 'processing', 'shipped', 'completed', 'cancelled'] as $status) {
            $this->assertTrue(Order::where('status', $status)->exists(), "tidak ada pesanan {$status}");
        }
    }

    public function test_orders_are_consistent(): void
    {
        $this->assertSame(Order::count(), Order::distinct('order_number')->count('order_number'));
        $this->assertSame(0, Order::where('created_at', '>', now())->count());

        $orders = Order::with(['items', 'payment', 'shipment'])->get();
        foreach ($orders as $order) {
            $this->assertSame($order->items->sum('subtotal'), $order->subtotal, $order->order_number);
            $this->assertSame($order->subtotal + $order->shipping_cost - $order->discount, $order->total);
            $paid = in_array($order->status, ['paid', 'processing', 'shipped', 'completed'], true);
            $this->assertSame($paid, $order->payment->paid_at !== null, "{$order->order_number} paid_at");
            $shipped = in_array($order->status, ['shipped', 'completed'], true);
            $this->assertSame($shipped, $order->shipment->tracking_number !== null, "{$order->order_number} resi");
        }
    }

    public function test_demo_accounts_can_log_in_and_report_has_data(): void
    {
        foreach (['owner@naura.test', 'admin@naura.test', 'customer@naura.test'] as $email) {
            $this->postJson('/api/auth/login', ['email' => $email, 'password' => 'password'])->assertOk();
        }

        $this->assertTrue(User::where('email', 'customer@naura.test')->first()->orders()->where('status', 'shipped')->exists());

        $this->actingAs(User::where('email', 'owner@naura.test')->first())
            ->getJson('/api/owner/reports/sales')
            ->assertOk()
            ->assertJsonPath('data.revenue', fn (int $v) => $v > 0)
            ->assertJsonCount(5, 'data.top_products');
    }

    public function test_is_deterministic(): void
    {
        $first = Order::orderBy('order_number')->pluck('total')->all();

        \DB::statement('TRUNCATE order_items, payments, shipments, orders, cart_items, carts, addresses,
            product_variants, product_images, products, categories, personal_access_tokens, users, store_settings
            RESTART IDENTITY CASCADE');
        $this->seed(DemoSeeder::class);

        $this->assertSame($first, Order::orderBy('order_number')->pluck('total')->all());
    }
}
