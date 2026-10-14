import { useEffect, useState, type FormEvent } from 'react'
import { Link, useParams } from 'react-router-dom'
import { AxiosError } from 'axios'
import { Modal } from '@/components/Modal'
import { Spinner } from '@/components/Spinner'
import { Status, Stock, Swatch } from '@/components/Swatch'
import { colorPart, swatchFor } from '@/lib/swatch'
import { formatRupiah } from '@/lib/format'
import {
  adjustStock,
  createVariant,
  deleteVariant,
  fetchProduct,
  updateVariant,
  type VariantPayload,
} from '@/lib/catalog'
import type { ApiError, Product, ProductVariant } from '@/types'

export function ProductDetailPage() {
  const { id } = useParams<{ id: string }>()
  const productId = Number(id)
  const [product, setProduct] = useState<Product | null>(null)
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [editingVariant, setEditingVariant] = useState<ProductVariant | null>(null)

  async function load() {
    setLoading(true)
    try {
      setProduct(await fetchProduct(productId))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [productId])

  async function handleStock(variant: ProductVariant) {
    const input = prompt(`Stok "${variant.name}" sekarang ${variant.stock}. Masukkan stok baru:`, String(variant.stock))
    if (input === null) return
    const value = Number(input)
    if (Number.isNaN(value) || value < 0) {
      alert('Nilai stok tidak valid.')
      return
    }
    await adjustStock(productId, variant.id, 'set', value)
    await load()
  }

  async function handleDeleteVariant(variant: ProductVariant) {
    if (!confirm(`Hapus varian "${variant.name}"?`)) return
    try {
      await deleteVariant(productId, variant.id)
      await load()
    } catch (err) {
      const ax = err as AxiosError<ApiError>
      alert(ax.response?.data?.message ?? 'Gagal menghapus varian.')
    }
  }

  if (loading) return <Spinner />
  if (!product)
    return (
      <div className="placeholder">
        Produk tidak ditemukan. <Link to="/products">Kembali ke daftar produk</Link>
      </div>
    )

  const variants = product.variants ?? []
  const palette = buildPalette(variants)

  return (
    <div>
      <div className="breadcrumb">
        <Link to="/products">Produk</Link>
        <span className="muted"> / {product.category?.name ?? 'Tanpa kategori'}</span>
      </div>

      <div className="page-header">
        <h2>{product.name}</h2>
        <Status active={product.is_active} />
      </div>

      <dl className="facts">
        <div>
          <dt>Kategori</dt>
          <dd>{product.category?.name ?? '–'}</dd>
        </div>
        <div>
          <dt>Harga dasar</dt>
          <dd>{formatRupiah(product.base_price)}</dd>
        </div>
        <div>
          <dt>Total stok</dt>
          <dd>{product.total_stock ?? 0} pcs</dd>
        </div>
        <div>
          <dt>Berat</dt>
          <dd>{product.weight_grams} g</dd>
        </div>
      </dl>

      {product.description && <p className="description">{product.description}</p>}

      {palette.length > 0 && (
        <>
          <div className="section-header">
            <h3>Warna tersedia</h3>
          </div>
          <ul className="palette">
            {palette.map((c) => (
              <li key={c.name} className={c.stock === 0 ? 'empty' : undefined}>
                <span className="swatch" style={{ background: c.hex }} aria-hidden="true" />
                <span>{c.name}</span>
                <small>{c.stock === 0 ? 'Habis' : `${c.stock} pcs`}</small>
              </li>
            ))}
          </ul>
        </>
      )}

      <div className="section-header">
        <h3>Varian &amp; stok</h3>
        <button
          onClick={() => {
            setEditingVariant(null)
            setShowForm(true)
          }}
        >
          Tambah varian
        </button>
      </div>

      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Varian</th>
              <th>SKU</th>
              <th className="num">Harga</th>
              <th className="num">Stok</th>
              <th>Status</th>
              <th>
                <span className="sr-only">Aksi</span>
              </th>
            </tr>
          </thead>
          <tbody>
            {variants.map((v) => (
              <tr key={v.id}>
                <td>
                  <span className="with-swatch">
                    <Swatch name={v.name} />
                    {v.name}
                  </span>
                </td>
                <td className="sku">{v.sku}</td>
                <td className="num">{formatRupiah(v.price)}</td>
                <td className="num">
                  <Stock value={v.stock} />
                </td>
                <td>
                  <Status active={v.is_active} />
                </td>
                <td className="actions">
                  <button className="ghost" onClick={() => handleStock(v)}>
                    Atur stok
                  </button>
                  <button
                    className="ghost"
                    onClick={() => {
                      setEditingVariant(v)
                      setShowForm(true)
                    }}
                  >
                    Ubah
                  </button>
                  <button className="ghost danger" onClick={() => handleDeleteVariant(v)}>
                    Hapus
                  </button>
                </td>
              </tr>
            ))}
            {variants.length === 0 && (
              <tr>
                <td colSpan={6} className="empty">
                  Belum ada varian. Tambahkan minimal satu, misalnya &ldquo;Mocca / M&rdquo;, agar produk bisa dibeli.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {showForm && (
        <VariantForm
          productId={productId}
          variant={editingVariant}
          onClose={() => setShowForm(false)}
          onSaved={async () => {
            setShowForm(false)
            await load()
          }}
        />
      )}
    </div>
  )
}

function VariantForm({
  productId,
  variant,
  onClose,
  onSaved,
}: {
  productId: number
  variant: ProductVariant | null
  onClose: () => void
  onSaved: () => void
}) {
  const [form, setForm] = useState<VariantPayload>({
    sku: variant?.sku ?? '',
    name: variant?.name ?? '',
    price: variant?.price ?? 0,
    stock: variant?.stock ?? 0,
    is_active: variant?.is_active ?? true,
  })
  const [error, setError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setSaving(true)
    setError(null)
    try {
      if (variant) {
        await updateVariant(productId, variant.id, form)
      } else {
        await createVariant(productId, form)
      }
      onSaved()
    } catch (err) {
      const ax = err as AxiosError<ApiError>
      setError(ax.response?.data?.message ?? 'Gagal menyimpan varian.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal title={variant ? 'Ubah varian' : 'Varian baru'} onClose={onClose}>
      <form onSubmit={handleSubmit} className="form">
        {error && <div className="alert">{error}</div>}
        <label>
          Nama varian
          <span className="with-swatch">
            <input
              style={{ flex: 1 }}
              placeholder="Warna / Ukuran, misalnya Sage / L"
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              required
            />
            <Swatch name={form.name} size={28} />
          </span>
        </label>
        <label>
          SKU
          <input value={form.sku} onChange={(e) => setForm({ ...form, sku: e.target.value })} required />
        </label>
        <div className="form-row">
        <label>
          Harga (Rp)
          <input
            type="number"
            min={0}
            value={form.price}
            onChange={(e) => setForm({ ...form, price: Number(e.target.value) })}
            required
          />
        </label>
        <label>
          Stok
          <input
            type="number"
            min={0}
            value={form.stock}
            onChange={(e) => setForm({ ...form, stock: Number(e.target.value) })}
          />
        </label>
        </div>
        <label className="checkbox">
          <input
            type="checkbox"
            checked={form.is_active}
            onChange={(e) => setForm({ ...form, is_active: e.target.checked })}
          />
          Bisa dipilih pembeli
        </label>
        <div className="form-actions">
          <button type="button" className="ghost" onClick={onClose}>
            Batal
          </button>
          <button type="submit" disabled={saving}>
            {saving ? 'Menyimpan…' : variant ? 'Simpan perubahan' : 'Tambah varian'}
          </button>
        </div>
      </form>
    </Modal>
  )
}

interface PaletteEntry {
  name: string
  hex: string
  stock: number
}

/** Kelompokkan varian per warna ("Mocca / M" + "Mocca / L" → Mocca) dan jumlahkan stoknya. */
function buildPalette(variants: ProductVariant[]): PaletteEntry[] {
  const byColor = new Map<string, PaletteEntry>()
  for (const v of variants) {
    const swatch = swatchFor(v.name)
    if (!swatch) continue
    const name = colorPart(v.name)
    const entry = byColor.get(name) ?? { name, hex: swatch.hex, stock: 0 }
    entry.stock += v.stock
    byColor.set(name, entry)
  }
  return [...byColor.values()]
}
