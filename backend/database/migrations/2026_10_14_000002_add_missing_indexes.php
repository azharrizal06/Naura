<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * PostgreSQL tidak mengindeks foreign key secara otomatis — tanpa ini setiap
 * eager-load pesanan/varian dan laporan omzet memindai seluruh tabel.
 * payments & shipments satu-satu dengan orders, jadi order_id dibuat unik.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('order_items', fn (Blueprint $t) => $t->index('order_id'));
        Schema::table('payments', function (Blueprint $t) {
            $t->unique('order_id');
            $t->index('paid_at');
        });
        Schema::table('shipments', fn (Blueprint $t) => $t->unique('order_id'));
        Schema::table('product_variants', fn (Blueprint $t) => $t->index('product_id'));
        Schema::table('product_images', fn (Blueprint $t) => $t->index('product_id'));
        Schema::table('addresses', fn (Blueprint $t) => $t->index('user_id'));
        Schema::table('products', fn (Blueprint $t) => $t->index('category_id'));
        Schema::table('orders', fn (Blueprint $t) => $t->index('created_at'));
    }

    public function down(): void
    {
        Schema::table('order_items', fn (Blueprint $t) => $t->dropIndex(['order_id']));
        Schema::table('payments', function (Blueprint $t) {
            $t->dropUnique(['order_id']);
            $t->dropIndex(['paid_at']);
        });
        Schema::table('shipments', fn (Blueprint $t) => $t->dropUnique(['order_id']));
        Schema::table('product_variants', fn (Blueprint $t) => $t->dropIndex(['product_id']));
        Schema::table('product_images', fn (Blueprint $t) => $t->dropIndex(['product_id']));
        Schema::table('addresses', fn (Blueprint $t) => $t->dropIndex(['user_id']));
        Schema::table('products', fn (Blueprint $t) => $t->dropIndex(['category_id']));
        Schema::table('orders', fn (Blueprint $t) => $t->dropIndex(['created_at']));
    }
};
