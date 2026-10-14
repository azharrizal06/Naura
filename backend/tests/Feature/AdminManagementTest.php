<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AdminManagementTest extends TestCase
{
    use RefreshDatabase;

    private function owner(): User
    {
        return User::factory()->owner()->create();
    }

    public function test_only_owner_manages_admins(): void
    {
        $this->actingAs(User::factory()->admin()->create())->getJson('/api/owner/admins')->assertForbidden();
        $this->actingAs(User::factory()->create())->postJson('/api/owner/admins', [])->assertForbidden();
    }

    public function test_owner_lists_admins_only(): void
    {
        User::factory()->admin()->create(['name' => 'Rina Admin']);
        User::factory()->admin()->create(['name' => 'Agus Admin', 'is_active' => false]);
        User::factory()->create(['name' => 'Budi Customer']);

        $this->actingAs($this->owner())
            ->getJson('/api/owner/admins')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.name', 'Agus Admin')
            ->assertJsonPath('data.0.is_active', false)
            ->assertJsonPath('data.1.name', 'Rina Admin')
            ->assertJsonMissingPath('data.0.password');
    }

    public function test_owner_creates_admin_who_can_log_in(): void
    {
        $this->actingAs($this->owner())
            ->postJson('/api/owner/admins', [
                'name' => 'Rina Admin',
                'email' => 'rina@naura.test',
                'phone' => '081211112222',
                'password' => 'rahasia123',
            ])
            ->assertCreated()
            ->assertJsonPath('data.name', 'Rina Admin')
            ->assertJsonPath('data.role', 'admin')
            ->assertJsonPath('data.is_active', true);

        $this->postJson('/api/auth/login', ['email' => 'rina@naura.test', 'password' => 'rahasia123'])
            ->assertOk();
    }

    public function test_create_validates_unique_email_and_password_length(): void
    {
        User::factory()->create(['email' => 'dipakai@naura.test']);

        $this->actingAs($this->owner())
            ->postJson('/api/owner/admins', [
                'name' => 'X',
                'email' => 'dipakai@naura.test',
                'password' => 'pendek',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['email', 'password']);
    }

    public function test_owner_updates_admin_data_and_resets_password(): void
    {
        $admin = User::factory()->admin()->create(['email' => 'rina@naura.test']);

        $this->actingAs($this->owner())
            ->patchJson("/api/owner/admins/{$admin->id}", [
                'name' => 'Rina Kartika',
                'phone' => '0899',
                'password' => 'sandibaru123',
            ])
            ->assertOk()
            ->assertJsonPath('data.name', 'Rina Kartika')
            ->assertJsonPath('data.phone', '0899');

        $this->assertTrue(Hash::check('sandibaru123', $admin->fresh()->password));
    }

    public function test_update_without_password_keeps_old_password(): void
    {
        $admin = User::factory()->admin()->create(['password' => 'lama12345']);

        $this->actingAs($this->owner())
            ->patchJson("/api/owner/admins/{$admin->id}", ['name' => 'Baru'])
            ->assertOk();

        $this->assertTrue(Hash::check('lama12345', $admin->fresh()->password));
    }

    public function test_email_can_stay_the_same_on_update(): void
    {
        $admin = User::factory()->admin()->create(['email' => 'rina@naura.test']);

        $this->actingAs($this->owner())
            ->patchJson("/api/owner/admins/{$admin->id}", ['email' => 'rina@naura.test'])
            ->assertOk();
    }

    public function test_deactivating_admin_revokes_sessions(): void
    {
        $admin = User::factory()->admin()->create();
        $admin->createToken('dashboard');

        $this->actingAs($this->owner())
            ->patchJson("/api/owner/admins/{$admin->id}", ['is_active' => false])
            ->assertOk()
            ->assertJsonPath('data.is_active', false);

        $this->assertSame(0, $admin->tokens()->count());
    }

    public function test_reactivating_admin(): void
    {
        $admin = User::factory()->admin()->create(['is_active' => false]);

        $this->actingAs($this->owner())
            ->patchJson("/api/owner/admins/{$admin->id}", ['is_active' => true])
            ->assertOk()
            ->assertJsonPath('data.is_active', true);
    }

    public function test_cannot_modify_owner_or_customer_accounts(): void
    {
        $owner = $this->owner();
        $customer = User::factory()->create();
        $otherOwner = User::factory()->owner()->create();

        $this->actingAs($owner)->patchJson("/api/owner/admins/{$customer->id}", ['is_active' => false])->assertNotFound();
        $this->actingAs($owner)->patchJson("/api/owner/admins/{$otherOwner->id}", ['is_active' => false])->assertNotFound();

        $this->assertTrue($customer->fresh()->is_active);
        $this->assertTrue($otherOwner->fresh()->is_active);
    }
}
