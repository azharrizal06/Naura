<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Address extends Model
{
    /** @use HasFactory<\Database\Factories\AddressFactory> */
    use HasFactory;

    protected $fillable = [
        'user_id',
        'label',
        'recipient_name',
        'phone',
        'province',
        'city',
        'district',
        'subdistrict',
        'postal_code',
        'destination_id',
        'address_line',
        'is_default',
    ];

    protected function casts(): array
    {
        return [
            'is_default' => 'boolean',
            'destination_id' => 'integer',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /** Snapshot alamat untuk disimpan ke order (shipping_address jsonb). */
    public function toSnapshot(): array
    {
        return $this->only([
            'label', 'recipient_name', 'phone', 'province',
            'city', 'district', 'subdistrict', 'postal_code', 'address_line',
        ]);
    }
}
