export type UserRole = 'customer' | 'admin' | 'owner'

export interface User {
  id: number
  name: string
  email: string
  phone: string | null
  role: UserRole
  role_label: string
  is_active: boolean
  email_verified_at: string | null
  created_at: string
}

export interface LoginResponse {
  message: string
  user: User
  token: string
}

export interface ApiError {
  message: string
  errors?: Record<string, string[]>
}

// --- Katalog (Fase 2) ---

export interface Category {
  id: number
  parent_id: number | null
  name: string
  slug: string
  description: string | null
  is_active: boolean
  products_count?: number
}

export interface ProductVariant {
  id: number
  product_id: number
  sku: string
  name: string
  price: number
  stock: number
  in_stock: boolean
  attributes: Record<string, unknown> | null
  is_active: boolean
}

export interface ProductImage {
  id: number
  url: string | null
  is_primary: boolean
  sort_order: number
}

export interface ProductListItem {
  id: number
  name: string
  slug: string
  base_price: number
  is_active: boolean
  category?: { id: number; name: string; slug: string }
  primary_image?: string | null
  total_stock?: number
}

export interface Product {
  id: number
  category_id: number
  name: string
  slug: string
  description: string | null
  base_price: number
  weight_grams: number
  is_active: boolean
  category?: Category
  images?: ProductImage[]
  variants?: ProductVariant[]
  total_stock?: number
}

export interface Paginated<T> {
  data: T[]
  links: { first: string | null; last: string | null; prev: string | null; next: string | null }
  meta: {
    current_page: number
    last_page: number
    per_page: number
    total: number
    from: number | null
    to: number | null
  }
}
