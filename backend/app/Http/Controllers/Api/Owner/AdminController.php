<?php

namespace App\Http\Controllers\Api\Owner;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\Owner\AdminRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Support\Demo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/**
 * Kelola akun admin oleh Owner (Fase 6). Hanya akun ber-role admin;
 * tidak ada hapus permanen agar riwayat tetap utuh — nonaktifkan saja.
 */
class AdminController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return UserResource::collection(
            User::where('role', UserRole::Admin->value)->orderBy('name')->get()
        );
    }

    public function store(AdminRequest $request): JsonResponse
    {
        $admin = User::create([
            ...$request->safe()->only(['name', 'email', 'phone', 'password']),
            'role' => UserRole::Admin->value,
            'is_active' => true,
        ]);

        return (new UserResource($admin))->response()->setStatusCode(201);
    }

    public function update(AdminRequest $request, int $admin): UserResource
    {
        $user = User::where('role', UserRole::Admin->value)->findOrFail($admin);
        // Admin demo: nama & HP boleh diubah, tetapi tidak bisa dikunci (status, password, email).
        if ($request->hasAny(['is_active', 'password', 'email'])) {
            Demo::guard($user);
        }

        $data = $request->safe()->only(['name', 'email', 'phone', 'is_active']);
        if ($request->filled('password')) {
            $data['password'] = $request->validated('password');
        }
        $user->update($data);

        // Nonaktif → semua sesi dicabut agar admin langsung keluar dari dashboard.
        if (! $user->is_active) {
            $user->tokens()->delete();
        }

        return new UserResource($user);
    }
}
