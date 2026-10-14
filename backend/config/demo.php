<?php

return [
    // DEMO_MODE=true untuk demo publik: akun demo tidak bisa dikunci pengunjung
    // (ganti password/email, reset password, nonaktifkan) dan klien menampilkan akunnya.
    'enabled' => (bool) env('DEMO_MODE', false),

    // Akun yang dilindungi — sama dengan akun di DatabaseSeeder & DemoSeeder.
    'accounts' => ['owner@naura.test', 'admin@naura.test', 'customer@naura.test'],
];
