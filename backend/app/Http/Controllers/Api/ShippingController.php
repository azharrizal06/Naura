<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Shipping\ShippingRatesRequest;
use App\Models\Cart;
use App\Services\Shipping\RajaOngkir;
use App\Services\Shipping\ShippingRateService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Pencarian tujuan & pilihan ongkir (Fase 3). API key RajaOngkir hanya
 * ada di server; aplikasi memanggil lewat endpoint ini.
 */
class ShippingController extends Controller
{
    public function destinations(Request $request, RajaOngkir $rajaOngkir): JsonResponse
    {
        $request->validate(['search' => ['required', 'string', 'min:3', 'max:100']]);

        return response()->json(['data' => $rajaOngkir->searchDestinations($request->string('search'))]);
    }

    public function rates(ShippingRatesRequest $request, ShippingRateService $rates): JsonResponse
    {
        $user = $request->user();
        $address = $user->addresses()->findOrFail($request->integer('address_id'));
        $cart = Cart::firstOrCreate(['user_id' => $user->id]);

        return response()->json([
            'data' => $rates->ratesFor($cart, $address, $request->validated('courier')),
        ]);
    }
}
