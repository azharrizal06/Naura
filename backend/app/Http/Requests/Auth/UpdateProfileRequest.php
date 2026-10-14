<?php

namespace App\Http\Requests\Auth;

use Closure;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

/** Profil sendiri: nama, HP, email. Role & status tidak bisa diubah di sini. */
class UpdateProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function emailChanged(): bool
    {
        return $this->filled('email')
            && strcasecmp(trim($this->input('email')), $this->user()->email) !== 0;
    }

    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:30'],
            'email' => [
                'sometimes', 'required', 'string', 'email', 'max:255',
                Rule::unique('users', 'email')->ignore($this->user()->id),
            ],
            // Ganti email = ganti alamat login dan tujuan reset password → wajib password.
            'current_password' => [
                Rule::requiredIf(fn () => $this->emailChanged()),
                'nullable',
                'string',
                function (string $attribute, mixed $value, Closure $fail) {
                    if ($value !== null && ! Hash::check($value, $this->user()->password)) {
                        $fail('Password saat ini salah.');
                    }
                },
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'email.unique' => 'Email ini sudah dipakai akun lain.',
            'current_password.required' => 'Masukkan password saat ini untuk mengganti email.',
        ];
    }
}
