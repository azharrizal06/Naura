<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Address\AddressRequest;
use App\Http\Resources\AddressResource;
use App\Models\Address;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

/**
 * Alamat pengiriman tersimpan milik customer (Fase 3).
 * Selalu ada tepat satu alamat default selama customer punya alamat.
 */
class AddressController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $addresses = $request->user()->addresses()
            ->orderByDesc('is_default')
            ->latest('id')
            ->get();

        return AddressResource::collection($addresses);
    }

    public function store(AddressRequest $request): JsonResponse
    {
        $user = $request->user();

        $address = DB::transaction(function () use ($request, $user) {
            $makeDefault = $request->boolean('is_default') || ! $user->addresses()->exists();
            if ($makeDefault) {
                $user->addresses()->update(['is_default' => false]);
            }

            return $user->addresses()->create([
                ...$request->safe()->except('is_default'),
                'is_default' => $makeDefault,
            ]);
        });

        return (new AddressResource($address))->response()->setStatusCode(201);
    }

    public function update(AddressRequest $request, int $address): AddressResource
    {
        $model = $request->user()->addresses()->findOrFail($address);

        DB::transaction(function () use ($request, $model) {
            if ($request->boolean('is_default')) {
                $request->user()->addresses()->whereKeyNot($model->id)->update(['is_default' => false]);
                $model->is_default = true;
            }
            $model->fill($request->safe()->except('is_default'))->save();
        });

        return new AddressResource($model);
    }

    public function destroy(Request $request, int $address): Response
    {
        $model = $request->user()->addresses()->findOrFail($address);

        DB::transaction(function () use ($request, $model) {
            $model->delete();
            if ($model->is_default) {
                /** @var Address|null $next */
                $next = $request->user()->addresses()->latest('id')->first();
                $next?->update(['is_default' => true]);
            }
        });

        return response()->noContent();
    }
}
