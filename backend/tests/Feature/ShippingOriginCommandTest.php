<?php

namespace Tests\Feature;

use App\Models\StoreSetting;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class ShippingOriginCommandTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['services.rajaongkir.key' => 'test-key', 'services.rajaongkir.base_url' => 'https://rajaongkir.komerce.id/api/v1']);
        Http::fake(['*/destination/domestic-destination*' => Http::response(['meta' => ['code' => 200], 'data' => [[
            'id' => 4949, 'label' => 'BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111',
            'province_name' => 'JAWA BARAT', 'city_name' => 'BANDUNG', 'district_name' => 'SUMUR BANDUNG',
            'subdistrict_name' => 'BRAGA', 'zip_code' => '40111',
        ]]])]);
    }

    public function test_sets_origin_from_search_result(): void
    {
        $this->artisan('store:shipping-origin', ['search' => 'braga', '--id' => 4949])
            ->assertSuccessful();

        $settings = StoreSetting::current()->fresh();
        $this->assertSame(4949, $settings->shipping_origin_id);
        $this->assertSame('BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111', $settings->shipping_origin_label);
    }

    public function test_rejects_id_that_is_not_in_search_results(): void
    {
        $this->artisan('store:shipping-origin', ['search' => 'braga', '--id' => 12345])
            ->assertFailed();

        $this->assertNull(StoreSetting::current()->fresh()->shipping_origin_id);
    }
}
