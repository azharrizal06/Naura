<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Catalog\ProductRequest;
use App\Http\Resources\ProductListResource;
use App\Http\Resources\ProductResource;
use App\Models\Product;
use App\Support\Slug;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/**
 * Manajemen produk (Admin & Owner). Menampilkan semua produk termasuk nonaktif.
 */
class ProductController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $products = Product::query()
            ->with(['category', 'primaryImage'])
            ->withCount('variants')
            ->with('variants:id,product_id,stock')
            ->search($request->query('q'))
            ->when($request->filled('category_id'), fn ($q) => $q->where('category_id', $request->integer('category_id')))
            ->when($request->filled('status'), function ($q) use ($request) {
                $q->where('is_active', $request->query('status') === 'active');
            })
            ->latest()
            ->paginate($this->perPage($request, 15))
            ->withQueryString();

        return ProductListResource::collection($products);
    }

    public function store(ProductRequest $request): JsonResponse
    {
        $data = $request->validated();
        $data['slug'] = $data['slug'] ?? Slug::unique(Product::class, $data['name']);

        $product = Product::create($data);

        return (new ProductResource($product->load(['category', 'images', 'variants'])))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Product $product): ProductResource
    {
        return new ProductResource(
            $product->load(['category', 'images', 'variants'])
        );
    }

    public function update(ProductRequest $request, Product $product): ProductResource
    {
        $data = $request->validated();
        if (empty($data['slug']) && isset($data['name'])) {
            $data['slug'] = Slug::unique(Product::class, $data['name'], 'slug', $product->id);
        }

        $product->update($data);

        return new ProductResource($product->load(['category', 'images', 'variants']));
    }

    public function destroy(Product $product): JsonResponse
    {
        $product->delete();

        return response()->json(['message' => 'Produk dihapus.']);
    }
}
