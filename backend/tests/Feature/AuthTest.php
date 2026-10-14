<?php

namespace Tests\Feature;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_can_register(): void
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'Budi',
            'email' => 'budi@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertCreated()
            ->assertJsonStructure(['message', 'user' => ['id', 'email', 'role'], 'token']);

        $this->assertDatabaseHas('users', [
            'email' => 'budi@example.com',
            'role' => UserRole::Customer->value,
        ]);
    }

    public function test_user_can_login_with_valid_credentials(): void
    {
        $user = User::factory()->create(['password' => 'password123']);

        $response = $this->postJson('/api/auth/login', [
            'email' => $user->email,
            'password' => 'password123',
        ]);

        $response->assertOk()->assertJsonStructure(['token', 'user']);
    }

    public function test_login_fails_with_invalid_credentials(): void
    {
        $user = User::factory()->create(['password' => 'password123']);

        $this->postJson('/api/auth/login', [
            'email' => $user->email,
            'password' => 'salah',
        ])->assertStatus(422);
    }

    public function test_inactive_user_cannot_login(): void
    {
        $user = User::factory()->create(['password' => 'password123', 'is_active' => false]);

        $this->postJson('/api/auth/login', [
            'email' => $user->email,
            'password' => 'password123',
        ])->assertStatus(422);
    }

    public function test_customer_cannot_access_dashboard_route(): void
    {
        $customer = User::factory()->create();

        $this->actingAs($customer)
            ->getJson('/api/dashboard/ping')
            ->assertStatus(403);
    }

    public function test_admin_can_access_dashboard_route(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin)
            ->getJson('/api/dashboard/ping')
            ->assertOk();
    }

    public function test_admin_cannot_access_owner_route(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin)
            ->getJson('/api/owner/ping')
            ->assertStatus(403);
    }

    public function test_owner_can_access_owner_route(): void
    {
        $owner = User::factory()->owner()->create();

        $this->actingAs($owner)
            ->getJson('/api/owner/ping')
            ->assertOk();
    }
}
