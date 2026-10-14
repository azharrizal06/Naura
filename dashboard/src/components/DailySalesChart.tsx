import { useEffect, useRef, useState } from 'react'
import { formatRupiah } from '@/lib/format'

export interface DailyPoint {
  date: string
  revenue: number
  orders: number
}

const HEIGHT = 240
const PAD = { top: 12, right: 8, bottom: 28, left: 64 }
const GAP = 2 // jarak antar-batang

const shortDate = new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'short' })
const longDate = new Intl.DateTimeFormat('id-ID', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })

/** "1,2 jt" / "350 rb" untuk label sumbu. */
function shortRupiah(v: number): string {
  if (v >= 1_000_000) return `${(v / 1_000_000).toLocaleString('id-ID', { maximumFractionDigits: 1 })} jt`
  if (v >= 1_000) return `${Math.round(v / 1_000)} rb`
  return String(v)
}

/** Garis bantu "rapi" (1, 2, 2,5, 5 × 10ⁿ), sekitar 4 garis. */
function niceTicks(max: number): number[] {
  if (max <= 0) return [0]
  const raw = max / 4
  const mag = 10 ** Math.floor(Math.log10(raw))
  const step = [1, 2, 2.5, 5, 10].map((m) => m * mag).find((s) => s >= raw) ?? raw
  const ticks: number[] = []
  for (let t = 0; t <= max + step * 0.001; t += step) ticks.push(t)
  if (ticks[ticks.length - 1] < max) ticks.push(ticks[ticks.length - 1] + step)
  return ticks
}

/** Batang dengan sudut atas membulat 4px, menempel di garis dasar. */
function barPath(x: number, y: number, w: number, h: number): string {
  const r = Math.min(4, w / 2, h)
  return `M${x},${y + h}V${y + r}Q${x},${y} ${x + r},${y}H${x + w - r}Q${x + w},${y} ${x + w},${y + r}V${y + h}Z`
}

function parseDate(iso: string): Date {
  const [y, m, d] = iso.split('-').map(Number)
  return new Date(y, m - 1, d)
}

/** Omzet per hari sebagai batang (satu seri, jadi tanpa legenda — judul menamainya). */
export function DailySalesChart({ data }: { data: DailyPoint[] }) {
  const wrapRef = useRef<HTMLDivElement>(null)
  const [width, setWidth] = useState(720)
  const [hover, setHover] = useState<number | null>(null)

  useEffect(() => {
    const el = wrapRef.current
    if (!el) return
    const ro = new ResizeObserver(([entry]) => setWidth(Math.max(320, entry.contentRect.width)))
    ro.observe(el)
    return () => ro.disconnect()
  }, [])

  const ticks = niceTicks(Math.max(...data.map((d) => d.revenue), 0))
  const top = ticks[ticks.length - 1] || 1
  const plotW = width - PAD.left - PAD.right
  const plotH = HEIGHT - PAD.top - PAD.bottom
  const slot = plotW / Math.max(data.length, 1)
  const barW = Math.max(1, Math.min(28, slot - GAP))
  const y = (v: number) => PAD.top + plotH - (v / top) * plotH
  // Label tanggal jarang-jarang agar tidak bertumpuk (~1 per 64px).
  const every = Math.max(1, Math.ceil(data.length / Math.floor(plotW / 64)))
  const peak = data.reduce((best, d, i) => (d.revenue > (data[best]?.revenue ?? -1) ? i : best), 0)
  const hovered = hover === null ? null : data[hover]

  return (
    <div className="chart" ref={wrapRef}>
      <svg
        width={width}
        height={HEIGHT}
        role="img"
        aria-label={`Grafik omzet harian, ${data.length} hari. Rincian ada di tabel di bawahnya.`}
        onMouseLeave={() => setHover(null)}
      >
        {ticks.map((t) => (
          <g key={t}>
            <line className="chart-grid" x1={PAD.left} x2={width - PAD.right} y1={y(t)} y2={y(t)} />
            <text className="chart-axis" x={PAD.left - 8} y={y(t)} dy="0.32em" textAnchor="end">
              {shortRupiah(t)}
            </text>
          </g>
        ))}

        {data.map((d, i) => {
          const x = PAD.left + i * slot + (slot - barW) / 2
          const h = PAD.top + plotH - y(d.revenue)
          return (
            <g key={d.date}>
              {d.revenue > 0 && (
                <path
                  className={hover === i ? 'chart-bar active' : 'chart-bar'}
                  d={barPath(x, y(d.revenue), barW, h)}
                />
              )}
              {i % every === 0 && (
                <text className="chart-axis" x={x + barW / 2} y={HEIGHT - 8} textAnchor="middle">
                  {shortDate.format(parseDate(d.date))}
                </text>
              )}
              {/* Area sentuh setinggi grafik — lebih besar dari batangnya. */}
              <rect
                x={PAD.left + i * slot}
                y={PAD.top}
                width={slot}
                height={plotH}
                fill="transparent"
                onMouseEnter={() => setHover(i)}
              />
            </g>
          )
        })}

        {/* Satu label langsung: hari dengan omzet tertinggi. */}
        {data[peak]?.revenue > 0 && hover === null && (
          <text
            className="chart-label"
            x={PAD.left + peak * slot + slot / 2}
            y={y(data[peak].revenue) - 6}
            textAnchor="middle"
          >
            {shortRupiah(data[peak].revenue)}
          </text>
        )}
      </svg>

      {hovered && hover !== null && (
        <div
          className="chart-tooltip"
          style={{
            left: Math.min(Math.max(PAD.left + hover * slot + slot / 2, 90), width - 90),
            top: Math.max(y(hovered.revenue) - 8, 0),
          }}
        >
          <strong>{longDate.format(parseDate(hovered.date))}</strong>
          <span>{formatRupiah(hovered.revenue)}</span>
          <span className="muted">{hovered.orders} pesanan dibayar</span>
        </div>
      )}
    </div>
  )
}
