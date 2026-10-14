<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StoreSetting extends Model
{
    protected $fillable = [
        'store_name',
        'store_email',
        'store_phone',
        'store_address',
        'currency',
        'flat_shipping_cost',
        'shipping_origin_id',
        'shipping_origin_label',
        'bank_accounts',
    ];

    protected function casts(): array
    {
        return [
            'flat_shipping_cost' => 'integer',
            'shipping_origin_id' => 'integer',
            'bank_accounts' => 'array',
        ];
    }

    /** Ambil (atau buat) baris pengaturan tunggal. */
    public static function current(): self
    {
        return static::firstOrCreate([], [
            'store_name' => 'Toko Online Terpadu',
            'currency' => 'IDR',
            'flat_shipping_cost' => 0,
        ]);
    }
}
