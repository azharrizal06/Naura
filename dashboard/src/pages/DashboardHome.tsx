import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '@/auth/AuthContext'
import { fetchProducts } from '@/lib/catalog'
import { fetchSummary } from '@/lib/orders'
import { formatRupiah } from '@/lib/format'
import type { DashboardSummary } from '@/types'

export function DashboardHome() {
  const { user } = useAuth()
  const [activeProducts, setActiveProducts] = useState<number | null>(null)
  const [summary, setSummary] = useState<DashboardSummary | null>(null)

  useEffect(() => {
    void fetchProducts({ status: 'active', per_page: 1 })
      .then((p) => setActiveProducts(p.meta.total))
      .catch(() => setActiveProducts(null))
    void fetchSummary()
      .then(setSummary)
      .catch(() => setSummary(null))
  }, [])

  const link = { color: 'var(--plum)', fontWeight: 600 }

  return (
    <div>
      <h2>Assalamu&rsquo;alaikum, {user?.name}</h2>
      <p className="muted" style={{ margin: '0.5rem 0 0' }}>
        Anda masuk sebagai {user?.role_label?.toLowerCase()}.
      </p>

      <dl className="figures">
        {summary?.revenue_this_month !== undefined && (
          <div className="figure">
            <dt>Omzet bulan ini</dt>
            <dd>{formatRupiah(summary.revenue_this_month)}</dd>
            <small>
              <Link to="/reports" style={link}>
                Lihat laporan
              </Link>
            </small>
          </div>
        )}
        <div className="figure">
          <dt>Pesanan hari ini</dt>
          <dd>{summary?.orders_today ?? '–'}</dd>
          <small>
            <Link to="/orders" style={link}>
              Lihat pesanan
            </Link>
          </small>
        </div>
        <div className="figure">
          <dt>Perlu diproses</dt>
          <dd>{summary?.to_process ?? '–'}</dd>
          <small>
            <Link to="/orders?status=paid" style={link}>
              Sudah dibayar
            </Link>
          </small>
        </div>
        <div className="figure">
          <dt>Perlu dikirim</dt>
          <dd>{summary?.to_ship ?? '–'}</dd>
          <small>
            <Link to="/orders?status=processing" style={link}>
              Sedang diproses
            </Link>
          </small>
        </div>
        <div className="figure">
          <dt>Menunggu transfer</dt>
          <dd>{summary?.awaiting_payment ?? '–'}</dd>
          <small>
            <Link to="/orders?status=pending" style={link}>
              Cocokkan pembayaran
            </Link>
          </small>
        </div>
        <div className="figure">
          <dt>Produk aktif</dt>
          <dd>{activeProducts ?? '–'}</dd>
          <small>
            <Link to="/products" style={link}>
              Lihat katalog
            </Link>
          </small>
        </div>
      </dl>
    </div>
  )
}
