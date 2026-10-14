<?php

return [

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'resend' => [
        'key' => env('RESEND_KEY'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    // Payment gateway (Fase 4) — isi bila memakai Midtrans.
    'midtrans' => [
        'server_key' => env('MIDTRANS_SERVER_KEY'),
        'client_key' => env('MIDTRANS_CLIENT_KEY'),
        'is_production' => env('MIDTRANS_IS_PRODUCTION', false),
    ],

    // Ongkir RajaOngkir (Komerce) — https://rajaongkir.com/docs
    // Key = API key "Shipping Cost" (hanya di server). Origin toko ada di
    // store_settings.shipping_origin_id; tanpa key/origin → ongkir flat.
    'rajaongkir' => [
        'key' => env('RAJAONGKIR_API_KEY'),
        'base_url' => env('RAJAONGKIR_BASE_URL', 'https://rajaongkir.komerce.id/api/v1/'),
        // Kode kurir yang ditawarkan, dipisah titik dua, mis. jne:jnt:sicepat:pos
        'couriers' => env('RAJAONGKIR_COURIERS', 'jne:jnt:sicepat:pos'),
        'timeout' => (int) env('RAJAONGKIR_TIMEOUT', 10),
    ],

];
