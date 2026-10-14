<?php

namespace App\Http\Requests\Address;

use Illuminate\Foundation\Http\FormRequest;

class AddressRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'label' => ['required', 'string', 'max:50'],
            'recipient_name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'min:9', 'max:30'],
            'address_line' => ['required', 'string', 'max:1000'],
            'subdistrict' => ['nullable', 'string', 'max:255'],
            'district' => ['nullable', 'string', 'max:255'],
            'city' => ['required', 'string', 'max:255'],
            'province' => ['required', 'string', 'max:255'],
            'postal_code' => ['required', 'digits:5'],
            // ID tujuan RajaOngkir dari pencarian kecamatan; wajib untuk hitung ongkir kurir.
            'destination_id' => ['nullable', 'integer', 'min:1'],
            'is_default' => ['sometimes', 'boolean'],
        ];
    }
}
