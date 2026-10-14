<?php

namespace App\Services\Orders;

use App\Models\Order;
use App\Models\ProductVariant;
use Closure;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Perpindahan status pesanan (customer & admin). Setiap aksi mengunci baris
 * pesanan dan memeriksa status asal, jadi permintaan ganda tidak diproses dua kali.
 *
 * pending → paid → processing → shipped → completed; pending/paid/processing → cancelled.
 */
class OrderWorkflow
{
    /** Admin: transfer sudah dicek masuk. */
    public function confirmPayment(Order $order): Order
    {
        return $this->transition($order, [Order::STATUS_PENDING], 'Hanya pesanan yang menunggu pembayaran yang bisa dikonfirmasi.',
            function (Order $order) {
                $order->update(['status' => Order::STATUS_PAID]);
                $order->payment()->update(['status' => 'paid', 'paid_at' => now()]);
            });
    }

    /** Admin: mulai menyiapkan barang. */
    public function process(Order $order): Order
    {
        return $this->transition($order, [Order::STATUS_PAID], 'Hanya pesanan yang sudah dibayar yang bisa diproses.',
            fn (Order $order) => $order->update(['status' => Order::STATUS_PROCESSING]));
    }

    /** Admin: paket diserahkan ke kurir. [courier] null = tetap kurir pilihan customer. */
    public function ship(Order $order, string $trackingNumber, ?string $courier = null): Order
    {
        return $this->transition($order, [Order::STATUS_PROCESSING], 'Hanya pesanan yang sedang diproses yang bisa dikirim.',
            function (Order $order) use ($trackingNumber, $courier) {
                $order->update(['status' => Order::STATUS_SHIPPED]);
                $order->shipment()->update(array_filter([
                    'status' => 'shipped',
                    'tracking_number' => $trackingNumber,
                    'courier' => $courier,
                    'shipped_at' => now(),
                ], fn ($v) => $v !== null));
            });
    }

    /** Customer atau admin: paket sudah diterima. */
    public function complete(Order $order): Order
    {
        return $this->transition($order, [Order::STATUS_SHIPPED], 'Hanya pesanan yang sedang dikirim yang bisa diselesaikan.',
            function (Order $order) {
                $order->update(['status' => Order::STATUS_COMPLETED]);
                $order->shipment()->update(['status' => 'delivered', 'delivered_at' => now()]);
            });
    }

    /**
     * Batalkan pesanan dan kembalikan stok. Customer hanya dari `pending`;
     * admin juga dari `paid`/`processing` (dana dikembalikan manual, payment tetap `paid`).
     */
    public function cancel(Order $order, bool $byAdmin = false): Order
    {
        $from = $byAdmin
            ? [Order::STATUS_PENDING, Order::STATUS_PAID, Order::STATUS_PROCESSING]
            : [Order::STATUS_PENDING];
        $message = $byAdmin
            ? 'Pesanan yang sudah dikirim tidak bisa dibatalkan.'
            : 'Pesanan ini tidak bisa dibatalkan karena sudah diproses.';

        return $this->transition($order, $from, $message, function (Order $order) {
            foreach ($order->items as $item) {
                // Varian yang sudah dihapus (product_variant_id null) dilewati.
                if ($item->product_variant_id !== null) {
                    ProductVariant::whereKey($item->product_variant_id)->increment('stock', $item->quantity);
                }
            }

            $wasUnpaid = $order->status === Order::STATUS_PENDING;
            $order->update(['status' => Order::STATUS_CANCELLED]);
            if ($wasUnpaid) {
                $order->payment()->update(['status' => 'cancelled']);
            }
        });
    }

    /**
     * @param  list<string>  $from  status asal yang diizinkan
     * @param  Closure(Order): void  $apply
     */
    private function transition(Order $order, array $from, string $message, Closure $apply): Order
    {
        return DB::transaction(function () use ($order, $from, $message, $apply) {
            $locked = Order::with('items')->lockForUpdate()->findOrFail($order->id);
            if (! in_array($locked->status, $from, true)) {
                throw ValidationException::withMessages(['order' => $message]);
            }
            $apply($locked);

            return $locked;
        });
    }
}
