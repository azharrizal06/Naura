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

// --- Pesanan (Fase 5) ---

export type OrderStatus = 'pending' | 'paid' | 'processing' | 'shipped' | 'completed' | 'cancelled'

export interface BankAccount {
  bank: string
  number: string
  holder: string
}

export interface OrderItem {
  id: number
  product_name: string
  variant_name: string
  unit_price: number
  quantity: number
  subtotal: number
  product: { id: number; slug: string; primary_image: string | null } | null
}

export interface Order {
  id: number
  order_number: string
  status: OrderStatus
  created_at: string
  subtotal: number
  shipping_cost: number
  discount: number
  total: number
  notes: string | null
  shipping_address: {
    recipient_name?: string
    phone?: string
    address_line?: string
    subdistrict?: string | null
    district?: string | null
    city?: string
    province?: string
    postal_code?: string
  }
  items: OrderItem[]
  payment: {
    method: string
    status: string
    amount: number
    bank: BankAccount | null
    paid_at: string | null
  } | null
  shipment: {
    courier: string | null
    service: string | null
    tracking_number: string | null
    status: string
    shipped_at: string | null
    delivered_at: string | null
  } | null
  customer: { id: number; name: string; email: string; phone: string | null } | null
}

export interface DashboardSummary {
  orders_today: number
  awaiting_payment: number
  to_process: number
  to_ship: number
  /** Hanya untuk owner. */
  revenue_this_month?: number
}

// --- Owner (Fase 6) ---

export interface SalesReport {
  from: string
  to: string
  revenue: number
  goods: number
  shipping: number
  orders: number
  average_order: number
  cancelled: number
  daily: { date: string; revenue: number; orders: number }[]
  top_products: { product_name: string; quantity: number; revenue: number }[]
}

export interface OwnerSettings {
  store_name: string
  store_email: string | null
  store_phone: string | null
  store_address: string | null
  currency: string
  flat_shipping_cost: number
  shipping_origin_id: number | null
  shipping_origin_label: string | null
  bank_accounts: BankAccount[]
}
