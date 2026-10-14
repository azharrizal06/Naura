import { useEffect, useState, type FormEvent } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { Spinner } from '@/components/Spinner'
import { OrderStatusBadge } from '@/components/OrderStatusBadge'
import { formatDateTime, formatRupiah } from '@/lib/format'
import { fetchOrders, ORDER_STATUS_LABEL } from '@/lib/orders'
import type { Order, OrderStatus, Paginated } from '@/types'

const TABS: (OrderStatus | '')[] = ['', 'pending', 'paid', 'processing', 'shipped', 'completed', 'cancelled']

export function OrdersPage() {
  // Status di URL agar kartu beranda bisa menautkan langsung, mis. /orders?status=paid.
  const [params, setParams] = useSearchParams()
  const status = (params.get('status') ?? '') as OrderStatus | ''
  const [page, setPage] = useState<Paginated<Order> | null>(null)
  const [q, setQ] = useState('')
  const [currentPage, setCurrentPage] = useState(1)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  async function load(pageNo = currentPage) {
    setLoading(true)
    setError(null)
    try {
      setPage(await fetchOrders({ q: q || undefined, status: status || undefined, page: pageNo }))
    } catch {
      setError('Pesanan tidak bisa dimuat. Periksa koneksi ke server lalu muat ulang halaman.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentPage, status])

  function selectTab(next: OrderStatus | '') {
    setCurrentPage(1)
    setParams(next ? { status: next } : {})
  }

  function handleSearch(e: FormEvent) {
    e.preventDefault()
    setCurrentPage(1)
    void load(1)
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h2>Pesanan</h2>
          {page && (
            <p className="muted">
              {page.meta.total} pesanan{status ? ` ${ORDER_STATUS_LABEL[status].toLowerCase()}` : ''}
            </p>
          )}
        </div>
      </div>

      <div className="tabs" role="group" aria-label="Saring status">
        {TABS.map((t) => (
          <button key={t || 'all'} type="button" aria-pressed={status === t} onClick={() => selectTab(t)}>
            {t ? ORDER_STATUS_LABEL[t] : 'Semua'}
          </button>
        ))}
      </div>

      <form className="toolbar" onSubmit={handleSearch}>
        <input
          type="search"
          aria-label="Cari pesanan"
          placeholder="Nomor pesanan atau nama customer"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
        <button type="submit" className="ghost">
          Cari
        </button>
      </form>

      {error && <div className="alert">{error}</div>}

      {loading ? (
        <Spinner />
      ) : (
        page && (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Pesanan</th>
                  <th>Customer</th>
                  <th>Waktu</th>
                  <th className="num">Barang</th>
                  <th className="num">Total</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {page.data.map((o) => (
                  <tr key={o.id}>
                    <td>
                      <Link className="order-number" to={`/orders/${o.id}`}>
                        {o.order_number}
                      </Link>
                    </td>
                    <td>{o.customer?.name ?? o.shipping_address.recipient_name ?? '–'}</td>
                    <td className="muted">{formatDateTime(o.created_at)}</td>
                    <td className="num">{o.items.reduce((n, i) => n + i.quantity, 0)} pcs</td>
                    <td className="num">{formatRupiah(o.total)}</td>
                    <td>
                      <OrderStatusBadge status={o.status} />
                    </td>
                  </tr>
                ))}
                {page.data.length === 0 && (
                  <tr>
                    <td colSpan={6} className="empty">
                      {q
                        ? 'Tidak ada pesanan yang cocok. Coba nomor pesanan atau nama lain.'
                        : status
                          ? `Tidak ada pesanan berstatus "${ORDER_STATUS_LABEL[status]}".`
                          : 'Belum ada pesanan masuk.'}
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )
      )}

      {page && page.meta.last_page > 1 && (
        <div className="pagination">
          <button className="ghost" disabled={currentPage <= 1} onClick={() => setCurrentPage((p) => p - 1)}>
            Sebelumnya
          </button>
          <span className="muted">
            Halaman {page.meta.current_page} / {page.meta.last_page}
          </span>
          <button
            className="ghost"
            disabled={currentPage >= page.meta.last_page}
            onClick={() => setCurrentPage((p) => p + 1)}
          >
            Berikutnya
          </button>
        </div>
      )}
    </div>
  )
}
