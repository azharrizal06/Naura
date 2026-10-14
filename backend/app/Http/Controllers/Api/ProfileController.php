<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\ChangePasswordRequest;
use App\Http\Requests\Auth\UpdateProfileRequest;
use App\Http\Resources\UserResource;
use App\Support\Demo;
use Illuminate\Http\JsonResponse;
use Laravel\Sanctum\PersonalAccessToken;

/**
 * Profil & password milik user yang sedang login — semua role (Fase 7).
 */
class ProfileController extends Controller
{
    public function update(UpdateProfileRequest $request): UserResource
    {
        if ($request->emailChanged()) {
            Demo::guard($request->user());
        }
        $data = $request->safe()->only(['name', 'phone', 'email']);
        if (isset($data['email'])) {
            $data['email'] = trim($data['email']);
        }
        $request->user()->update($data);

        return new UserResource($request->user());
    }

    public function changePassword(ChangePasswordRequest $request): JsonResponse
    {
        $user = $request->user();
        Demo::guard($user);
        $user->update(['password' => $request->validated('password')]);

        // Perangkat lain harus login ulang; perangkat ini tetap masuk.
        $current = $user->currentAccessToken();
        $user->tokens()
            ->when($current instanceof PersonalAccessToken, fn ($q) => $q->whereKeyNot($current->getKey()))
            ->delete();

        return response()->json(['message' => 'Password berhasil diganti. Perangkat lain perlu masuk ulang.']);
    }
}
