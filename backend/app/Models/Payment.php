<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class Payment extends Model
{
    public const STATUS_PENDING = 'pending';
    public const STATUS_PAID = 'paid';
    public const STATUS_FAILED = 'failed';
    public const STATUS_EXPIRED = 'expired';
    public const STATUS_REFUNDED = 'refunded';

    protected $fillable = [
        'order_id',
        'method',
        'status',
        'amount',
        'reference',
        'proof_path',
        'paid_at',
        'meta',
    ];

    protected $appends = ['proof_url'];

    protected function casts(): array
    {
        return [
            'amount' => 'integer',
            'paid_at' => 'datetime',
            'meta' => 'array',
        ];
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function getProofUrlAttribute(): ?string
    {
        return $this->proof_path ? Storage::disk('public')->url($this->proof_path) : null;
    }
}
