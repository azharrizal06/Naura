<?php

namespace App\Http\Requests\Owner;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/** Tambah (POST) atau ubah (PATCH) akun admin. */
class AdminRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $creating = $this->isMethod('post');
        $adminId = $this->route('admin');

        return [
            'name' => [$creating ? 'required' : 'sometimes', 'string', 'max:100'],
            'email' => [
                $creating ? 'required' : 'sometimes',
                'email',
                'max:255',
                Rule::unique('users', 'email')->ignore($adminId),
            ],
            'phone' => ['nullable', 'string', 'max:30'],
            // Saat ubah: kosong/tidak dikirim = password lama tetap.
            'password' => [$creating ? 'required' : 'nullable', 'string', 'min:8', 'max:100'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'email.unique' => 'Email ini sudah dipakai akun lain.',
            'password.min' => 'Password minimal 8 karakter.',
        ];
    }
}
