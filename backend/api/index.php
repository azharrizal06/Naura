<?php

// Vercel (runtime vercel-php): semua permintaan non-statis masuk ke Laravel. Lihat vercel.json.
// SCRIPT_NAME asli `/api/index.php` membuat Laravel menganggap `/api` base path dan memotongnya dari rute.
$_SERVER['SCRIPT_NAME'] = $_SERVER['PHP_SELF'] = '/index.php';
$_SERVER['SCRIPT_FILENAME'] = __DIR__.'/../public/index.php';

require __DIR__.'/../public/index.php';
