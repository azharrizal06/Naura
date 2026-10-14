<?php

namespace App\Http\Resources;

use App\Models\StoreSetting;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Info toko untuk publik. Asal ongkir & ongkir flat sengaja tidak dikirim.
 *
 * @mixin StoreSetting
 */
class StoreSettingResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'store_name' => $this->store_name,
            'store_email' => $this->store_email,
            'store_phone' => $this->store_phone,
            'store_address' => $this->store_address,
            'currency' => $this->currency,
            // jsonb menyusun ulang key; kirim dengan urutan tetap.
            'bank_accounts' => collect($this->bank_accounts ?? [])
                ->map(fn (array $a) => ['bank' => $a['bank'], 'number' => $a['number'], 'holder' => $a['holder']])
                ->values()
                ->all(),
        ];
    }
}
