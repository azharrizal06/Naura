<?php

namespace App\Services\Shipping;

use App\Models\Address;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\StoreSetting;
use Illuminate\Validation\ValidationException;

/**
 * Pilihan ongkir untuk isi keranjang ke sebuah alamat.
 * Dipakai saat menampilkan pilihan kurir dan saat membuat pesanan
 * (ongkir selalu dihitung ulang di server).
 */
class ShippingRateService
{
    public const FLAT_COURIER = 'toko';

    public const FLAT_SERVICE = 'REG';

    public function __construct(private readonly RajaOngkir $rajaOngkir) {}

    /** @return list<array{courier:string,courier_name:string,service:string,description:string,cost:int,etd:string}> */
    public function ratesFor(Cart $cart, Address $address, ?string $courier = null): array
    {
        $cart->loadMissing('items.variant.product');
        if ($cart->items->isEmpty()) {
            throw ValidationException::withMessages(['cart' => 'Keranjang kosong. Tambahkan barang sebelum memilih kurir.']);
        }

        if (! $this->rajaOngkir->enabled()) {
            return [[
                'courier' => self::FLAT_COURIER,
                'courier_name' => 'Kurir toko',
                'service' => self::FLAT_SERVICE,
                'description' => 'Ongkir flat',
                'cost' => StoreSetting::current()->flat_shipping_cost,
                'etd' => '',
            ]];
        }

        if ($address->destination_id === null) {
            throw ValidationException::withMessages([
                'address_id' => 'Ubah alamat ini dan pilih kecamatan dari pencarian agar ongkir kurir bisa dihitung.',
            ]);
        }

        $rates = $this->rajaOngkir->domesticCost($address->destination_id, $this->weightOf($cart), $courier);
        usort($rates, fn (array $a, array $b) => $a['cost'] <=> $b['cost']);

        return $rates;
    }

    /**
     * Cari satu layanan dari pilihan yang dihitung server; null bila tidak tersedia.
     * Memakai daftar lengkap (sama dengan yang ditampilkan saat checkout) agar
     * hasilnya diambil dari cache, bukan panggilan API baru.
     */
    public function find(Cart $cart, Address $address, string $courier, string $service): ?array
    {
        foreach ($this->ratesFor($cart, $address) as $rate) {
            if ($rate['courier'] === $courier && $rate['service'] === $service) {
                return $rate;
            }
        }

        return null;
    }

    /** Berat total (gram) dari berat produk × jumlah; minimal 1 gram. */
    public function weightOf(Cart $cart): int
    {
        $grams = $cart->items->sum(
            fn (CartItem $item) => $item->variant->product->weight_grams * $item->quantity
        );

        return max(1, (int) $grams);
    }
}
