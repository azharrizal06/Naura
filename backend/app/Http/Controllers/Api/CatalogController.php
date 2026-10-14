<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CategoryResource;
use App\Http\Resources\ProductListResource;
use App\Http\Resources\ProductResource;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/**
 * Katalog publik (dipakai mobile app & halaman toko).
 * Hanya menampilkan produk/kategori aktif.
 */
class CatalogController extends Controller
{
    public function products(Request $request): AnonymousResourceCollection
    {
        $products = Product::query()
            ->active()
            ->with(['category', 'primaryImage'])
            ->search($request->query('q'))
            ->when($request->filled('category'), function ($query) use ($request) {
                $category = $request->query('category');
                $query->whereHas('category', function ($q) use ($category) {
                    is_numeric($category)
                        ? $q->where('id', $category)
                        : $q->where('slug', $category);
                });
            })
            ->when($request->query('sort') === 'price_asc', fn ($q) => $q->orderBy('base_price'))
            ->when($request->query('sort') === 'price_desc', fn ($q) => $q->orderByDesc('base_price'))
            ->when(! $request->filled('sort'), fn ($q) => $q->latest())
            ->paginate($request->integer('per_page', 12))
            ->withQueryString();

        return ProductListResource::collection($products);
    }

    public function product(string $slug): ProductResource
    {
        $product = Product::query()
            ->active()
            ->where('slug', $slug)
            ->with([
                'category',
                'images' => fn ($q) => $q->orderByDesc('is_primary')->orderBy('sort_order'),
                'variants' => fn ($q) => $q->where('is_active', true),
            ])
            ->firstOrFail();

        return new ProductResource($product);
    }

    public function categories(): AnonymousResourceCollection
    {
        $categories = Category::query()
            ->where('is_active', true)
            ->withCount(['products' => fn ($q) => $q->where('is_active', true)])
            ->orderBy('name')
            ->get();

        return CategoryResource::collection($categories);
    }
}
