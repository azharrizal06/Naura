import { api } from '@/lib/api'
import type { OwnerSettings, SalesReport, User } from '@/types'

// --- Laporan ---

export async function fetchSalesReport(from: string, to: string): Promise<SalesReport> {
  const res = await api.get<{ data: SalesReport }>('/owner/reports/sales', { params: { from, to } })
  return res.data.data
}

// --- Kelola admin ---

export interface AdminPayload {
  name?: string
  email?: string
  phone?: string | null
  password?: string
  is_active?: boolean
}

export async function fetchAdmins(): Promise<User[]> {
  const res = await api.get<{ data: User[] }>('/owner/admins')
  return res.data.data
}

export async function createAdmin(payload: AdminPayload): Promise<User> {
  const res = await api.post<{ data: User }>('/owner/admins', payload)
  return res.data.data
}

export async function updateAdmin(id: number, payload: AdminPayload): Promise<User> {
  const res = await api.patch<{ data: User }>(`/owner/admins/${id}`, payload)
  return res.data.data
}

// --- Pengaturan toko ---

export type SettingsPayload = Pick<
  OwnerSettings,
  'store_name' | 'store_email' | 'store_phone' | 'store_address' | 'flat_shipping_cost' | 'bank_accounts'
>

export async function fetchSettings(): Promise<OwnerSettings> {
  const res = await api.get<{ data: OwnerSettings }>('/owner/settings')
  return res.data.data
}

export async function updateSettings(payload: SettingsPayload): Promise<OwnerSettings> {
  const res = await api.patch<{ data: OwnerSettings }>('/owner/settings', payload)
  return res.data.data
}
