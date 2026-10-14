<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AddressTest extends TestCase
{
    use RefreshDatabase;

    private function payload(array $overrides = []): array
    {
        return array_merge([
            'label' => 'Rumah',
            'recipient_name' => 'Budi Customer',
            'phone' => '081200000003',
            'address_line' => 'Jl. Merdeka 1, RT 02/RW 05',
            'subdistrict' => 'Braga',
            'district' => 'Sumur Bandung',
            'city' => 'Bandung',
            'province' => 'Jawa Barat',
            'postal_code' => '40111',
            'destination_id' => 4949,
        ], $overrides);
    }

    public function test_first_address_becomes_default(): void
    {
        $this->actingAs(User::factory()->create())
            ->postJson('/api/addresses', $this->payload())
            ->assertCreated()
            ->assertJsonPath('data.label', 'Rumah')
            ->assertJsonPath('data.subdistrict', 'Braga')
            ->assertJsonPath('data.destination_id', 4949)
            ->assertJsonPath('data.is_default', true);
    }

    public function test_new_default_address_replaces_previous_default(): void
    {
        $customer = User::factory()->create();
        $first = $this->actingAs($customer)->postJson('/api/addresses', $this->payload())->json('data.id');

        $this->actingAs($customer)
            ->postJson('/api/addresses', $this->payload(['label' => 'Kantor', 'is_default' => true]))
            ->assertCreated()
            ->assertJsonPath('data.is_default', true);

        $this->actingAs($customer)
            ->getJson('/api/addresses')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.label', 'Kantor')
            ->assertJsonPath('data.1.id', $first)
            ->assertJsonPath('data.1.is_default', false);
    }

    public function test_customer_updates_and_deletes_own_address(): void
    {
        $customer = User::factory()->create();
        $id = $this->actingAs($customer)->postJson('/api/addresses', $this->payload())->json('data.id');

        $this->actingAs($customer)
            ->patchJson("/api/addresses/{$id}", $this->payload(['label' => 'Rumah Ibu']))
            ->assertOk()
            ->assertJsonPath('data.label', 'Rumah Ibu');

        $this->actingAs($customer)->deleteJson("/api/addresses/{$id}")->assertNoContent();
        $this->actingAs($customer)->getJson('/api/addresses')->assertJsonCount(0, 'data');
    }

    public function test_deleting_default_promotes_another_address(): void
    {
        $customer = User::factory()->create();
        $first = $this->actingAs($customer)->postJson('/api/addresses', $this->payload())->json('data.id');
        $second = $this->actingAs($customer)->postJson('/api/addresses', $this->payload(['label' => 'Kantor']))->json('data.id');

        $this->actingAs($customer)->deleteJson("/api/addresses/{$first}")->assertNoContent();

        $this->actingAs($customer)
            ->getJson('/api/addresses')
            ->assertJsonPath('data.0.id', $second)
            ->assertJsonPath('data.0.is_default', true);
    }

    public function test_customer_cannot_touch_another_customers_address(): void
    {
        $id = $this->actingAs(User::factory()->create())->postJson('/api/addresses', $this->payload())->json('data.id');
        $other = User::factory()->create();

        $this->actingAs($other)->patchJson("/api/addresses/{$id}", $this->payload())->assertNotFound();
        $this->actingAs($other)->deleteJson("/api/addresses/{$id}")->assertNotFound();
    }

    public function test_incomplete_address_is_rejected(): void
    {
        $this->actingAs(User::factory()->create())
            ->postJson('/api/addresses', $this->payload(['city' => '', 'postal_code' => '12']))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['city', 'postal_code']);
    }
}
