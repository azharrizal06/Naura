<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * PostgreSQL tidak membuat indeks untuk foreign key secara otomatis.
 * Kolom yang dipakai join/eager-load/laporan harus berindeks.
 */
class DatabaseIndexTest extends TestCase
{
    use RefreshDatabase;

    /** @return list<string> definisi kolom indeks pada [table], mis. "(order_id)" */
    private function indexedColumns(string $table): array
    {
        return collect(DB::select('select indexdef from pg_indexes where schemaname = current_schema() and tablename = ?', [$table]))
            ->map(fn ($r) => preg_replace('/.*USING btree /', '', $r->indexdef))
            ->all();
    }

    public function test_foreign_keys_and_report_columns_are_indexed(): void
    {
        $expected = [
            'order_items' => ['(order_id)'],
            'payments' => ['(order_id)', '(paid_at)'],
            'shipments' => ['(order_id)'],
            'product_variants' => ['(product_id)'],
            'product_images' => ['(product_id)'],
            'addresses' => ['(user_id)'],
            'products' => ['(category_id)'],
            'orders' => ['(created_at)'],
        ];

        foreach ($expected as $table => $columns) {
            foreach ($columns as $column) {
                $this->assertContains($column, $this->indexedColumns($table), "{$table} {$column} belum berindeks");
            }
        }
    }

    public function test_an_order_has_at_most_one_payment(): void
    {
        $order = Order::create([
            'order_number' => 'INV-X-1',
            'user_id' => User::factory()->create()->id,
            'status' => 'pending',
            'subtotal' => 1, 'shipping_cost' => 0, 'discount' => 0, 'total' => 1,
            'shipping_address' => [],
        ]);
        $order->payment()->create(['method' => 'manual_transfer', 'status' => 'pending', 'amount' => 1]);

        $this->expectException(QueryException::class);
        $order->payment()->create(['method' => 'manual_transfer', 'status' => 'pending', 'amount' => 1]);
    }
}
