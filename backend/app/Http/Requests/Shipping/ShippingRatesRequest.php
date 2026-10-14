<?php

namespace App\Http\Requests\Shipping;

use App\Services\Shipping\RajaOngkir;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ShippingRatesRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'address_id' => ['required', 'integer'],
            // Opsional: batasi ke satu kurir yang ditawarkan toko.
            'courier' => ['nullable', 'string', Rule::in(app(RajaOngkir::class)->couriers())],
        ];
    }
}
