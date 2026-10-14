<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class ProductImage extends Model
{
    protected $fillable = [
        'product_id',
        'path',
        'is_primary',
        'sort_order',
    ];

    protected $appends = ['url'];

    protected function casts(): array
    {
        return [
            'is_primary' => 'boolean',
            'sort_order' => 'integer',
        ];
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    /**
     * URL mengikuti host permintaan (bukan APP_URL): HP di jaringan lokal, emulator (10.0.2.2),
     * dan domain produksi masing-masing mendapat URL yang bisa mereka jangkau.
     * `demo/...` = gambar demo statis di public/demo; lainnya = unggahan di storage/app/public.
     */
    public function getUrlAttribute(): ?string
    {
        if (! $this->path) {
            return null;
        }
        $path = ltrim($this->path, '/');

        return asset(str_starts_with($path, 'demo/') ? $path : 'storage/'.$path);
    }
}
