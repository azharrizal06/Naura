<?php

namespace App\Http\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

class ShipOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'tracking_number' => ['required', 'string', 'max:100'],
            // Opsional: koreksi kurir bila paket diserahkan ke kurir lain.
            'courier' => ['nullable', 'string', 'max:20'],
        ];
    }

    public function messages(): array
    {
        return ['tracking_number.required' => 'Isi nomor resi dari kurir.'];
    }
}
