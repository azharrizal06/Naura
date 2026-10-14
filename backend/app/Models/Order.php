<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Facades\DB;

class Order extends Model
{
    /** @use HasFactory<\Database\Factories\OrderFactory> */
    use HasFactory;

    public const STATUS_PENDING = 'pending';
    public const STATUS_PAID = 'paid';
    public const STATUS_PROCESSING = 'processing';
    public const STATUS_SHIPPED = 'shipped';
    public const STATUS_COMPLETED = 'completed';
    public const STATUS_CANCELLED = 'cancelled';

    protected $fillable = [
        'order_number',
        'user_id',
        'address_id',
        'status',
        'subtotal',
        'shipping_cost',
        'discount',
        'total',
        'shipping_address',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'subtotal' => 'integer',
            'shipping_cost' => 'integer',
            'discount' => 'integer',
            'total' => 'integer',
            'shipping_address' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function address(): BelongsTo
    {
        return $this->belongsTo(Address::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function payment(): HasOne
    {
        return $this->hasOne(Payment::class)->latestOfMany();
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    public function shipment(): HasOne
    {
        return $this->hasOne(Shipment::class);
    }

    /** Cari nomor pesanan atau nama customer. */
    public function scopeSearch(Builder $query, ?string $term): Builder
    {
        if (! $term) {
            return $query;
        }

        return $query->where(function (Builder $q) use ($term) {
            $q->where('order_number', 'ilike', "%{$term}%")
                ->orWhereHas('user', fn (Builder $u) => $u->where('name', 'ilike', "%{$term}%"));
        });
    }

    /**
     * Nomor berurutan per hari: INV-YYYYMMDD-0001, -0002, …
     * Wajib dipanggil di dalam transaksi: advisory lock menahan pesanan lain
     * sampai transaksi selesai, jadi dua checkout bersamaan tidak dapat nomor sama.
     */
    public static function generateNumber(): string
    {
        $prefix = 'INV-'.now()->format('Ymd').'-';
        DB::select('select pg_advisory_xact_lock(?)', [crc32('orders.order_number')]);

        $last = static::where('order_number', 'like', $prefix.'%')->max('order_number');
        $next = $last ? ((int) substr($last, strlen($prefix))) + 1 : 1;

        return $prefix.str_pad((string) $next, 4, '0', STR_PAD_LEFT);
    }
}
