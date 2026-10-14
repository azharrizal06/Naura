<?php

namespace App\Http\Requests\Catalog;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ProductVariantRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $variantId = $this->route('variant')?->id;
        $required = $this->isMethod('post') ? 'required' : 'sometimes';

        return [
            'sku' => [
                $required, 'string', 'max:255',
                Rule::unique('product_variants', 'sku')->ignore($variantId),
            ],
            'name' => [$required, 'string', 'max:255'],
            'price' => [$required, 'integer', 'min:0'],
            'stock' => ['sometimes', 'integer', 'min:0'],
            'attributes' => ['nullable', 'array'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
