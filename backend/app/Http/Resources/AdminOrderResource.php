<?php

namespace App\Http\Resources;

use App\Models\Order;
use Illuminate\Http\Request;

/**
 * Pesanan untuk dashboard: sama dengan versi customer + data pemesan.
 *
 * @mixin Order
 */
class AdminOrderResource extends OrderResource
{
    public function toArray(Request $request): array
    {
        return [
            ...parent::toArray($request),
            'customer' => $this->user ? [
                'id' => $this->user->id,
                'name' => $this->user->name,
                'email' => $this->user->email,
                'phone' => $this->user->phone,
            ] : null,
        ];
    }
}
