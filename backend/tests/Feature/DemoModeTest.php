<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

/** DEMO_MODE: pengunjung tidak bisa mengunci akun demo untuk pengunjung berikutnya. */
class DemoModeTest extends TestCase
{
    use RefreshDatabase;

    private const MESSAGE = 'Fitur ini dinonaktifkan untuk akun demo.';

    private User $owner;

    private User $admin;

    private User $customer;

    protected function setUp(): void
    {
        parent::setUp();
        config(['demo.enabled' => true]);
        $this->owner = User::factory()->owner()->create(['email' => 'owner@naura.test', 'password' => 'password']);
        $this->admin = User::factory()->admin()->create(['email' => 'admin@naura.test', 'password' => 'password']);
        $this->customer = User::factory()->create(['email' => 'customer@naura.test', 'password' => 'password']);
    }

    public function test_demo_account_cannot_change_password(): void
    {
        $this->actingAs($this->customer)
            ->putJson('/api/auth/password', [
                'current_password' => 'password',
                'password' => 'dikunci123',
                'password_confirmation' => 'dikunci123',
            ])
            ->assertForbidden()
            ->assertJsonPath('message', self::MESSAGE);

        $this->assertTrue(Hash::check('password', $this->customer->fresh()->password));
    }

    public function test_demo_account_cannot_change_email_but_can_change_name(): void
    {
        $this->actingAs($this->owner)
            ->patchJson('/api/auth/profile', ['email' => 'lain@naura.test', 'current_password' => 'password'])
            ->assertForbidden();

        $this->actingAs($this->owner)
            ->patchJson('/api/auth/profile', ['name' => 'Pemilik Demo'])
            ->assertOk();
    }

    public function test_reset_code_is_not_sent_for_demo_account(): void
    {
        Notification::fake();

        $this->postJson('/api/auth/forgot-password', ['email' => 'customer@naura.test'])->assertOk();

        Notification::assertNothingSent();
    }

    public function test_owner_cannot_deactivate_or_repassword_demo_admin(): void
    {
        $this->actingAs($this->owner)
            ->patchJson("/api/owner/admins/{$this->admin->id}", ['is_active' => false])
            ->assertForbidden();
        $this->actingAs($this->owner)
            ->patchJson("/api/owner/admins/{$this->admin->id}", ['password' => 'dikunci123'])
            ->assertForbidden();

        $this->assertTrue($this->admin->fresh()->is_active);
    }

    public function test_owner_can_still_manage_other_admins(): void
    {
        $other = User::factory()->admin()->create();

        $this->actingAs($this->owner)
            ->patchJson("/api/owner/admins/{$other->id}", ['is_active' => false])
            ->assertOk();
    }

    public function test_non_demo_accounts_are_unaffected(): void
    {
        $user = User::factory()->create(['password' => 'lama12345']);

        $this->actingAs($user)
            ->putJson('/api/auth/password', [
                'current_password' => 'lama12345',
                'password' => 'baru123456',
                'password_confirmation' => 'baru123456',
            ])
            ->assertOk();
    }

    public function test_protection_is_off_when_demo_mode_disabled(): void
    {
        config(['demo.enabled' => false]);

        $this->actingAs($this->customer)
            ->putJson('/api/auth/password', [
                'current_password' => 'password',
                'password' => 'baru123456',
                'password_confirmation' => 'baru123456',
            ])
            ->assertOk();
    }
}
