<?php

namespace App\Services\Reports;

use App\Models\Order;
use App\Models\OrderItem;
use Carbon\CarbonImmutable;
use Carbon\CarbonPeriod;
use Illuminate\Database\Eloquent\Builder;

/**
 * Omzet = total pesanan yang sudah dibayar (paid → completed), dikelompokkan
 * menurut tanggal pembayaran dikonfirmasi (zona waktu aplikasi). Pesanan batal tidak dihitung.
 */
class SalesReport
{
    public const PAID_STATUSES = [
        Order::STATUS_PAID,
        Order::STATUS_PROCESSING,
        Order::STATUS_SHIPPED,
        Order::STATUS_COMPLETED,
    ];

    /** @return array<string, mixed> */
    public function build(CarbonImmutable $from, CarbonImmutable $to): array
    {
        $start = $from->startOfDay();
        $end = $to->endOfDay();

        $orders = $this->paidOrders($start, $end)
            ->join('payments', 'payments.order_id', '=', 'orders.id')
            ->get(['orders.id', 'orders.total', 'orders.shipping_cost', 'payments.paid_at']);

        $revenue = (int) $orders->sum('total');
        $shipping = (int) $orders->sum('shipping_cost');
        $count = $orders->count();

        $byDay = $orders->groupBy(fn ($o) => CarbonImmutable::parse($o->paid_at)->toDateString());
        $daily = collect(CarbonPeriod::create($start, $end->startOfDay()))
            ->map(fn ($day) => [
                'date' => $day->toDateString(),
                'revenue' => (int) ($byDay[$day->toDateString()] ?? collect())->sum('total'),
                'orders' => ($byDay[$day->toDateString()] ?? collect())->count(),
            ])
            ->values();

        $topProducts = OrderItem::query()
            ->whereIn('order_id', $orders->pluck('id'))
            ->selectRaw('product_name, sum(quantity) as quantity, sum(subtotal) as revenue')
            ->groupBy('product_name')
            ->orderByDesc('quantity')
            ->orderByDesc('revenue')
            ->limit(5)
            ->get()
            ->map(fn ($row) => [
                'product_name' => $row->product_name,
                'quantity' => (int) $row->quantity,
                'revenue' => (int) $row->revenue,
            ]);

        return [
            'from' => $start->toDateString(),
            'to' => $end->toDateString(),
            'revenue' => $revenue,
            'goods' => $revenue - $shipping,
            'shipping' => $shipping,
            'orders' => $count,
            'average_order' => $count > 0 ? intdiv($revenue, $count) : 0,
            // Batal dihitung menurut tanggal pesanan dibuat (pesanan batal umumnya belum dibayar).
            'cancelled' => Order::where('status', Order::STATUS_CANCELLED)
                ->whereBetween('created_at', [$start, $end])
                ->count(),
            'daily' => $daily,
            'top_products' => $topProducts,
        ];
    }

    /** Omzet satu periode saja (kartu beranda). */
    public function revenue(CarbonImmutable $from, CarbonImmutable $to): int
    {
        return (int) $this->paidOrders($from->startOfDay(), $to->endOfDay())->sum('orders.total');
    }

    private function paidOrders(CarbonImmutable $start, CarbonImmutable $end): Builder
    {
        return Order::query()
            ->whereIn('orders.status', self::PAID_STATUSES)
            ->whereHas('payment', fn (Builder $q) => $q->whereBetween('paid_at', [$start, $end]));
    }
}
