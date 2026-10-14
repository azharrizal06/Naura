<?php

use App\Http\Controllers\Api\AddressController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CartController;
use App\Http\Controllers\Api\CatalogController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\PasswordResetController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\ShippingController;
use App\Http\Controllers\Api\StoreSettingController;
use App\Http\Controllers\Api\Admin\CategoryController;
use App\Http\Controllers\Api\Admin\OrderController as AdminOrderController;
use App\Http\Controllers\Api\Admin\ProductController;
use App\Http\Controllers\Api\Admin\ProductImageController;
use App\Http\Controllers\Api\Admin\ProductVariantController;
use App\Http\Controllers\Api\Admin\SummaryController;
use App\Http\Controllers\Api\Owner\AdminController;
use App\Http\Controllers\Api\Owner\ReportController;
use App\Http\Controllers\Api\Owner\SettingsController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes — Toko Online Terpadu
|--------------------------------------------------------------------------
| Prefix otomatis: /api
| Auth: Laravel Sanctum (Bearer token untuk mobile & dashboard)
*/

// --- Publik: autentikasi -------------------------------------------------
Route::post('/auth/register', [AuthController::class, 'register'])->middleware('throttle:auth');
Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:auth');
Route::post('/auth/forgot-password', [PasswordResetController::class, 'forgot'])->middleware('throttle:auth');
Route::post('/auth/reset-password', [PasswordResetController::class, 'reset'])->middleware('throttle:auth');

// --- Publik: katalog (Fase 2) --------------------------------------------
Route::prefix('catalog')->group(function () {
    Route::get('/products', [CatalogController::class, 'products']);
    Route::get('/products/{slug}', [CatalogController::class, 'product']);
    Route::get('/categories', [CatalogController::class, 'categories']);
});

// --- Publik: info toko & rekening transfer (Fase 3) ----------------------
Route::get('/store', [StoreSettingController::class, 'show']);

// --- Terautentikasi (semua role) ------------------------------------------
Route::middleware(['auth:sanctum', 'active'])->group(function () {
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::post('/auth/logout-all', [AuthController::class, 'logoutAll']);
    Route::patch('/auth/profile', [ProfileController::class, 'update']);
    Route::put('/auth/password', [ProfileController::class, 'changePassword']);

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
    Route::middleware(['role:customer', 'throttle:shipping'])->prefix('shipping')->group(function () {
        Route::get('/destinations', [ShippingController::class, 'destinations']);
        Route::post('/rates', [ShippingController::class, 'rates']);
    });

    // --- Pesanan: Customer (Fase 4) ---------------------------------------
    Route::middleware('role:customer')->prefix('orders')->group(function () {
        Route::get('/', [OrderController::class, 'index']);
        Route::post('/', [OrderController::class, 'store']);
        Route::get('/{order}', [OrderController::class, 'show']);
        Route::post('/{order}/cancel', [OrderController::class, 'cancel']);
        Route::post('/{order}/complete', [OrderController::class, 'complete']);
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

        // Ringkasan beranda & pesanan (Fase 5)
        Route::get('summary', SummaryController::class);
        Route::get('orders', [AdminOrderController::class, 'index']);
        Route::get('orders/{order}', [AdminOrderController::class, 'show']);
        Route::post('orders/{order}/confirm-payment', [AdminOrderController::class, 'confirmPayment']);
        Route::post('orders/{order}/process', [AdminOrderController::class, 'process']);
        Route::post('orders/{order}/ship', [AdminOrderController::class, 'ship']);
        Route::post('orders/{order}/complete', [AdminOrderController::class, 'complete']);
        Route::post('orders/{order}/cancel', [AdminOrderController::class, 'cancel']);
    });

    // --- Khusus Owner ------------------------------------------------------
    Route::middleware('role:owner')->prefix('owner')->group(function () {
        Route::get('/ping', fn (Request $r) => response()->json([
            'message' => 'Halo Owner',
        ]));

        // Laporan, kelola admin, pengaturan toko (Fase 6)
        Route::get('/reports/sales', [ReportController::class, 'sales']);
        Route::get('/admins', [AdminController::class, 'index']);
        Route::post('/admins', [AdminController::class, 'store']);
        Route::patch('/admins/{admin}', [AdminController::class, 'update']);
        Route::get('/settings', [SettingsController::class, 'show']);
        Route::patch('/settings', [SettingsController::class, 'update']);
    });
});
