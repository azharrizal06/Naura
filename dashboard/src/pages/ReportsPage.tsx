import { useEffect, useState, type FormEvent } from 'react'
import { Spinner } from '@/components/Spinner'
import { DailySalesChart } from '@/components/DailySalesChart'
import { apiErrorMessage } from '@/lib/api'
import { formatRupiah } from '@/lib/format'
import { fetchSalesReport } from '@/lib/owner'
import type { SalesReport } from '@/types'

/** Tanggal lokal "YYYY-MM-DD". */
function iso(d: Date): string {
  const p = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`
}

type Preset = '7' | '30' | 'month' | 'last-month' | 'custom'

function presetRange(preset: Exclude<Preset, 'custom'>): [string, string] {
  const today = new Date()
  const daysAgo = (n: number) => new Date(today.getFullYear(), today.getMonth(), today.getDate() - n)
  switch (preset) {
    case '7':
      return [iso(daysAgo(6)), iso(today)]
    case '30':
      return [iso(daysAgo(29)), iso(today)]
    case 'month':
      return [iso(new Date(today.getFullYear(), today.getMonth(), 1)), iso(today)]
    case 'last-month':
      return [
        iso(new Date(today.getFullYear(), today.getMonth() - 1, 1)),
        iso(new Date(today.getFullYear(), today.getMonth(), 0)),
      ]
  }
}

const PRESETS: { value: Exclude<Preset, 'custom'>; label: string }[] = [
  { value: '7', label: '7 hari' },
  { value: '30', label: '30 hari' },
  { value: 'month', label: 'Bulan ini' },
  { value: 'last-month', label: 'Bulan lalu' },
]

const dayLabel = new Intl.DateTimeFormat('id-ID', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' })
const rangeLabel = new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })

function parse(isoDate: string): Date {
  const [y, m, d] = isoDate.split('-').map(Number)
  return new Date(y, m - 1, d)
}

export function ReportsPage() {
  const [preset, setPreset] = useState<Preset>('30')
  const [range, setRange] = useState<[string, string]>(() => presetRange('30'))
  const [draft, setDraft] = useState<[string, string]>(range)
  const [report, setReport] = useState<SalesReport | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    setLoading(true)
    setError(null)
    fetchSalesReport(range[0], range[1])
      .then(setReport)
      .catch((err) => setError(apiErrorMessage(err, 'Laporan tidak bisa dimuat. Coba lagi.')))
      .finally(() => setLoading(false))
  }, [range])

  function choosePreset(p: Exclude<Preset, 'custom'>) {
    const r = presetRange(p)
    setPreset(p)
    setRange(r)
    setDraft(r)
  }

  function applyCustom(e: FormEvent) {
    e.preventDefault()
    setPreset('custom')
    setRange(draft)
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h2>Laporan &amp; Omzet</h2>
          <p className="muted">
            {rangeLabel.format(parse(range[0]))} – {rangeLabel.format(parse(range[1]))}. Omzet dihitung dari pesanan
            yang sudah dibayar, menurut tanggal pembayaran dikonfirmasi.
          </p>
        </div>
      </div>

      {/* Filter dalam satu baris di atas grafik. */}
      <div className="toolbar report-filters">
        <div className="tabs" role="group" aria-label="Periode">
          {PRESETS.map((p) => (
            <button key={p.value} type="button" aria-pressed={preset === p.value} onClick={() => choosePreset(p.value)}>
              {p.label}
            </button>
          ))}
        </div>
        <form className="date-range" onSubmit={applyCustom}>
          <input
            type="date"
            aria-label="Dari tanggal"
            value={draft[0]}
            max={draft[1]}
            onChange={(e) => setDraft([e.target.value, draft[1]])}
            required
          />
          <span className="muted">s.d.</span>
          <input
            type="date"
            aria-label="Sampai tanggal"
            value={draft[1]}
            min={draft[0]}
            onChange={(e) => setDraft([draft[0], e.target.value])}
            required
          />
          <button type="submit" className="ghost">
            Terapkan
          </button>
        </form>
      </div>

      {error && <div className="alert">{error}</div>}

      {loading && !report ? (
        <Spinner />
      ) : (
        report && (
          <div style={{ opacity: loading ? 0.5 : 1 }}>
            <dl className="figures" style={{ marginTop: '1rem' }}>
              <div className="figure">
                <dt>Omzet</dt>
                <dd>{formatRupiah(report.revenue)}</dd>
                <small>
                  Barang {formatRupiah(report.goods)} · ongkir {formatRupiah(report.shipping)}
                </small>
              </div>
              <div className="figure">
                <dt>Pesanan dibayar</dt>
                <dd>{report.orders}</dd>
                <small>{report.cancelled} pesanan batal di periode ini</small>
              </div>
              <div className="figure">
                <dt>Rata-rata per pesanan</dt>
                <dd>{formatRupiah(report.average_order)}</dd>
                <small>Termasuk ongkir</small>
              </div>
            </dl>

            <div className="section-header">
              <h3>Omzet harian</h3>
            </div>
            {report.revenue === 0 ? (
              <div className="placeholder">
                <p className="muted" style={{ margin: 0 }}>
                  Belum ada pembayaran yang dikonfirmasi di periode ini.
                </p>
              </div>
            ) : (
              <>
                <DailySalesChart data={report.daily} />
                <details className="table-toggle">
                  <summary>Lihat sebagai tabel</summary>
                  <div className="table-wrap">
                    <table>
                      <thead>
                        <tr>
                          <th>Tanggal</th>
                          <th className="num">Pesanan dibayar</th>
                          <th className="num">Omzet</th>
                        </tr>
                      </thead>
                      <tbody>
                        {report.daily.map((d) => (
                          <tr key={d.date}>
                            <td>{dayLabel.format(parse(d.date))}</td>
                            <td className="num">{d.orders}</td>
                            <td className="num">{formatRupiah(d.revenue)}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </details>
              </>
            )}

            <div className="section-header">
              <h3>Produk terlaris</h3>
            </div>
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Produk</th>
                    <th className="num">Terjual</th>
                    <th className="num">Penjualan barang</th>
                  </tr>
                </thead>
                <tbody>
                  {report.top_products.map((p) => (
                    <tr key={p.product_name}>
                      <td>{p.product_name}</td>
                      <td className="num">{p.quantity} pcs</td>
                      <td className="num">{formatRupiah(p.revenue)}</td>
                    </tr>
                  ))}
                  {report.top_products.length === 0 && (
                    <tr>
                      <td colSpan={3} className="empty">
                        Belum ada barang terjual di periode ini.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )
      )}
    </div>
  )
}
