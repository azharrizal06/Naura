<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ThrottleTest extends TestCase
{
    use RefreshDatabase;

    public function test_login_is_limited_per_email_after_five_failed_attempts(): void
    {
        User::factory()->create(['email' => 'korban@naura.test']);

        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/auth/login', ['email' => 'korban@naura.test', 'password' => "tebak{$i}"])
                ->assertStatus(422);
        }

        $this->postJson('/api/auth/login', ['email' => 'korban@naura.test', 'password' => 'tebak5'])
            ->assertStatus(429)
            ->assertHeader('Retry-After')
            ->assertJsonPath('message', fn (string $m) => str_starts_with($m, 'Terlalu banyak percobaan.'));
    }

    public function test_login_limit_per_email_does_not_block_other_accounts(): void
    {
        User::factory()->create(['email' => 'korban@naura.test']);
        User::factory()->create(['email' => 'lain@naura.test', 'password' => 'password']);

        for ($i = 0; $i < 6; $i++) {
            $this->postJson('/api/auth/login', ['email' => 'korban@naura.test', 'password' => 'salah']);
        }

        $this->postJson('/api/auth/login', ['email' => 'lain@naura.test', 'password' => 'password'])->assertOk();
    }

    public function test_login_is_limited_per_ip_across_many_emails(): void
    {
        for ($i = 0; $i < 20; $i++) {
            $this->postJson('/api/auth/login', ['email' => "orang{$i}@naura.test", 'password' => 'salah'])
                ->assertStatus(422);
        }

        $this->postJson('/api/auth/login', ['email' => 'orang99@naura.test', 'password' => 'salah'])
            ->assertStatus(429);
    }

    public function test_register_shares_the_auth_limit(): void
    {
        for ($i = 0; $i < 20; $i++) {
            $this->postJson('/api/auth/register', ['email' => "spam{$i}@naura.test"])->assertStatus(422);
        }

        $this->postJson('/api/auth/register', ['email' => 'spam99@naura.test'])->assertStatus(429);
    }

    public function test_shipping_destination_search_is_limited_per_user(): void
    {
        $customer = User::factory()->create();

        for ($i = 0; $i < 30; $i++) {
            // Tanpa API key → 503, tetapi tetap dihitung.
            $this->actingAs($customer)->getJson("/api/shipping/destinations?search=braga{$i}")->assertStatus(503);
        }

        $this->actingAs($customer)->getJson('/api/shipping/destinations?search=braga')->assertStatus(429);
    }

    public function test_general_api_limit(): void
    {
        for ($i = 0; $i < 120; $i++) {
            $this->getJson('/api/catalog/categories')->assertOk();
        }

        $this->getJson('/api/catalog/categories')->assertStatus(429);
    }
}
