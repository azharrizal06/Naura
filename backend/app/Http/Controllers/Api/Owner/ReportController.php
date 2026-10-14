<?php

namespace App\Http\Controllers\Api\Owner;

use App\Http\Controllers\Controller;
use App\Http\Requests\Owner\SalesReportRequest;
use App\Services\Reports\SalesReport;
use Illuminate\Http\JsonResponse;

/**
 * Laporan penjualan untuk Owner (Fase 6).
 */
class ReportController extends Controller
{
    public function sales(SalesReportRequest $request, SalesReport $report): JsonResponse
    {
        [$from, $to] = $request->period();

        return response()->json(['data' => $report->build($from, $to)]);
    }
}
