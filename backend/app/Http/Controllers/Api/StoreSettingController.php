<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\StoreSettingResource;
use App\Models\StoreSetting;

class StoreSettingController extends Controller
{
    /** Info toko + rekening transfer (dipakai layar checkout). */
    public function show(): StoreSettingResource
    {
        return new StoreSettingResource(StoreSetting::current());
    }
}
