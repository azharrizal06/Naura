<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Order\ShipOrderRequest;
use App\Http\Resources\AdminOrderResource;
use App\Models\Order;
use App\Services\Orders\OrderWorkflow;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/**
 * Pesanan semua customer (Admin & Owner): daftar, detail, dan aksi status (Fase 5).
 */
class OrderController extends Controller
{
    private const RELATIONS = ['user', 'items.variant.product.primaryImage', 'payment', 'shipment'];

    public function __construct(private readonly OrderWorkflow $workflow) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $orders = Order::query()
            ->with(self::RELATIONS)
            ->search($request->query('q'))
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->query('status')))
            ->latest()
            ->latest('id')
            ->paginate($this->perPage($request, 15))
            ->withQueryString();

        return AdminOrderResource::collection($orders);
    }

    public function show(Order $order): JsonResponse
    {
        return $this->respond($order);
    }

    public function confirmPayment(Order $order): JsonResponse
    {
        return $this->respond($this->workflow->confirmPayment($order));
    }

    public function process(Order $order): JsonResponse
    {
        return $this->respond($this->workflow->process($order));
    }

    public function ship(ShipOrderRequest $request, Order $order): JsonResponse
    {
        return $this->respond($this->workflow->ship(
            $order,
            trim($request->string('tracking_number')->value()),
            $request->filled('courier') ? $request->string('courier')->value() : null,
        ));
    }

    public function complete(Order $order): JsonResponse
    {
        return $this->respond($this->workflow->complete($order));
    }

    public function cancel(Order $order): JsonResponse
    {
        return $this->respond($this->workflow->cancel($order, byAdmin: true));
    }

    private function respond(Order $order): JsonResponse
    {
        return (new AdminOrderResource($order->load(self::RELATIONS)))->response();
    }
}
