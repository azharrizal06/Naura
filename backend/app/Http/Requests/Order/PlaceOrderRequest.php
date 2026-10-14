<?php

namespace App\Http\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

class PlaceOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'address_id' => ['required', 'integer'],
            // Pilihan dari POST /api/shipping/rates; ongkirnya dihitung ulang di server.
            'courier' => ['required', 'string', 'max:20'],
            'service' => ['required', 'string', 'max:50'],
            'payment_method' => ['required', 'in:manual_transfer'],
            'bank' => ['required', 'string'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ];
    }
}
