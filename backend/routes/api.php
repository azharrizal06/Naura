<?php

use App\Http\Controllers\Api\AddressController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CartController;
use App\Http\Controllers\Api\CatalogController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\ShippingController;
use App\Http\Controllers\Api\Admin\CategoryController;
use App\Http\Controllers\Api\Admin\ProductController;
use App\Http\Controllers\Api\Admin\ProductImageController;
use App\Http\Controllers\Api\Admin\ProductVariantController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes — Toko Online Terpadu
|--------------------------------------------------------------------------
| Prefix otomatis: /api
| Auth: Laravel Sanctum (Bearer token untuk mobile, cookie untuk dashboard)
*/

// --- Publik: autentikasi -------------------------------------------------
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);

// --- Publik: katalog (Fase 2) --------------------------------------------
Route::prefix('catalog')->group(function () {
    Route::get('/products', [CatalogController::class, 'products']);
    Route::get('/products/{slug}', [CatalogController::class, 'product']);
    Route::get('/categories', [CatalogController::class, 'categories']);
});

// --- Terautentikasi (semua role) ------------------------------------------
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::post('/auth/logout-all', [AuthController::class, 'logoutAll']);

    Route::get('/ping/customer', fn (Request $r) => response()->json([
        'message' => 'Halo Customer', 'user' => $r->user()->name,
    ]))->middleware('role:customer');

    // --- Keranjang: Customer (Fase 3) -------------------------------------
    Route::middleware('role:customer')->prefix('cart')->group(function () {
        Route::get('/', [CartController::class, 'show']);
        Route::post('/items', [CartController::class, 'addItem']);
        Route::patch('/items/{item}', [CartController::class, 'updateItem']);
        Route::delete('/items/{item}', [CartController::class, 'removeItem']);
    });

    // --- Alamat pengiriman: Customer (Fase 3) -----------------------------
    Route::middleware('role:customer')->prefix('addresses')->group(function () {
        Route::get('/', [AddressController::class, 'index']);
        Route::post('/', [AddressController::class, 'store']);
        Route::patch('/{address}', [AddressController::class, 'update']);
        Route::delete('/{address}', [AddressController::class, 'destroy']);
    });

    // --- Ongkir: Customer (Fase 3) ----------------------------------------
    Route::middleware('role:customer')->prefix('shipping')->group(function () {
        Route::get('/destinations', [ShippingController::class, 'destinations']);
        Route::post('/rates', [ShippingController::class, 'rates']);
    });

    // --- Pesanan: Customer (Fase 4) ---------------------------------------
    Route::middleware('role:customer')->prefix('orders')->group(function () {
        Route::get('/', [OrderController::class, 'index']);
        Route::post('/', [OrderController::class, 'store']);
        Route::get('/{order}', [OrderController::class, 'show']);
    });

    // --- Dashboard: Admin & Owner -----------------------------------------
    Route::middleware('role:admin,owner')->prefix('dashboard')->group(function () {
        Route::get('/ping', fn (Request $r) => response()->json([
            'message' => 'Halo '.$r->user()->role->label(),
        ]));

        // Kategori
        Route::apiResource('categories', CategoryController::class);

        // Produk
        Route::apiResource('products', ProductController::class);

        // Varian produk (nested)
        Route::get('products/{product}/variants', [ProductVariantController::class, 'index']);
        Route::post('products/{product}/variants', [ProductVariantController::class, 'store']);
        Route::match(['put', 'patch'], 'products/{product}/variants/{variant}', [ProductVariantController::class, 'update']);
        Route::delete('products/{product}/variants/{variant}', [ProductVariantController::class, 'destroy']);
        Route::patch('products/{product}/variants/{variant}/stock', [ProductVariantController::class, 'adjustStock']);

        // Foto produk
        Route::post('products/{product}/images', [ProductImageController::class, 'store']);
        Route::patch('products/{product}/images/{image}/primary', [ProductImageController::class, 'setPrimary']);
        Route::delete('products/{product}/images/{image}', [ProductImageController::class, 'destroy']);
    });

    // --- Khusus Owner ------------------------------------------------------
    Route::middleware('role:owner')->prefix('owner')->group(function () {
        Route::get('/ping', fn (Request $r) => response()->json([
            'message' => 'Halo Owner',
        ]));
        // Fase 6: laporan, omzet, kelola admin, pengaturan toko ...
    });
});
