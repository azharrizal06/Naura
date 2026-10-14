<?php

namespace App\Http\Resources;

use App\Models\StoreSetting;
use Illuminate\Http\Request;

/**
 * Pengaturan lengkap untuk Owner: info publik + ongkir flat & asal ongkir.
 *
 * @mixin StoreSetting
 */
class OwnerStoreSettingResource extends StoreSettingResource
{
    public function toArray(Request $request): array
    {
        return [
            ...parent::toArray($request),
            'flat_shipping_cost' => $this->flat_shipping_cost,
            'shipping_origin_id' => $this->shipping_origin_id,
            'shipping_origin_label' => $this->shipping_origin_label,
        ];
    }
}
