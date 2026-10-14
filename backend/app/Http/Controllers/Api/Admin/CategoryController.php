<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Catalog\CategoryRequest;
use App\Http\Resources\CategoryResource;
use App\Models\Category;
use App\Support\Slug;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class CategoryController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        $categories = Category::query()
            ->withCount('products')
            ->orderBy('name')
            ->get();

        return CategoryResource::collection($categories);
    }

    public function store(CategoryRequest $request): JsonResponse
    {
        $data = $request->validated();
        $data['slug'] = $data['slug'] ?? Slug::unique(Category::class, $data['name']);

        $category = Category::create($data);

        return (new CategoryResource($category))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Category $category): CategoryResource
    {
        return new CategoryResource($category->loadCount('products'));
    }

    public function update(CategoryRequest $request, Category $category): CategoryResource
    {
        $data = $request->validated();
        if (empty($data['slug']) && isset($data['name'])) {
            $data['slug'] = Slug::unique(Category::class, $data['name'], 'slug', $category->id);
        }

        $category->update($data);

        return new CategoryResource($category);
    }

    public function destroy(Category $category): JsonResponse
    {
        if ($category->products()->exists()) {
            return response()->json([
                'message' => 'Kategori tidak bisa dihapus karena masih memiliki produk.',
            ], 422);
        }

        $category->delete();

        return response()->json(['message' => 'Kategori dihapus.']);
    }
}
