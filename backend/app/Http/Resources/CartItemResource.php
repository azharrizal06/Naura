<?php

namespace App\Http\Resources;

use App\Models\CartItem;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin CartItem */
class CartItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $product = $this->variant->product;

        return [
            'id' => $this->id,
            'variant_id' => $this->product_variant_id,
            'variant_name' => $this->variant->name,
            'product' => [
                'id' => $product->id,
                'name' => $product->name,
                'slug' => $product->slug,
                'primary_image' => $product->primaryImage?->url,
            ],
            'unit_price' => $this->unit_price,
            'quantity' => $this->quantity,
            'stock' => $this->variant->stock,
            'line_total' => $this->subtotal(),
        ];
    }
}
