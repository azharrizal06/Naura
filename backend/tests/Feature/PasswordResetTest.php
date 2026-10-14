<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\PasswordResetCode;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class PasswordResetTest extends TestCase
{
    use RefreshDatabase;

    private const GENERIC = 'Jika email terdaftar, kode reset sudah dikirim. Periksa kotak masuk Anda.';

    protected function setUp(): void
    {
        parent::setUp();
        Notification::fake();
    }

    /** Minta kode untuk [user] dan kembalikan kode yang dikirim lewat email. */
    private function requestCode(User $user): string
    {
        $this->postJson('/api/auth/forgot-password', ['email' => $user->email])->assertOk();

        $code = null;
        Notification::assertSentTo($user, PasswordResetCode::class, function (PasswordResetCode $n) use (&$code) {
            $code = $n->code;

            return true;
        });

        return $code;
    }

    private function reset(string $email, string $code, string $password = 'sandibaru123')
    {
        return $this->postJson('/api/auth/reset-password', [
            'email' => $email,
            'code' => $code,
            'password' => $password,
            'password_confirmation' => $password,
        ]);
    }

    public function test_forgot_password_sends_six_digit_code(): void
    {
        $user = User::factory()->create();

        $this->postJson('/api/auth/forgot-password', ['email' => $user->email])
            ->assertOk()
            ->assertJsonPath('message', self::GENERIC);

        Notification::assertSentTo($user, PasswordResetCode::class, fn (PasswordResetCode $n) => preg_match('/^\d{6}$/', $n->code) === 1);
    }

    public function test_code_is_stored_hashed(): void
    {
        $user = User::factory()->create();
        $code = $this->requestCode($user);

        $stored = \DB::table('password_reset_tokens')->where('email', $user->email)->value('token');
        $this->assertNotSame($code, $stored);
        $this->assertTrue(Hash::check($code, $stored));
    }

    public function test_unknown_or_inactive_email_gets_same_answer_and_no_email(): void
    {
        $inactive = User::factory()->create(['is_active' => false]);

        $this->postJson('/api/auth/forgot-password', ['email' => 'tidak-ada@naura.test'])
            ->assertOk()
            ->assertJsonPath('message', self::GENERIC);
        $this->postJson('/api/auth/forgot-password', ['email' => $inactive->email])
            ->assertOk()
            ->assertJsonPath('message', self::GENERIC);

        Notification::assertNothingSent();
    }

    public function test_reset_with_valid_code_changes_password_and_revokes_sessions(): void
    {
        $user = User::factory()->create(['password' => 'lama12345']);
        $user->createToken('hp-lama');
        $code = $this->requestCode($user);

        $this->reset($user->email, $code)->assertOk();

        $this->assertTrue(Hash::check('sandibaru123', $user->fresh()->password));
        $this->assertSame(0, $user->tokens()->count());
        $this->assertDatabaseMissing('password_reset_tokens', ['email' => $user->email]);
        $this->postJson('/api/auth/login', ['email' => $user->email, 'password' => 'sandibaru123'])->assertOk();
    }

    public function test_code_works_only_once(): void
    {
        $user = User::factory()->create();
        $code = $this->requestCode($user);

        $this->reset($user->email, $code)->assertOk();
        $this->reset($user->email, $code, 'lainlagi123')->assertStatus(422)->assertJsonValidationErrors('code');
    }

    public function test_wrong_code_is_rejected(): void
    {
        $user = User::factory()->create(['password' => 'lama12345']);
        $code = $this->requestCode($user);
        $wrong = $code === '000000' ? '111111' : '000000';

        $this->reset($user->email, $wrong)
            ->assertStatus(422)
            ->assertJsonPath('errors.code.0', 'Kode salah atau sudah kedaluwarsa.');

        $this->assertTrue(Hash::check('lama12345', $user->fresh()->password));
    }

    public function test_code_expires_after_fifteen_minutes(): void
    {
        $user = User::factory()->create();
        $code = $this->requestCode($user);

        Carbon::setTestNow(now()->addMinutes(16));

        $this->reset($user->email, $code)->assertStatus(422)->assertJsonValidationErrors('code');
    }

    public function test_code_is_burned_after_five_wrong_attempts(): void
    {
        $user = User::factory()->create();
        $code = $this->requestCode($user);
        $wrong = $code === '000000' ? '111111' : '000000';

        for ($i = 0; $i < 5; $i++) {
            // IP berbeda tiap kali agar yang diuji batas kode, bukan rate limit.
            $this->withServerVariables(['REMOTE_ADDR' => "10.0.0.{$i}"])->reset($user->email, $wrong)->assertStatus(422);
        }

        $this->withServerVariables(['REMOTE_ADDR' => '10.0.1.1'])
            ->reset($user->email, $code)
            ->assertStatus(422)
            ->assertJsonValidationErrors('code');
    }

    public function test_new_request_replaces_old_code(): void
    {
        $user = User::factory()->create();
        $first = $this->requestCode($user);
        Notification::fake(); // reset catatan notifikasi
        $second = $this->requestCode($user);

        if ($first !== $second) {
            $this->reset($user->email, $first)->assertStatus(422);
        }
        $this->reset($user->email, $second)->assertOk();
    }

    public function test_reset_validates_password(): void
    {
        $user = User::factory()->create();
        $code = $this->requestCode($user);

        $this->postJson('/api/auth/reset-password', [
            'email' => $user->email,
            'code' => $code,
            'password' => 'pendek',
            'password_confirmation' => 'beda',
        ])->assertStatus(422)->assertJsonValidationErrors('password');
    }
}
