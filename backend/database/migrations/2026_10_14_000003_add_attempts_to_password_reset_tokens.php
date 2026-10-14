<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Reset password memakai kode 6 digit; percobaan salah dihitung agar kode
 * hangus setelah beberapa kali salah (cegah tebak-tebakan).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('password_reset_tokens', function (Blueprint $table) {
            $table->unsignedTinyInteger('attempts')->default(0)->after('token');
        });
    }

    public function down(): void
    {
        Schema::table('password_reset_tokens', function (Blueprint $table) {
            $table->dropColumn('attempts');
        });
    }
};
