<?php

namespace App\Http\Resources;

use App\Models\Cart;
use App\Models\StoreSetting;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Cart */
class CartResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $subtotal = $this->subtotal();
        $shipping = $this->items->isEmpty() ? 0 : StoreSetting::current()->flat_shipping_cost;

        return [
            'items' => CartItemResource::collection($this->items),
            'count' => (int) $this->items->sum('quantity'),
            'subtotal' => $subtotal,
            'shipping_cost' => $shipping,
            'total' => $subtotal + $shipping,
        ];
    }
}
