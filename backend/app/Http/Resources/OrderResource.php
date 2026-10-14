<?php

namespace App\Http\Resources;

use App\Models\Order;
use App\Models\OrderItem;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Order */
class OrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'order_number' => $this->order_number,
            'status' => $this->status,
            'created_at' => $this->created_at?->toJSON(),
            'subtotal' => $this->subtotal,
            'shipping_cost' => $this->shipping_cost,
            'discount' => $this->discount,
            'total' => $this->total,
            'notes' => $this->notes,
            'shipping_address' => $this->shipping_address,
            'items' => $this->items->map(fn (OrderItem $item) => [
                'id' => $item->id,
                'product_name' => $item->product_name,
                'variant_name' => $item->variant_name,
                'unit_price' => $item->unit_price,
                'quantity' => $item->quantity,
                'subtotal' => $item->subtotal,
                'product' => $item->variant?->product ? [
                    'id' => $item->variant->product->id,
                    'slug' => $item->variant->product->slug,
                    'primary_image' => $item->variant->product->primaryImage?->url,
                ] : null,
            ])->values(),
            'payment' => $this->payment ? [
                'method' => $this->payment->method,
                'status' => $this->payment->status,
                'amount' => $this->payment->amount,
                'bank' => $this->payment->meta['bank'] ?? null,
                'paid_at' => $this->payment->paid_at?->toJSON(),
            ] : null,
            'shipment' => $this->shipment ? [
                'courier' => $this->shipment->courier,
                'service' => $this->shipment->service,
                'tracking_number' => $this->shipment->tracking_number,
                'status' => $this->shipment->status,
                'shipped_at' => $this->shipment->shipped_at?->toJSON(),
                'delivered_at' => $this->shipment->delivered_at?->toJSON(),
            ] : null,
        ];
    }
}
