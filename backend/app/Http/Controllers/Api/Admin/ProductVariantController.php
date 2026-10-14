<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Catalog\ProductVariantRequest;
use App\Http\Requests\Catalog\StockAdjustmentRequest;
use App\Http\Resources\ProductVariantResource;
use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ProductVariantController extends Controller
{
    public function index(Product $product): AnonymousResourceCollection
    {
        return ProductVariantResource::collection($product->variants()->get());
    }

    public function store(ProductVariantRequest $request, Product $product): JsonResponse
    {
        $variant = $product->variants()->create($request->validated());

        return (new ProductVariantResource($variant))
            ->response()
            ->setStatusCode(201);
    }

    public function update(ProductVariantRequest $request, Product $product, ProductVariant $variant): ProductVariantResource
    {
        $this->assertBelongs($product, $variant);
        $variant->update($request->validated());

        return new ProductVariantResource($variant);
    }

    public function destroy(Product $product, ProductVariant $variant): JsonResponse
    {
        $this->assertBelongs($product, $variant);
        $variant->delete();

        return response()->json(['message' => 'Varian dihapus.']);
    }

    /** Tetapkan atau sesuaikan stok varian. */
    public function adjustStock(StockAdjustmentRequest $request, Product $product, ProductVariant $variant): ProductVariantResource
    {
        $this->assertBelongs($product, $variant);

        $value = $request->integer('value');
        $newStock = $request->input('mode') === 'set'
            ? $value
            : $variant->stock + $value;

        $variant->update(['stock' => max(0, $newStock)]);

        return new ProductVariantResource($variant);
    }

    private function assertBelongs(Product $product, ProductVariant $variant): void
    {
        abort_unless($variant->product_id === $product->id, 404, 'Varian tidak ditemukan pada produk ini.');
    }
}
