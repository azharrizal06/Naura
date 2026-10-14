import { api } from '@/lib/api'
import type { DashboardSummary, Order, OrderStatus, Paginated } from '@/types'

export const ORDER_STATUS_LABEL: Record<OrderStatus, string> = {
  pending: 'Menunggu bayar',
  paid: 'Dibayar',
  processing: 'Diproses',
  shipped: 'Dikirim',
  completed: 'Selesai',
  cancelled: 'Dibatalkan',
}

export interface OrderFilters {
  q?: string
  status?: OrderStatus
  page?: number
  per_page?: number
}

export async function fetchOrders(filters: OrderFilters = {}): Promise<Paginated<Order>> {
  const res = await api.get<Paginated<Order>>('/dashboard/orders', { params: filters })
  return res.data
}

export async function fetchOrder(id: number): Promise<Order> {
  const res = await api.get<{ data: Order }>(`/dashboard/orders/${id}`)
  return res.data.data
}

async function action(id: number, name: string, body?: object): Promise<Order> {
  const res = await api.post<{ data: Order }>(`/dashboard/orders/${id}/${name}`, body)
  return res.data.data
}

export const confirmPayment = (id: number) => action(id, 'confirm-payment')
export const processOrder = (id: number) => action(id, 'process')
export const shipOrder = (id: number, tracking_number: string, courier?: string) =>
  action(id, 'ship', { tracking_number, courier: courier || undefined })
export const completeOrder = (id: number) => action(id, 'complete')
export const cancelOrder = (id: number) => action(id, 'cancel')

export async function fetchSummary(): Promise<DashboardSummary> {
  const res = await api.get<{ data: DashboardSummary }>('/dashboard/summary')
  return res.data.data
}
