<?php

namespace App\Services\Shipping;

use App\Models\StoreSetting;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Klien RajaOngkir Shipping Cost (Komerce) — https://rajaongkir.com/docs
 *
 * - Autentikasi: header `key` berisi API key (tidak pernah dikirim ke aplikasi).
 * - Pencarian: GET  destination/domestic-destination?search=&limit=&offset=
 * - Tarif:     POST calculate/domestic-cost (form: origin, destination, weight, courier, price)
 *
 * Kuota akun dibatasi per hari, jadi hasil di-cache.
 */
class RajaOngkir
{
    /** Siap dipakai bila API key ada dan lokasi asal toko sudah diatur. */
    public function enabled(): bool
    {
        return $this->hasKey() && $this->originId() !== null;
    }

    public function hasKey(): bool
    {
        return filled(config('services.rajaongkir.key'));
    }

    /** ID tujuan RajaOngkir lokasi toko, dari konfigurasi toko. */
    public function originId(): ?int
    {
        return StoreSetting::current()->shipping_origin_id;
    }

    /** @return list<string> kode kurir yang ditawarkan toko */
    public function couriers(): array
    {
        return array_values(array_filter(explode(':', (string) config('services.rajaongkir.couriers'))));
    }

    /**
     * Cari kecamatan/kelurahan tujuan.
     *
     * @return list<array{id:int,label:string,subdistrict:?string,district:?string,city:?string,province:?string,postal_code:?string}>
     */
    public function searchDestinations(string $search): array
    {
        if (! $this->hasKey()) {
            throw ShippingException::notConfigured();
        }

        $search = mb_strtolower(trim($search));

        return Cache::remember("rajaongkir:dest:{$search}", now()->addDay(), function () use ($search) {
            $response = $this->send(fn (PendingRequest $http) => $http->get('destination/domestic-destination', [
                'search' => $search,
                'limit' => 15,
                'offset' => 0,
            ]), ShippingException::searchFailed(...));
            $rows = $this->dataOf($response, ShippingException::searchFailed(...));

            $results = [];
            foreach ($rows as $r) {
                if (! is_array($r) || ! isset($r['id']) || ! is_numeric($r['id'])) {
                    continue;
                }
                $results[] = [
                    'id' => (int) $r['id'],
                    'label' => (string) ($r['label'] ?? ''),
                    'subdistrict' => $r['subdistrict_name'] ?? null,
                    'district' => $r['district_name'] ?? null,
                    'city' => $r['city_name'] ?? null,
                    'province' => $r['province_name'] ?? null,
                    'postal_code' => isset($r['zip_code']) ? (string) $r['zip_code'] : null,
                ];
            }

            return $results;
        });
    }

    /**
     * Tarif dari lokasi toko ke tujuan. [$couriers] = kode dipisah ":" (default: semua kurir toko).
     * Rute yang tidak dilayani kurir → daftar kosong.
     *
     * @return list<array{courier:string,courier_name:string,service:string,description:string,cost:int,etd:string}>
     */
    public function domesticCost(int $destinationId, int $weightGrams, ?string $couriers = null): array
    {
        $origin = $this->originId();
        $couriers ??= implode(':', $this->couriers());
        $key = "rajaongkir:cost:{$origin}:{$destinationId}:{$weightGrams}:{$couriers}";

        return Cache::remember($key, now()->addMinutes(30), function () use ($origin, $destinationId, $weightGrams, $couriers) {
            $response = $this->send(fn (PendingRequest $http) => $http->asForm()->post('calculate/domestic-cost', [
                'origin' => $origin,
                'destination' => $destinationId,
                'weight' => $weightGrams,
                'courier' => $couriers,
                'price' => 'lowest',
            ]), ShippingException::providerFailed(...));

            // 400 "Calculate Domestic Shipping Cost not found": kurir tidak melayani rute ini.
            if ($response->status() === 400 && str_contains((string) $response->json('meta.message'), 'not found')) {
                return [];
            }

            $rates = [];
            foreach ($this->dataOf($response, ShippingException::providerFailed(...)) as $r) {
                if (! is_array($r) || ! isset($r['code'], $r['service'], $r['cost']) || ! is_numeric($r['cost'])) {
                    continue; // baris tidak lengkap tidak ditawarkan
                }
                $rates[] = [
                    'courier' => (string) $r['code'],
                    'courier_name' => (string) ($r['name'] ?? strtoupper((string) $r['code'])),
                    'service' => (string) $r['service'],
                    'description' => (string) ($r['description'] ?? ''),
                    'cost' => (int) $r['cost'],
                    'etd' => (string) ($r['etd'] ?? ''),
                ];
            }

            return $rates;
        });
    }

    /**
     * Kirim permintaan; gagal jaringan/timeout → exception dari [$failure].
     *
     * @param  callable(): ShippingException  $failure
     */
    private function send(callable $request, callable $failure): Response
    {
        try {
            return $request(
                Http::baseUrl((string) config('services.rajaongkir.base_url'))
                    ->withHeaders(['key' => (string) config('services.rajaongkir.key')])
                    ->acceptJson()
                    ->connectTimeout(5)
                    ->timeout((int) config('services.rajaongkir.timeout', 10))
            );
        } catch (Throwable $e) {
            Log::warning('RajaOngkir tidak bisa dihubungi', ['error' => $e->getMessage()]);
            throw $failure();
        }
    }

    /**
     * Ambil `data` dari respons sukses; selain itu → exception dari [$failure].
     *
     * @param  callable(): ShippingException  $failure
     */
    private function dataOf(Response $response, callable $failure): array
    {
        $data = $response->json('data');
        if ($response->successful() && is_array($data)) {
            return $data;
        }

        // Jangan log header permintaan (berisi API key).
        Log::warning('RajaOngkir menolak permintaan', [
            'status' => $response->status(),
            'message' => $response->json('meta.message'),
        ]);
        throw $failure();
    }
}
