<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

abstract class Controller
{
    /** Batas atas `per_page` agar satu permintaan tidak bisa menarik seluruh tabel. */
    protected const MAX_PER_PAGE = 100;

    /** `per_page` dari query, dijepit ke 1..MAX_PER_PAGE. */
    protected function perPage(Request $request, int $default): int
    {
        return max(1, min(self::MAX_PER_PAGE, $request->integer('per_page', $default)));
    }
}
