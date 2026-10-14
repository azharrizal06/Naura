<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Cart\AddCartItemRequest;
use App\Http\Requests\Cart\UpdateCartItemRequest;
use App\Http\Resources\CartResource;
use App\Models\Cart;
use App\Models\ProductVariant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

/**
 * Keranjang milik customer yang sedang login (Fase 3).
 */
class CartController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return $this->cartResponse($this->cartOf($request));
    }

    public function addItem(AddCartItemRequest $request): JsonResponse
    {
        $cart = $this->cartOf($request);
        $variant = ProductVariant::with('product')->findOrFail($request->integer('variant_id'));
        if (! $variant->is_active || ! $variant->product->is_active) {
            throw ValidationException::withMessages([
                'variant_id' => 'Pilihan ini sedang tidak dijual.',
            ]);
        }

        $item = $cart->items()->firstOrNew(['product_variant_id' => $variant->id]);
        $item->quantity = ($item->exists ? $item->quantity : 0) + $request->integer('quantity', 1);
        $this->ensureStock($variant, $item->quantity);
        $item->unit_price = $variant->price;
        $item->save();

        return $this->cartResponse($cart, 201);
    }

    public function updateItem(UpdateCartItemRequest $request, int $item): JsonResponse
    {
        $cart = $this->cartOf($request);
        $cartItem = $cart->items()->with('variant')->findOrFail($item);
        $this->ensureStock($cartItem->variant, $request->integer('quantity'));
        $cartItem->update(['quantity' => $request->integer('quantity')]);

        return $this->cartResponse($cart);
    }

    public function removeItem(Request $request, int $item): JsonResponse
    {
        $cart = $this->cartOf($request);
        $cart->items()->findOrFail($item)->delete();

        return $this->cartResponse($cart);
    }

    /** Tolak bila jumlah di keranjang melebihi stok varian. */
    private function ensureStock(ProductVariant $variant, int $quantity): void
    {
        if (! $variant->inStock($quantity)) {
            throw ValidationException::withMessages([
                'quantity' => "Stok {$variant->name} tinggal {$variant->stock}.",
            ]);
        }
    }

    private function cartOf(Request $request): Cart
    {
        return Cart::firstOrCreate(['user_id' => $request->user()->id]);
    }

    private function cartResponse(Cart $cart, int $status = 200): JsonResponse
    {
        $cart->load('items.variant.product.primaryImage');

        // Status ditetapkan eksplisit: Resource otomatis memberi 201 untuk
        // model yang baru dibuat (keranjang pertama via firstOrCreate).
        return (new CartResource($cart))->response()->setStatusCode($status);
    }
}
