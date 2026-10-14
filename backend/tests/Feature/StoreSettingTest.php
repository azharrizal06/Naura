<?php

namespace Tests\Feature;

use App\Models\StoreSetting;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class StoreSettingTest extends TestCase
{
    use RefreshDatabase;

    public function test_publik_bisa_melihat_info_toko_dan_rekening_transfer(): void
    {
        StoreSetting::current()->update([
            'store_name' => 'Naura',
            'store_email' => 'cs@naura.test',
            'store_phone' => '0800-1234-5678',
            'store_address' => 'Talun, Kab. Cirebon',
            'bank_accounts' => [
                ['bank' => 'BCA', 'number' => '1234567890', 'holder' => 'Toko Naura'],
                ['bank' => 'BSI', 'number' => '7777777777', 'holder' => 'Toko Naura'],
            ],
        ]);

        $this->getJson('/api/store')
            ->assertOk()
            ->assertExactJson(['data' => [
                'store_name' => 'Naura',
                'store_email' => 'cs@naura.test',
                'store_phone' => '0800-1234-5678',
                'store_address' => 'Talun, Kab. Cirebon',
                'currency' => 'IDR',
                'bank_accounts' => [
                    ['bank' => 'BCA', 'number' => '1234567890', 'holder' => 'Toko Naura'],
                    ['bank' => 'BSI', 'number' => '7777777777', 'holder' => 'Toko Naura'],
                ],
            ]]);
    }

    public function test_tanpa_rekening_mengembalikan_daftar_kosong(): void
    {
        StoreSetting::current()->update(['bank_accounts' => null]);

        $this->getJson('/api/store')
            ->assertOk()
            ->assertJsonPath('data.bank_accounts', []);
    }

    public function test_info_internal_tidak_ikut_dikirim(): void
    {
        StoreSetting::current()->update(['shipping_origin_id' => 17131, 'flat_shipping_cost' => 15000]);

        $this->getJson('/api/store')
            ->assertOk()
            ->assertJsonMissingPath('data.shipping_origin_id')
            ->assertJsonMissingPath('data.flat_shipping_cost');
    }
}
