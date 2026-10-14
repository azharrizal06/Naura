<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Lokasi asal pengiriman toko = ID tujuan RajaOngkir hasil pencarian
 * (diisi lewat `php artisan store:shipping-origin`).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('store_settings', function (Blueprint $table) {
            $table->unsignedInteger('shipping_origin_id')->nullable()->after('flat_shipping_cost');
            $table->string('shipping_origin_label')->nullable()->after('shipping_origin_id');
        });
    }

    public function down(): void
    {
        Schema::table('store_settings', function (Blueprint $table) {
            $table->dropColumn(['shipping_origin_id', 'shipping_origin_label']);
        });
    }
};
