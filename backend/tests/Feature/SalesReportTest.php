<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class SalesReportTest extends TestCase
{
    use RefreshDatabase;

    private int $seq = 0;

    private User $customer;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow(Carbon::parse('2026-10-14 12:00:00'));
        $this->customer = User::factory()->create();
    }

    private function owner(): User
    {
        return User::factory()->owner()->create();
    }

    /**
     * Pesanan dengan satu baris barang. [paidAt] null = belum dibayar.
     *
     * @param  array{0: string, 1: int, 2: int}  $item  [nama produk, jumlah, harga satuan]
     */
    private function order(string $status, ?string $paidAt, array $item = ['Gamis Alesha', 1, 100000], int $shipping = 10000, ?string $createdAt = null): Order
    {
        [$name, $qty, $price] = $item;
        $subtotal = $qty * $price;
        $order = Order::create([
            'order_number' => 'INV-TEST-'.++$this->seq,
            'user_id' => $this->customer->id,
            'status' => $status,
            'subtotal' => $subtotal,
            'shipping_cost' => $shipping,
            'discount' => 0,
            'total' => $subtotal + $shipping,
            'shipping_address' => ['city' => 'Bandung'],
        ]);
        if ($createdAt) {
            $order->forceFill(['created_at' => Carbon::parse($createdAt)])->save();
        }
        $order->items()->create([
            'product_name' => $name,
            'variant_name' => 'Mocca / L',
            'unit_price' => $price,
            'quantity' => $qty,
            'subtotal' => $subtotal,
        ]);
        $order->payment()->create([
            'method' => 'manual_transfer',
            'status' => $paidAt ? 'paid' : 'pending',
            'amount' => $subtotal + $shipping,
            'paid_at' => $paidAt ? Carbon::parse($paidAt) : null,
        ]);

        return $order;
    }

    public function test_admin_and_customer_cannot_see_reports(): void
    {
        $this->actingAs(User::factory()->admin()->create())->getJson('/api/owner/reports/sales')->assertForbidden();
        $this->actingAs($this->customer)->getJson('/api/owner/reports/sales')->assertForbidden();
    }

    public function test_revenue_counts_paid_orders_by_payment_date(): void
    {
        $this->order('paid', '2026-10-10 09:00', ['Gamis Alesha', 2, 100000]);       // 210.000
        $this->order('processing', '2026-10-11 09:00', ['Hijab Voal', 1, 50000]);   // 60.000
        $this->order('shipped', '2026-10-11 20:00', ['Hijab Voal', 3, 50000]);      // 160.000
        $this->order('completed', '2026-10-12 10:00', ['Mukena Bali', 1, 200000]);  // 210.000
        $this->order('pending', null);                                               // belum dibayar
        $this->order('cancelled', '2026-10-11 09:00');                               // dibayar lalu batal

        $this->actingAs($this->owner())
            ->getJson('/api/owner/reports/sales?from=2026-10-10&to=2026-10-12')
            ->assertOk()
            ->assertJsonPath('data.from', '2026-10-10')
            ->assertJsonPath('data.to', '2026-10-12')
            ->assertJsonPath('data.revenue', 640000)
            ->assertJsonPath('data.shipping', 40000)
            ->assertJsonPath('data.goods', 600000)
            ->assertJsonPath('data.orders', 4)
            ->assertJsonPath('data.average_order', 160000);
    }

    public function test_period_bounds_include_whole_days(): void
    {
        $this->order('paid', '2026-10-09 23:59');   // sebelum periode
        $this->order('paid', '2026-10-10 00:00');   // awal hari pertama
        $this->order('paid', '2026-10-12 23:59');   // akhir hari terakhir
        $this->order('paid', '2026-10-13 00:00');   // sesudah periode

        $this->actingAs($this->owner())
            ->getJson('/api/owner/reports/sales?from=2026-10-10&to=2026-10-12')
            ->assertJsonPath('data.orders', 2);
    }

    public function test_daily_series_fills_days_without_sales(): void
    {
        $this->order('paid', '2026-10-10 09:00');
        $this->order('paid', '2026-10-12 09:00');
        $this->order('paid', '2026-10-12 15:00');

        $this->actingAs($this->owner())
            ->getJson('/api/owner/reports/sales?from=2026-10-10&to=2026-10-12')
            ->assertJsonPath('data.daily', [
                ['date' => '2026-10-10', 'revenue' => 110000, 'orders' => 1],
                ['date' => '2026-10-11', 'revenue' => 0, 'orders' => 0],
                ['date' => '2026-10-12', 'revenue' => 220000, 'orders' => 2],
            ]);
    }

    public function test_top_products_by_quantity_sold(): void
    {
        $this->order('paid', '2026-10-10 09:00', ['Hijab Voal', 3, 50000]);
        $this->order('completed', '2026-10-11 09:00', ['Hijab Voal', 2, 50000]);
        $this->order('paid', '2026-10-11 09:00', ['Gamis Alesha', 1, 300000]);
        $this->order('cancelled', '2026-10-11 09:00', ['Mukena Bali', 9, 200000]);

        $this->actingAs($this->owner())
            ->getJson('/api/owner/reports/sales?from=2026-10-10&to=2026-10-12')
            ->assertJsonPath('data.top_products', [
                ['product_name' => 'Hijab Voal', 'quantity' => 5, 'revenue' => 250000],
                ['product_name' => 'Gamis Alesha', 'quantity' => 1, 'revenue' => 300000],
            ]);
    }

    public function test_counts_orders_cancelled_in_period(): void
    {
        $this->order('cancelled', null, createdAt: '2026-10-11 09:00');
        $this->order('cancelled', null, createdAt: '2026-10-01 09:00');

        $this->actingAs($this->owner())
            ->getJson('/api/owner/reports/sales?from=2026-10-10&to=2026-10-12')
            ->assertJsonPath('data.cancelled', 1);
    }

    public function test_default_period_is_last_30_days(): void
    {
        $this->actingAs($this->owner())
            ->getJson('/api/owner/reports/sales')
            ->assertOk()
            ->assertJsonPath('data.from', '2026-09-15')
            ->assertJsonPath('data.to', '2026-10-14')
            ->assertJsonCount(30, 'data.daily')
            ->assertJsonPath('data.revenue', 0)
            ->assertJsonPath('data.average_order', 0);
    }

    public function test_rejects_invalid_period(): void
    {
        $owner = $this->owner();

        $this->actingAs($owner)
            ->getJson('/api/owner/reports/sales?from=2026-10-12&to=2026-10-10')
            ->assertStatus(422)
            ->assertJsonValidationErrors('to');

        $this->actingAs($owner)
            ->getJson('/api/owner/reports/sales?from=2025-01-01&to=2026-10-10')
            ->assertStatus(422)
            ->assertJsonValidationErrors('to');
    }

    public function test_owner_summary_includes_revenue_this_month(): void
    {
        $this->order('paid', '2026-10-01 08:00');      // 110.000
        $this->order('completed', '2026-10-14 08:00'); // 110.000
        $this->order('paid', '2026-09-30 22:00');      // bulan lalu
        $this->order('cancelled', '2026-10-05 08:00'); // batal

        $this->actingAs($this->owner())
            ->getJson('/api/dashboard/summary')
            ->assertOk()
            ->assertJsonPath('data.revenue_this_month', 220000);
    }

    public function test_admin_summary_has_no_revenue(): void
    {
        $this->actingAs(User::factory()->admin()->create())
            ->getJson('/api/dashboard/summary')
            ->assertOk()
            ->assertJsonMissingPath('data.revenue_this_month');
    }
}
