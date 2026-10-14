<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('store_settings', function (Blueprint $table) {
            $table->id();
            $table->string('store_name')->default('Toko Online Terpadu');
            $table->string('store_email')->nullable();
            $table->string('store_phone')->nullable();
            $table->text('store_address')->nullable();
            $table->string('currency', 8)->default('IDR');
            $table->integer('flat_shipping_cost')->default(0);
            $table->jsonb('bank_accounts')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('store_settings');
    }
};
