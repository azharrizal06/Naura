import { api } from '@/lib/api'
import type { Category, Paginated, Product, ProductListItem, ProductVariant } from '@/types'

// --- Produk ---

export interface ProductFilters {
  q?: string
  category_id?: number
  status?: 'active' | 'inactive'
  page?: number
  per_page?: number
}

export async function fetchProducts(filters: ProductFilters = {}): Promise<Paginated<ProductListItem>> {
  const res = await api.get<Paginated<ProductListItem>>('/dashboard/products', { params: filters })
  return res.data
}

export async function fetchProduct(id: number): Promise<Product> {
  const res = await api.get<{ data: Product }>(`/dashboard/products/${id}`)
  return res.data.data
}

export interface ProductPayload {
  category_id: number
  name: string
  description?: string | null
  base_price: number
  weight_grams?: number
  is_active?: boolean
}

export async function createProduct(payload: ProductPayload): Promise<Product> {
  const res = await api.post<{ data: Product }>('/dashboard/products', payload)
  return res.data.data
}

export async function updateProduct(id: number, payload: Partial<ProductPayload>): Promise<Product> {
  const res = await api.patch<{ data: Product }>(`/dashboard/products/${id}`, payload)
  return res.data.data
}

export async function deleteProduct(id: number): Promise<void> {
  await api.delete(`/dashboard/products/${id}`)
}

// --- Varian & stok ---

export interface VariantPayload {
  sku: string
  name: string
  price: number
  stock?: number
  attributes?: Record<string, unknown> | null
  is_active?: boolean
}

export async function createVariant(productId: number, payload: VariantPayload): Promise<ProductVariant> {
  const res = await api.post<{ data: ProductVariant }>(`/dashboard/products/${productId}/variants`, payload)
  return res.data.data
}

export async function updateVariant(
  productId: number,
  variantId: number,
  payload: Partial<VariantPayload>,
): Promise<ProductVariant> {
  const res = await api.patch<{ data: ProductVariant }>(
    `/dashboard/products/${productId}/variants/${variantId}`,
    payload,
  )
  return res.data.data
}

export async function deleteVariant(productId: number, variantId: number): Promise<void> {
  await api.delete(`/dashboard/products/${productId}/variants/${variantId}`)
}

export async function adjustStock(
  productId: number,
  variantId: number,
  mode: 'set' | 'adjust',
  value: number,
): Promise<ProductVariant> {
  const res = await api.patch<{ data: ProductVariant }>(
    `/dashboard/products/${productId}/variants/${variantId}/stock`,
    { mode, value },
  )
  return res.data.data
}

// --- Kategori ---

export async function fetchCategories(): Promise<Category[]> {
  const res = await api.get<{ data: Category[] }>('/dashboard/categories')
  return res.data.data
}

export interface CategoryPayload {
  name: string
  parent_id?: number | null
  description?: string | null
  is_active?: boolean
}

export async function createCategory(payload: CategoryPayload): Promise<Category> {
  const res = await api.post<{ data: Category }>('/dashboard/categories', payload)
  return res.data.data
}

export async function updateCategory(id: number, payload: Partial<CategoryPayload>): Promise<Category> {
  const res = await api.patch<{ data: Category }>(`/dashboard/categories/${id}`, payload)
  return res.data.data
}

export async function deleteCategory(id: number): Promise<void> {
  await api.delete(`/dashboard/categories/${id}`)
}
