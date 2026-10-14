<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\ResetPasswordRequest;
use App\Models\User;
use App\Notifications\PasswordResetCode;
use App\Support\Demo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

/**
 * Lupa password dengan kode 6 digit via email (Fase 7).
 * Kode disimpan ter-hash di `password_reset_tokens`, berlaku 15 menit,
 * hangus setelah 5 kali salah atau setelah dipakai.
 */
class PasswordResetController extends Controller
{
    private const EXPIRES_MINUTES = 15;

    private const MAX_ATTEMPTS = 5;

    public function forgot(Request $request): JsonResponse
    {
        $request->validate(['email' => ['required', 'string', 'email']]);
        $email = mb_strtolower($request->string('email')->trim()->value());

        $user = User::whereRaw('lower(email) = ?', [$email])->where('is_active', true)->first();
        // Akun demo tidak menerima kode: pengunjung tidak bisa mengganti password-nya.
        if ($user && ! Demo::isProtected($user)) {
            $code = str_pad((string) random_int(0, 999_999), 6, '0', STR_PAD_LEFT);
            // Satu kode aktif per email: permintaan baru menimpa yang lama.
            DB::table('password_reset_tokens')->updateOrInsert(
                ['email' => $user->email],
                ['token' => Hash::make($code), 'attempts' => 0, 'created_at' => now()],
            );
            $user->notify(new PasswordResetCode($code, self::EXPIRES_MINUTES));
        }

        // Jawaban sama untuk email terdaftar atau tidak — cegah pengecekan email.
        return response()->json([
            'message' => 'Jika email terdaftar, kode reset sudah dikirim. Periksa kotak masuk Anda.',
        ]);
    }

    public function reset(ResetPasswordRequest $request): JsonResponse
    {
        $email = mb_strtolower($request->string('email')->trim()->value());
        $user = User::whereRaw('lower(email) = ?', [$email])->where('is_active', true)->first();
        $row = $user ? DB::table('password_reset_tokens')->where('email', $user->email)->first() : null;

        $valid = $row
            && Carbon::parse($row->created_at)->addMinutes(self::EXPIRES_MINUTES)->isFuture()
            && $row->attempts < self::MAX_ATTEMPTS
            && Hash::check($request->string('code')->trim()->value(), $row->token);

        if (! $valid) {
            if ($row) {
                DB::table('password_reset_tokens')->where('email', $row->email)->increment('attempts');
            }
            throw ValidationException::withMessages(['code' => 'Kode salah atau sudah kedaluwarsa.']);
        }

        $user->update(['password' => $request->validated('password')]);
        DB::table('password_reset_tokens')->where('email', $user->email)->delete();
        // Siapa pun yang memegang sesi lama harus login ulang.
        $user->tokens()->delete();

        return response()->json(['message' => 'Password berhasil diganti. Silakan masuk dengan password baru.']);
    }
}
