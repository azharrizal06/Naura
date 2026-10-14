<?php

namespace App\Http\Controllers\Api\Admin;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\Reports\SalesReport;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Angka di beranda dashboard: pesanan hari ini dan pesanan yang menunggu tindakan.
 * Owner juga mendapat omzet bulan ini.
 */
class SummaryController extends Controller
{
    public function __invoke(Request $request, SalesReport $report): JsonResponse
    {
        $byStatus = Order::query()
            ->selectRaw('status, count(*) as total')
            ->groupBy('status')
            ->pluck('total', 'status');

        $data = [
            // Pesanan batal tidak dihitung sebagai pesanan masuk.
            'orders_today' => Order::whereDate('created_at', today())
                ->where('status', '!=', Order::STATUS_CANCELLED)
                ->count(),
            'awaiting_payment' => (int) ($byStatus[Order::STATUS_PENDING] ?? 0),
            'to_process' => (int) ($byStatus[Order::STATUS_PAID] ?? 0),
            'to_ship' => (int) ($byStatus[Order::STATUS_PROCESSING] ?? 0),
        ];

        if ($request->user()->role === UserRole::Owner) {
            $today = CarbonImmutable::today();
            $data['revenue_this_month'] = $report->revenue($today->startOfMonth(), $today);
        }

        return response()->json(['data' => $data]);
    }
}
