import { ORDER_STATUS_LABEL } from '@/lib/orders'
import type { OrderStatus } from '@/types'

/** Status pesanan sebagai titik + teks; warnanya menandai siapa yang harus bertindak. */
export function OrderStatusBadge({ status }: { status: OrderStatus }) {
  return <span className={`status order-${status}`}>{ORDER_STATUS_LABEL[status]}</span>
}
