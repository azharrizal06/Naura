<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Order\PlaceOrderRequest;
use App\Http\Resources\OrderResource;
use App\Models\Cart;
use App\Models\Order;
use App\Models\ProductVariant;
use App\Models\StoreSetting;
use App\Services\Shipping\ShippingRateService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Pesanan milik customer yang sedang login (Fase 4).
 */
class OrderController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $orders = $request->user()->orders()
            ->with(['items.variant.product.primaryImage', 'payment', 'shipment'])
            ->latest()
            ->latest('id')
            ->get();

        return OrderResource::collection($orders);
    }

    public function show(Request $request, int $order): JsonResponse
    {
        return $this->orderResponse($request->user()->orders()->findOrFail($order));
    }

    public function store(PlaceOrderRequest $request, ShippingRateService $shippingRates): JsonResponse
    {
        $address = $request->user()->addresses()->findOrFail($request->integer('address_id'));
        $cart = Cart::firstOrCreate(['user_id' => $request->user()->id])
            ->load('items.variant.product');
        $settings = StoreSetting::current();
        $bank = collect($settings->bank_accounts ?? [])->firstWhere('bank', $request->string('bank')->value());

        if ($bank === null) {
            throw ValidationException::withMessages(['bank' => 'Pilih rekening tujuan transfer yang tersedia.']);
        }
        if ($cart->items->isEmpty()) {
            throw ValidationException::withMessages(['cart' => 'Keranjang kosong. Tambahkan barang sebelum membuat pesanan.']);
        }

        // Ongkir dihitung ulang di server — nilai dari aplikasi tidak dipercaya.
        $rate = $shippingRates->find($cart, $address, $request->string('courier')->value(), $request->string('service')->value());
        if ($rate === null) {
            throw ValidationException::withMessages(['service' => 'Layanan kurir ini tidak tersedia untuk alamat tersebut. Pilih kurir lain.']);
        }

        $order = DB::transaction(function () use ($request, $cart, $bank, $address, $rate) {
            // Kunci baris varian agar dua pesanan tidak mengambil stok yang sama.
            $variants = ProductVariant::whereIn('id', $cart->items->pluck('product_variant_id'))
                ->lockForUpdate()
                ->get()
                ->keyBy('id');
            foreach ($cart->items as $item) {
                $variant = $variants[$item->product_variant_id];
                if ($variant->stock < $item->quantity) {
                    throw ValidationException::withMessages([
                        'cart' => "Stok {$variant->name} tinggal {$variant->stock}. Ubah jumlahnya di keranjang.",
                    ]);
                }
            }

            $subtotal = $cart->subtotal();
            $shipping = $rate['cost'];

            $order = Order::create([
                'order_number' => Order::generateNumber(),
                'user_id' => $request->user()->id,
                'status' => 'pending',
                'subtotal' => $subtotal,
                'shipping_cost' => $shipping,
                'discount' => 0,
                'total' => $subtotal + $shipping,
                'address_id' => $address->id,
                'shipping_address' => $address->toSnapshot(),
                'notes' => $request->validated('notes'),
            ]);

            foreach ($cart->items as $item) {
                $order->items()->create([
                    'product_variant_id' => $item->product_variant_id,
                    'product_name' => $item->variant->product->name,
                    'variant_name' => $item->variant->name,
                    'unit_price' => $item->unit_price,
                    'quantity' => $item->quantity,
                    'subtotal' => $item->subtotal(),
                ]);
                // Stok dipesan sejak pesanan dibuat (dikembalikan bila batal — Fase 5).
                $variants[$item->product_variant_id]->decrement('stock', $item->quantity);
            }

            $cart->items()->delete();

            $order->shipment()->create([
                'courier' => $rate['courier'],
                'service' => $rate['service'],
                'status' => 'preparing',
            ]);

            $order->payment()->create([
                'method' => 'manual_transfer',
                'status' => 'pending',
                'amount' => $order->total,
                'meta' => ['bank' => $bank],
            ]);

            return $order;
        });

        return $this->orderResponse($order, 201);
    }

    private function orderResponse(Order $order, int $status = 200): JsonResponse
    {
        $order->load(['items.variant.product.primaryImage', 'payment', 'shipment']);

        return (new OrderResource($order))->response()->setStatusCode($status);
    }
}
