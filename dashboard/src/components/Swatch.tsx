import { useState } from 'react'
import { swatchFor } from '@/lib/swatch'

/** Titik warna kain untuk nama varian. Tidak dirender bila warna tak dikenali. */
export function Swatch({ name, size = 14 }: { name: string; size?: number }) {
  const swatch = swatchFor(name)
  if (!swatch) return null
  return (
    <span
      className="swatch"
      style={{ background: swatch.hex, width: size, height: size }}
      aria-hidden="true"
    />
  )
}

/** Status aktif/nonaktif sebagai titik + teks. */
export function Status({ active }: { active: boolean }) {
  return <span className={active ? 'status status-on' : 'status'}>{active ? 'Aktif' : 'Nonaktif'}</span>
}

/** Jumlah stok dengan penanda habis/menipis. */
export function Stock({ value }: { value: number }) {
  if (value === 0) return <span className="stock stock-out">Habis</span>
  if (value < 5) return <span className="stock stock-low">Sisa {value}</span>
  return <span className="stock">{value}</span>
}

/** Foto produk 3:4; jatuh ke lipatan kain bila foto kosong atau gagal dimuat. */
export function Thumb({ src }: { src?: string | null }) {
  const [failed, setFailed] = useState(false)
  if (!src || failed) return <span className="thumb" aria-hidden="true" />
  return <img className="thumb" src={src} alt="" onError={() => setFailed(true)} />
}
