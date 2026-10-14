<?php

namespace App\Http\Requests\Owner;

use Closure;
use Illuminate\Foundation\Http\FormRequest;

class UpdateStoreSettingsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'store_name' => ['required', 'string', 'max:100'],
            'store_email' => ['nullable', 'email', 'max:255'],
            'store_phone' => ['nullable', 'string', 'max:30'],
            'store_address' => ['nullable', 'string', 'max:500'],
            'flat_shipping_cost' => ['required', 'integer', 'min:0'],
            'bank_accounts' => ['present', 'array', 'max:10'],
            'bank_accounts.*.bank' => [
                'required',
                'string',
                'max:50',
                // Pesanan memilih rekening menurut nama bank, jadi nama harus unik.
                function (string $attribute, mixed $value, Closure $fail) {
                    $index = (int) explode('.', $attribute)[1];
                    $before = collect($this->input('bank_accounts'))->take($index)->pluck('bank');
                    if ($before->contains(fn ($b) => is_string($b) && strcasecmp(trim($b), trim($value)) === 0)) {
                        $fail('Nama bank sudah ada di daftar. Satu bank hanya boleh satu rekening.');
                    }
                },
            ],
            'bank_accounts.*.number' => ['required', 'regex:/^\d{4,30}$/'],
            'bank_accounts.*.holder' => ['required', 'string', 'max:100'],
        ];
    }

    public function messages(): array
    {
        return [
            'bank_accounts.*.bank.required' => 'Isi nama bank.',
            'bank_accounts.*.number.required' => 'Isi nomor rekening.',
            'bank_accounts.*.number.regex' => 'Nomor rekening hanya angka (4–30 digit), tanpa spasi atau tanda hubung.',
            'bank_accounts.*.holder.required' => 'Isi nama pemilik rekening.',
            'flat_shipping_cost.min' => 'Ongkir flat tidak boleh negatif.',
        ];
    }

    /** Rekening dirapikan: spasi di tepi dibuang, hanya kolom yang dikenal. */
    public function bankAccounts(): array
    {
        return collect($this->validated('bank_accounts'))
            ->map(fn (array $a) => [
                'bank' => trim($a['bank']),
                'number' => $a['number'],
                'holder' => trim($a['holder']),
            ])
            ->values()
            ->all();
    }
}
