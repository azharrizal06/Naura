<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProductImageResource;
use App\Models\Product;
use App\Models\ProductImage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProductImageController extends Controller
{
    public function store(Request $request, Product $product): JsonResponse
    {
        $request->validate([
            'image' => ['required', 'image', 'max:4096'], // maks 4MB
            'is_primary' => ['sometimes', 'boolean'],
        ]);

        $path = $request->file('image')->store('products', 'public');

        $isPrimary = $request->boolean('is_primary') || $product->images()->count() === 0;

        if ($isPrimary) {
            $product->images()->update(['is_primary' => false]);
        }

        $image = $product->images()->create([
            'path' => $path,
            'is_primary' => $isPrimary,
            'sort_order' => $product->images()->max('sort_order') + 1,
        ]);

        return (new ProductImageResource($image))
            ->response()
            ->setStatusCode(201);
    }

    public function setPrimary(Product $product, ProductImage $image): ProductImageResource
    {
        abort_unless($image->product_id === $product->id, 404);

        $product->images()->update(['is_primary' => false]);
        $image->update(['is_primary' => true]);

        return new ProductImageResource($image);
    }

    public function destroy(Product $product, ProductImage $image): JsonResponse
    {
        abort_unless($image->product_id === $product->id, 404);

        Storage::disk('public')->delete($image->path);
        $image->delete();

        return response()->json(['message' => 'Foto dihapus.']);
    }
}
