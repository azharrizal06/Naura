<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('orders')->cascadeOnDelete();
            // manual_transfer | midtrans | cod | ...
            $table->string('method')->default('manual_transfer');
            // pending | paid | failed | expired | refunded
            $table->string('status')->default('pending')->index();
            $table->integer('amount');
            $table->string('reference')->nullable();
            $table->string('proof_path')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->jsonb('meta')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
