<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        $this->configureRateLimiting();
    }

    /**
     * Batas laju API (429 + Retry-After, pesan bahasa Indonesia):
     * - api: semua endpoint, 120/menit per user (atau IP bila belum login);
     * - auth: login & daftar, 5/menit per email+IP (tebak password) dan 20/menit per IP (banyak email);
     * - shipping: pencarian & tarif RajaOngkir, 30/menit per user (kuota harian terbatas).
     */
    private function configureRateLimiting(): void
    {
        $tooMany = fn () => function (Request $request, array $headers) {
            $seconds = (int) ($headers['Retry-After'] ?? 60);

            return response()->json([
                'message' => "Terlalu banyak percobaan. Coba lagi dalam {$seconds} detik.",
            ], 429, $headers);
        };

        RateLimiter::for('api', fn (Request $request) => Limit::perMinute(120)
            ->by($request->user()?->id ?: $request->ip())
            ->response($tooMany()));

        RateLimiter::for('auth', fn (Request $request) => [
            Limit::perMinute(5)
                ->by('email:'.mb_strtolower((string) $request->input('email')).'|'.$request->ip())
                ->response($tooMany()),
            Limit::perMinute(20)->by('ip:'.$request->ip())->response($tooMany()),
        ]);

        RateLimiter::for('shipping', fn (Request $request) => Limit::perMinute(30)
            ->by($request->user()?->id ?: $request->ip())
            ->response($tooMany()));
    }
}
