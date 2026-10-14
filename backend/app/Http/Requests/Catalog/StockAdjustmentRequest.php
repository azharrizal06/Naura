<?php

namespace App\Http\Requests\Catalog;

use Illuminate\Foundation\Http\FormRequest;

class StockAdjustmentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            // 'set' = tetapkan nilai absolut; 'adjust' = tambah/kurangi (boleh negatif)
            'mode' => ['required', 'in:set,adjust'],
            'value' => ['required', 'integer'],
        ];
    }
}
