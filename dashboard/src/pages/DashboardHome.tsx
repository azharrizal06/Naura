import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '@/auth/AuthContext'
import { fetchProducts } from '@/lib/catalog'

export function DashboardHome() {
  const { user } = useAuth()
  const [activeProducts, setActiveProducts] = useState<number | null>(null)

  useEffect(() => {
    void fetchProducts({ status: 'active', per_page: 1 })
      .then((p) => setActiveProducts(p.meta.total))
      .catch(() => setActiveProducts(null))
  }, [])

  return (
    <div>
      <h2>Assalamu&rsquo;alaikum, {user?.name}</h2>
      <p className="muted" style={{ margin: '0.5rem 0 0' }}>
        Anda masuk sebagai {user?.role_label?.toLowerCase()}.
      </p>

      <dl className="figures">
        <div className="figure">
          <dt>Produk aktif</dt>
          <dd>{activeProducts ?? '–'}</dd>
          <small>
            <Link to="/products" style={{ color: 'var(--plum)', fontWeight: 600 }}>
              Lihat katalog
            </Link>
          </small>
        </div>
        <div className="figure">
          <dt>Pesanan hari ini</dt>
          <dd>–</dd>
          <small>Muncul setelah modul pesanan aktif.</small>
        </div>
        <div className="figure">
          <dt>Omzet bulan ini</dt>
          <dd>–</dd>
          <small>Muncul setelah modul laporan aktif.</small>
        </div>
      </dl>
    </div>
  )
}
