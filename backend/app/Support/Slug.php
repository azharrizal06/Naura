<?php

namespace App\Support;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Slug
{
    /**
     * Buat slug unik untuk sebuah tabel/kolom.
     * Menambahkan sufiks angka bila sudah dipakai.
     */
    public static function unique(string $modelClass, string $value, string $column = 'slug', ?int $ignoreId = null): string
    {
        $base = Str::slug($value) ?: Str::random(8);
        $slug = $base;
        $i = 1;

        /** @var class-string<Model> $modelClass */
        while (
            $modelClass::query()
                ->where($column, $slug)
                ->when($ignoreId, fn ($q) => $q->where('id', '!=', $ignoreId))
                ->exists()
        ) {
            $slug = $base.'-'.(++$i);
        }

        return $slug;
    }
}
