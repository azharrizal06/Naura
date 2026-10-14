<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\StoreSetting;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class ShippingTest extends TestCase
{
    use RefreshDatabase;

    private const BASE = 'https://rajaongkir.komerce.id/api/v1';

    protected function setUp(): void
    {
        parent::setUp();
        StoreSetting::current()->update(['flat_shipping_cost' => 15000]);
    }

    /** Nilai uji: origin toko diambil dari store_settings, bukan .env. */
    private function configureRajaOngkir(): void
    {
        config([
            'services.rajaongkir.key' => 'test-key',
            'services.rajaongkir.base_url' => self::BASE,
            'services.rajaongkir.couriers' => 'jne:jnt',
        ]);
        StoreSetting::current()->update(['shipping_origin_id' => 501]);
    }

    /** Customer dengan 2 × gamis 450 g di keranjang dan satu alamat. */
    private function customerReadyToShip(?int $destinationId = 4949): array
    {
        $product = Product::factory()->create(['weight_grams' => 450, 'is_active' => true]);
        $variant = ProductVariant::factory()->create([
            'product_id' => $product->id, 'stock' => 10, 'price' => 289000, 'is_active' => true,
        ]);
        $customer = User::factory()->create();
        $this->actingAs($customer)->postJson('/api/cart/items', ['variant_id' => $variant->id, 'quantity' => 2]);
        $addressId = $this->actingAs($customer)->postJson('/api/addresses', [
            'label' => 'Rumah', 'recipient_name' => 'Budi', 'phone' => '081200000003',
            'address_line' => 'Jl. Merdeka 1', 'city' => 'Bandung', 'province' => 'Jawa Barat',
            'postal_code' => '40111', 'destination_id' => $destinationId,
        ])->json('data.id');

        return [$customer, $addressId];
    }

    private function fakeCosts(): void
    {
        Http::fake([
            self::BASE.'/calculate/domestic-cost' => Http::response(['meta' => ['code' => 200], 'data' => [
                ['name' => 'Jalur Nugraha Ekakurir (JNE)', 'code' => 'jne', 'service' => 'REG', 'description' => 'Layanan Reguler', 'cost' => 18000, 'etd' => '2-3 day'],
                ['name' => 'J&T Express', 'code' => 'jnt', 'service' => 'EZ', 'description' => 'Reguler', 'cost' => 16000, 'etd' => '2-4 day'],
            ]]),
        ]);
    }

    public function test_destination_search_proxies_rajaongkir(): void
    {
        $this->configureRajaOngkir();
        Http::fake([
            self::BASE.'/destination/domestic-destination*' => Http::response(['meta' => ['code' => 200], 'data' => [[
                'id' => 4949, 'label' => 'BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111',
                'province_name' => 'JAWA BARAT', 'city_name' => 'BANDUNG', 'district_name' => 'SUMUR BANDUNG',
                'subdistrict_name' => 'BRAGA', 'zip_code' => '40111',
            ]]]),
        ]);

        $this->actingAs(User::factory()->create())
            ->getJson('/api/shipping/destinations?search=braga')
            ->assertOk()
            ->assertJsonPath('data.0.id', 4949)
            ->assertJsonPath('data.0.subdistrict', 'BRAGA')
            ->assertJsonPath('data.0.district', 'SUMUR BANDUNG')
            ->assertJsonPath('data.0.city', 'BANDUNG')
            ->assertJsonPath('data.0.province', 'JAWA BARAT')
            ->assertJsonPath('data.0.postal_code', '40111');

        Http::assertSent(fn (Request $r) => $r->hasHeader('key', 'test-key')
            && str_contains($r->url(), 'search=braga'));
    }

    public function test_destination_search_unavailable_without_api_key(): void
    {
        config(['services.rajaongkir.key' => null]);

        $this->actingAs(User::factory()->create())
            ->getJson('/api/shipping/destinations?search=braga')
            ->assertStatus(503);
    }

    public function test_rates_use_cart_weight_and_are_sorted_by_cost(): void
    {
        $this->configureRajaOngkir();
        StoreSetting::current()->update(['shipping_origin_id' => 777]); // origin dibaca dari konfigurasi toko
        $this->fakeCosts();
        [$customer, $addressId] = $this->customerReadyToShip();

        $this->actingAs($customer)
            ->postJson('/api/shipping/rates', ['address_id' => $addressId])
            ->assertOk()
            ->assertJsonPath('data.0.courier', 'jnt')
            ->assertJsonPath('data.0.service', 'EZ')
            ->assertJsonPath('data.0.cost', 16000)
            ->assertJsonPath('data.0.etd', '2-4 day')
            ->assertJsonPath('data.1.courier_name', 'Jalur Nugraha Ekakurir (JNE)');

        Http::assertSent(fn (Request $r) => $r['origin'] == 777
            && $r['destination'] == 4949
            && $r['weight'] == 900
            && $r['courier'] === 'jne:jnt');
    }

    public function test_same_rates_request_is_cached(): void
    {
        $this->configureRajaOngkir();
        $this->fakeCosts();
        [$customer, $addressId] = $this->customerReadyToShip();

        $this->actingAs($customer)->postJson('/api/shipping/rates', ['address_id' => $addressId])->assertOk();
        $this->actingAs($customer)->postJson('/api/shipping/rates', ['address_id' => $addressId])->assertOk();

        Http::assertSentCount(1);
    }

    public function test_rates_fall_back_to_flat_cost_without_api_key(): void
    {
        config(['services.rajaongkir.key' => null]);
        Http::fake();
        [$customer, $addressId] = $this->customerReadyToShip(destinationId: null);

        $this->actingAs($customer)
            ->postJson('/api/shipping/rates', ['address_id' => $addressId])
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.courier', 'toko')
            ->assertJsonPath('data.0.cost', 15000);

        Http::assertNothingSent();
    }

    public function test_address_without_destination_cannot_get_courier_rates(): void
    {
        $this->configureRajaOngkir();
        Http::fake();
        [$customer, $addressId] = $this->customerReadyToShip(destinationId: null);

        $this->actingAs($customer)
            ->postJson('/api/shipping/rates', ['address_id' => $addressId])
            ->assertStatus(422)
            ->assertJsonValidationErrors('address_id');
    }

    public function test_store_without_origin_uses_flat_cost(): void
    {
        $this->configureRajaOngkir();
        StoreSetting::current()->update(['shipping_origin_id' => null]);
        Http::fake();
        [$customer, $addressId] = $this->customerReadyToShip();

        $this->actingAs($customer)
            ->postJson('/api/shipping/rates', ['address_id' => $addressId])
            ->assertOk()
            ->assertJsonPath('data.0.courier', 'toko');

        Http::assertNothingSent();
    }

    public function test_rates_can_be_limited_to_one_courier(): void
    {
        $this->configureRajaOngkir();
        $this->fakeCosts();
        [$customer, $addressId] = $this->customerReadyToShip();

        $this->actingAs($customer)
            ->postJson('/api/shipping/rates', ['address_id' => $addressId, 'courier' => 'jne'])
            ->assertOk();

        Http::assertSent(fn (Request $r) => $r['courier'] === 'jne');
    }

    public function test_courier_outside_store_list_is_rejected(): void
    {
        $this->configureRajaOngkir();
        Http::fake();
        [$customer, $addressId] = $this->customerReadyToShip();

        $this->actingAs($customer)
            ->postJson('/api/shipping/rates', ['address_id' => $addressId, 'courier' => 'dhl'])
            ->assertStatus(422)
            ->assertJsonValidationErrors('courier');

        Http::assertNothingSent();
    }

    public function test_route_not_served_returns_empty_rates(): void
    {
        $this->configureRajaOngkir();
        Http::fake([self::BASE.'/calculate/domestic-cost' => Http::response([
            'meta' => ['message' => 'Calculate Domestic Shipping Cost not found', 'code' => 400, 'status' => 'error'],
            'data' => null,
        ], 400)]);
        [$customer, $addressId] = $this->customerReadyToShip();

        $this->actingAs($customer)
            ->postJson('/api/shipping/rates', ['address_id' => $addressId])
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    public function test_incomplete_rate_rows_are_skipped(): void
    {
        $this->configureRajaOngkir();
        Http::fake([self::BASE.'/calculate/domestic-cost' => Http::response(['meta' => ['code' => 200], 'data' => [
            ['name' => 'JNE', 'code' => 'jne', 'service' => 'REG', 'description' => 'Reguler', 'cost' => 18000, 'etd' => '2 day'],
            ['name' => 'Rusak', 'code' => 'jne', 'service' => 'X'],
        ]])]);
        [$customer, $addressId] = $this->customerReadyToShip();

        $this->actingAs($customer)
            ->postJson('/api/shipping/rates', ['address_id' => $addressId])
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.service', 'REG');
    }

    public function test_api_key_is_never_returned_to_client(): void
    {
        $this->configureRajaOngkir();
        $this->fakeCosts();
        [$customer, $addressId] = $this->customerReadyToShip();

        $body = $this->actingAs($customer)
            ->postJson('/api/shipping/rates', ['address_id' => $addressId])
            ->getContent();

        $this->assertStringNotContainsString('test-key', $body);
    }

    public function test_destination_search_failure_says_search_failed(): void
    {
        $this->configureRajaOngkir();
        Http::fake([self::BASE.'/*' => Http::response(['meta' => ['code' => 500]], 500)]);

        $this->actingAs(User::factory()->create())
            ->getJson('/api/shipping/destinations?search=braga')
            ->assertStatus(502)
            ->assertJsonPath('message', 'Pencarian wilayah tidak bisa dilakukan saat ini. Coba lagi beberapa saat lagi.');
    }

    public function test_rajaongkir_failure_returns_502(): void
    {
        $this->configureRajaOngkir();
        Http::fake([self::BASE.'/*' => Http::response(['meta' => ['code' => 500]], 500)]);
        [$customer, $addressId] = $this->customerReadyToShip();

        $this->actingAs($customer)
            ->postJson('/api/shipping/rates', ['address_id' => $addressId])
            ->assertStatus(502);
    }

    public function test_rates_need_items_in_cart(): void
    {
        $this->configureRajaOngkir();
        Http::fake();
        $customer = User::factory()->create();
        $addressId = $this->actingAs($customer)->postJson('/api/addresses', [
            'label' => 'Rumah', 'recipient_name' => 'Budi', 'phone' => '081200000003',
            'address_line' => 'Jl. Merdeka 1', 'city' => 'Bandung', 'province' => 'Jawa Barat',
            'postal_code' => '40111', 'destination_id' => 4949,
        ])->json('data.id');

        $this->actingAs($customer)
            ->postJson('/api/shipping/rates', ['address_id' => $addressId])
            ->assertStatus(422)
            ->assertJsonValidationErrors('cart');
    }

    public function test_rates_for_another_customers_address_are_not_found(): void
    {
        $this->configureRajaOngkir();
        $this->fakeCosts();
        [, $addressId] = $this->customerReadyToShip();
        [$other] = $this->customerReadyToShip();

        $this->actingAs($other)
            ->postJson('/api/shipping/rates', ['address_id' => $addressId])
            ->assertNotFound();
    }
}
