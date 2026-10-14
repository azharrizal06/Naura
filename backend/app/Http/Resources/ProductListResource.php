<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Representasi ringkas produk untuk daftar/katalog.
 */
class ProductListResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'slug' => $this->slug,
            'base_price' => $this->base_price,
            'is_active' => $this->is_active,
            'category' => $this->whenLoaded('category', fn () => [
                'id' => $this->category->id,
                'name' => $this->category->name,
                'slug' => $this->category->slug,
            ]),
            'primary_image' => $this->whenLoaded('primaryImage', fn () => $this->primaryImage?->url),
            'total_stock' => $this->when(
                $this->relationLoaded('variants'),
                fn () => $this->variants->sum('stock'),
            ),
        ];
    }
}
