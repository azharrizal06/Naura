<?php

namespace App\Support;

use App\Models\User;
use Symfony\Component\HttpKernel\Exception\HttpException;

/** Perlindungan akun demo saat DEMO_MODE aktif (lihat config/demo.php). */
class Demo
{
    public const MESSAGE = 'Fitur ini dinonaktifkan untuk akun demo.';

    public static function isProtected(?User $user): bool
    {
        return $user !== null
            && config('demo.enabled')
            && in_array(mb_strtolower($user->email), config('demo.accounts'), true);
    }

    /** 403 bila [user] akun demo yang dilindungi. */
    public static function guard(?User $user): void
    {
        if (self::isProtected($user)) {
            throw new HttpException(403, self::MESSAGE);
        }
    }
}
