<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Batasi akses endpoint berdasarkan role.
 *
 * Penggunaan: ->middleware('role:admin,owner')
 */
class EnsureUserHasRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (! $user) {
            return response()->json(['message' => 'Tidak terautentikasi.'], 401);
        }

        if (! $user->is_active) {
            return response()->json(['message' => 'Akun Anda tidak aktif.'], 403);
        }

        if (! empty($roles) && ! in_array($user->role->value, $roles, true)) {
            return response()->json([
                'message' => 'Anda tidak memiliki akses untuk tindakan ini.',
            ], 403);
        }

        return $next($request);
    }
}
