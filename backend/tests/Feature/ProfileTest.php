<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class ProfileTest extends TestCase
{
    use RefreshDatabase;

    // --- Ubah profil ----------------------------------------------------

    public function test_user_updates_name_and_phone(): void
    {
        $user = User::factory()->create(['name' => 'Budi', 'phone' => '0811']);

        $this->actingAs($user)
            ->patchJson('/api/auth/profile', ['name' => 'Budi Santoso', 'phone' => '0812'])
            ->assertOk()
            ->assertJsonPath('data.name', 'Budi Santoso')
            ->assertJsonPath('data.phone', '0812');
    }

    public function test_admin_and_owner_can_update_their_profile(): void
    {
        foreach ([User::factory()->admin()->create(), User::factory()->owner()->create()] as $user) {
            $this->actingAs($user)->patchJson('/api/auth/profile', ['name' => 'Nama Baru'])->assertOk();
        }
    }

    public function test_changing_email_requires_current_password(): void
    {
        $user = User::factory()->create(['email' => 'lama@naura.test', 'password' => 'rahasia123']);

        $this->actingAs($user)
            ->patchJson('/api/auth/profile', ['email' => 'baru@naura.test'])
            ->assertStatus(422)
            ->assertJsonValidationErrors('current_password');

        $this->actingAs($user)
            ->patchJson('/api/auth/profile', ['email' => 'baru@naura.test', 'current_password' => 'salah'])
            ->assertStatus(422)
            ->assertJsonPath('errors.current_password.0', 'Password saat ini salah.');

        $this->actingAs($user)
            ->patchJson('/api/auth/profile', ['email' => 'baru@naura.test', 'current_password' => 'rahasia123'])
            ->assertOk()
            ->assertJsonPath('data.email', 'baru@naura.test');
    }

    public function test_same_email_needs_no_password(): void
    {
        $user = User::factory()->create(['email' => 'saya@naura.test']);

        $this->actingAs($user)
            ->patchJson('/api/auth/profile', ['email' => 'saya@naura.test', 'name' => 'X'])
            ->assertOk();
    }

    public function test_email_must_be_unique(): void
    {
        User::factory()->create(['email' => 'dipakai@naura.test']);
        $user = User::factory()->create(['password' => 'rahasia123']);

        $this->actingAs($user)
            ->patchJson('/api/auth/profile', ['email' => 'dipakai@naura.test', 'current_password' => 'rahasia123'])
            ->assertStatus(422)
            ->assertJsonValidationErrors('email');
    }

    public function test_profile_cannot_change_role_or_status(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->patchJson('/api/auth/profile', ['name' => 'X', 'role' => 'owner', 'is_active' => false])
            ->assertOk()
            ->assertJsonPath('data.role', 'customer')
            ->assertJsonPath('data.is_active', true);
    }

    // --- Ganti password --------------------------------------------------

    public function test_change_password_keeps_current_session_and_revokes_others(): void
    {
        $user = User::factory()->create(['password' => 'lama12345']);
        $user->createToken('perangkat-lain');
        $current = $user->createToken('perangkat-ini')->plainTextToken;

        $this->withToken($current)
            ->putJson('/api/auth/password', [
                'current_password' => 'lama12345',
                'password' => 'baru123456',
                'password_confirmation' => 'baru123456',
            ])
            ->assertOk();

        $this->assertTrue(Hash::check('baru123456', $user->fresh()->password));
        $this->assertSame(['perangkat-ini'], $user->tokens()->pluck('name')->all());
    }

    public function test_change_password_rejects_wrong_current_password(): void
    {
        $user = User::factory()->create(['password' => 'lama12345']);

        $this->actingAs($user)
            ->putJson('/api/auth/password', [
                'current_password' => 'salah',
                'password' => 'baru123456',
                'password_confirmation' => 'baru123456',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors('current_password');

        $this->assertTrue(Hash::check('lama12345', $user->fresh()->password));
    }

    public function test_change_password_validates_new_password(): void
    {
        $user = User::factory()->create(['password' => 'lama12345']);

        $this->actingAs($user)
            ->putJson('/api/auth/password', [
                'current_password' => 'lama12345',
                'password' => 'pendek',
                'password_confirmation' => 'beda',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors('password');
    }

    // --- Dari audit: akun nonaktif & token kedaluwarsa --------------------

    public function test_inactive_account_is_rejected_on_any_authenticated_endpoint(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('hp')->plainTextToken;
        $user->update(['is_active' => false]);

        $this->withToken($token)
            ->getJson('/api/auth/me')
            ->assertForbidden()
            ->assertJsonPath('message', 'Akun Anda tidak aktif.');
    }

    public function test_token_expires_after_thirty_days(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('hp')->plainTextToken;

        Carbon::setTestNow(now()->addDays(29));
        $this->withToken($token)->getJson('/api/auth/me')->assertOk();

        $this->app['auth']->forgetGuards();
        Carbon::setTestNow(now()->addDays(2));
        $this->withToken($token)->getJson('/api/auth/me')->assertUnauthorized();
    }
}
