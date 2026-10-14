<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Tolak akun nonaktif di semua endpoint terautentikasi (termasuk /auth/me),
 * bukan hanya di rute ber-role.
 */
class EnsureUserIsActive
{
    public function handle(Request $request, Closure $next): Response
    {
        if ($request->user() && ! $request->user()->is_active) {
            return response()->json(['message' => 'Akun Anda tidak aktif.'], 403);
        }

        return $next($request);
    }
}
