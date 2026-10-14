<?php

namespace Tests\Feature;

use App\Models\StoreSetting;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OwnerSettingsTest extends TestCase
{
    use RefreshDatabase;

    private function owner(): User
    {
        return User::factory()->owner()->create();
    }

    private function valid(array $overrides = []): array
    {
        return array_merge([
            'store_name' => 'Naura',
            'store_email' => 'cs@naura.test',
            'store_phone' => '0800-1234-5678',
            'store_address' => 'Talun, Kab. Cirebon',
            'flat_shipping_cost' => 12000,
            'bank_accounts' => [
                ['bank' => 'BCA', 'number' => '1234567890', 'holder' => 'Toko Naura'],
                ['bank' => 'BSI', 'number' => '7777777777', 'holder' => 'Toko Naura'],
            ],
        ], $overrides);
    }

    public function test_only_owner_can_see_or_change_settings(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin)->getJson('/api/owner/settings')->assertForbidden();
        $this->actingAs($admin)->patchJson('/api/owner/settings', $this->valid())->assertForbidden();
    }

    public function test_owner_sees_settings_including_shipping_origin(): void
    {
        StoreSetting::current()->update([
            'store_name' => 'Naura',
            'flat_shipping_cost' => 15000,
            'shipping_origin_id' => 17131,
            'shipping_origin_label' => 'CIPERNA, TALUN, CIREBON',
        ]);

        $this->actingAs($this->owner())
            ->getJson('/api/owner/settings')
            ->assertOk()
            ->assertJsonPath('data.store_name', 'Naura')
            ->assertJsonPath('data.flat_shipping_cost', 15000)
            ->assertJsonPath('data.shipping_origin_id', 17131)
            ->assertJsonPath('data.shipping_origin_label', 'CIPERNA, TALUN, CIREBON')
            ->assertJsonPath('data.bank_accounts', []);
    }

    public function test_owner_updates_settings_and_checkout_sees_new_banks(): void
    {
        $this->actingAs($this->owner())
            ->patchJson('/api/owner/settings', $this->valid())
            ->assertOk()
            ->assertJsonPath('data.store_name', 'Naura')
            ->assertJsonPath('data.flat_shipping_cost', 12000)
            ->assertJsonPath('data.bank_accounts.1.bank', 'BSI');

        $this->getJson('/api/store')
            ->assertJsonPath('data.bank_accounts', [
                ['bank' => 'BCA', 'number' => '1234567890', 'holder' => 'Toko Naura'],
                ['bank' => 'BSI', 'number' => '7777777777', 'holder' => 'Toko Naura'],
            ]);
    }

    public function test_shipping_origin_is_not_changed_by_update(): void
    {
        StoreSetting::current()->update(['shipping_origin_id' => 17131]);

        $this->actingAs($this->owner())
            ->patchJson('/api/owner/settings', $this->valid(['shipping_origin_id' => 1]))
            ->assertOk();

        $this->assertSame(17131, StoreSetting::current()->shipping_origin_id);
    }

    public function test_bank_names_must_be_unique(): void
    {
        $this->actingAs($this->owner())
            ->patchJson('/api/owner/settings', $this->valid(['bank_accounts' => [
                ['bank' => 'BCA', 'number' => '111', 'holder' => 'A'],
                ['bank' => 'bca', 'number' => '222', 'holder' => 'B'],
            ]]))
            ->assertStatus(422)
            ->assertJsonValidationErrors('bank_accounts.1.bank');
    }

    public function test_bank_account_fields_are_required_and_number_is_digits(): void
    {
        $this->actingAs($this->owner())
            ->patchJson('/api/owner/settings', $this->valid(['bank_accounts' => [
                ['bank' => '', 'number' => '12-34', 'holder' => ''],
            ]]))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['bank_accounts.0.bank', 'bank_accounts.0.number', 'bank_accounts.0.holder']);
    }

    public function test_store_name_required_and_shipping_cost_not_negative(): void
    {
        $this->actingAs($this->owner())
            ->patchJson('/api/owner/settings', $this->valid(['store_name' => '', 'flat_shipping_cost' => -1]))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['store_name', 'flat_shipping_cost']);
    }

    public function test_empty_bank_list_is_allowed(): void
    {
        $this->actingAs($this->owner())
            ->patchJson('/api/owner/settings', $this->valid(['bank_accounts' => []]))
            ->assertOk()
            ->assertJsonPath('data.bank_accounts', []);
    }
}
