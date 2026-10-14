<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Ongkir RajaOngkir: alamat menyimpan ID tujuan RajaOngkir (kecamatan/kelurahan),
 * pengiriman menyimpan layanan kurir yang dipilih saat checkout.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('addresses', function (Blueprint $table) {
            $table->string('subdistrict')->nullable()->after('district');
            $table->unsignedInteger('destination_id')->nullable()->after('postal_code');
        });

        Schema::table('shipments', function (Blueprint $table) {
            $table->string('service')->nullable()->after('courier');
        });
    }

    public function down(): void
    {
        Schema::table('addresses', function (Blueprint $table) {
            $table->dropColumn(['subdistrict', 'destination_id']);
        });

        Schema::table('shipments', function (Blueprint $table) {
            $table->dropColumn('service');
        });
    }
};
