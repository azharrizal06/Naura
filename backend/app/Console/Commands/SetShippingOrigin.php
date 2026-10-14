<?php

namespace App\Console\Commands;

use App\Models\StoreSetting;
use App\Services\Shipping\RajaOngkir;
use App\Services\Shipping\ShippingException;
use Illuminate\Console\Command;

/**
 * Atur lokasi asal pengiriman toko dari hasil pencarian RajaOngkir.
 * ID hanya diterima bila muncul di hasil pencarian — tidak bisa dikarang.
 *
 *   php artisan store:shipping-origin "sumur bandung"          # pilih dari daftar
 *   php artisan store:shipping-origin "braga" --id=4949        # tanpa interaksi
 */
class SetShippingOrigin extends Command
{
    protected $signature = 'store:shipping-origin
        {search : Nama kecamatan/kelurahan lokasi toko (min. 3 huruf)}
        {--id= : ID dari hasil pencarian, untuk menjalankan tanpa interaksi}';

    protected $description = 'Atur lokasi asal pengiriman toko (RajaOngkir) di store_settings';

    public function handle(RajaOngkir $rajaOngkir): int
    {
        try {
            $results = $rajaOngkir->searchDestinations((string) $this->argument('search'));
        } catch (ShippingException $e) {
            $this->error($e->getMessage());

            return self::FAILURE;
        }

        if ($results === []) {
            $this->error('Tidak ada hasil. Coba nama kecamatan atau kelurahan lain.');

            return self::FAILURE;
        }

        $byId = collect($results)->keyBy('id');

        if ($this->option('id') !== null) {
            $chosen = $byId->get((int) $this->option('id'));
            if ($chosen === null) {
                $this->error('ID '.$this->option('id').' tidak ada di hasil pencarian "'.$this->argument('search').'".');
                $this->table(['ID', 'Wilayah'], $byId->map(fn ($r) => [$r['id'], $r['label']])->values());

                return self::FAILURE;
            }
        } else {
            $labels = $byId->map(fn ($r) => "{$r['label']} (ID {$r['id']})")->all();
            $picked = $this->choice('Pilih lokasi toko', array_values($labels));
            $chosen = $byId->first(fn ($r) => "{$r['label']} (ID {$r['id']})" === $picked);
        }

        StoreSetting::current()->update([
            'shipping_origin_id' => $chosen['id'],
            'shipping_origin_label' => $chosen['label'],
        ]);

        $this->info("Lokasi asal pengiriman: {$chosen['label']} (ID {$chosen['id']}).");

        return self::SUCCESS;
    }
}
