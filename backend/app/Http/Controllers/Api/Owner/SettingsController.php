<?php

namespace App\Http\Controllers\Api\Owner;

use App\Http\Controllers\Controller;
use App\Http\Requests\Owner\UpdateStoreSettingsRequest;
use App\Http\Resources\OwnerStoreSettingResource;
use App\Models\StoreSetting;
use Illuminate\Http\JsonResponse;

/**
 * Pengaturan toko oleh Owner (Fase 6). Asal ongkir tidak diubah di sini —
 * pakai `php artisan store:shipping-origin` (ID harus dari pencarian RajaOngkir).
 */
class SettingsController extends Controller
{
    public function show(): JsonResponse
    {
        return $this->respond(StoreSetting::current());
    }

    public function update(UpdateStoreSettingsRequest $request): JsonResponse
    {
        $settings = StoreSetting::current();
        $settings->update([
            ...$request->safe()->only(['store_name', 'store_email', 'store_phone', 'store_address', 'flat_shipping_cost']),
            'bank_accounts' => $request->bankAccounts(),
        ]);

        return $this->respond($settings);
    }

    /** Selalu 200 — baris pengaturan bisa baru dibuat oleh current(), dan resource lalu menjawab 201. */
    private function respond(StoreSetting $settings): JsonResponse
    {
        return (new OwnerStoreSettingResource($settings))->response()->setStatusCode(200);
    }
}
