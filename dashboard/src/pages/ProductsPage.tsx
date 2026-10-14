import { useEffect, useState, type FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { AxiosError } from 'axios'
import { Modal } from '@/components/Modal'
import { Spinner } from '@/components/Spinner'
import { Status, Stock, Thumb } from '@/components/Swatch'
import { formatRupiah } from '@/lib/format'
import {
  createProduct,
  deleteProduct,
  fetchCategories,
  fetchProduct,
  fetchProducts,
  updateProduct,
  type ProductPayload,
} from '@/lib/catalog'
import type { ApiError, Category, Paginated, Product, ProductListItem } from '@/types'

export function ProductsPage() {
  const [page, setPage] = useState<Paginated<ProductListItem> | null>(null)
  const [categories, setCategories] = useState<Category[]>([])
  const [q, setQ] = useState('')
  const [categoryId, setCategoryId] = useState<number | ''>('')
  const [currentPage, setCurrentPage] = useState(1)
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [editing, setEditing] = useState<ProductListItem | null>(null)

  async function load() {
    setLoading(true)
    try {
      const data = await fetchProducts({
        q: q || undefined,
        category_id: categoryId || undefined,
        page: currentPage,
      })
      setPage(data)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void fetchCategories().then(setCategories)
  }, [])

  useEffect(() => {
    void load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentPage])

  function handleSearch(e: FormEvent) {
    e.preventDefault()
    setCurrentPage(1)
    void load()
  }

  async function handleDelete(p: ProductListItem) {
    if (!confirm(`Hapus produk "${p.name}"?`)) return
    try {
      await deleteProduct(p.id)
      await load()
    } catch (err) {
      const ax = err as AxiosError<ApiError>
      alert(ax.response?.data?.message ?? 'Gagal menghapus produk.')
    }
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h2>Produk</h2>
          {page && <p className="muted">{page.meta.total} produk di katalog</p>}
        </div>
        <button
          onClick={() => {
            setEditing(null)
            setShowForm(true)
          }}
        >
          Tambah produk
        </button>
      </div>

      <form className="toolbar" onSubmit={handleSearch}>
        <input type="search" aria-label="Cari produk" placeholder="Cari nama produk" value={q} onChange={(e) => setQ(e.target.value)} />
        <select
          aria-label="Kategori"
          value={categoryId}
          onChange={(e) => setCategoryId(e.target.value ? Number(e.target.value) : '')}
        >
          <option value="">Semua kategori</option>
          {categories.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
        <button type="submit" className="ghost">
          Cari
        </button>
      </form>

      {loading ? (
        <Spinner />
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Produk</th>
                <th>Kategori</th>
                <th className="num">Harga dasar</th>
                <th className="num">Stok</th>
                <th>Status</th>
                <th>
                  <span className="sr-only">Aksi</span>
                </th>
              </tr>
            </thead>
            <tbody>
              {page?.data.map((p) => (
                <tr key={p.id}>
                  <td>
                    <div className="product-cell">
                      <Thumb src={p.primary_image} />
                      <Link to={`/products/${p.id}`}>{p.name}</Link>
                    </div>
                  </td>
                  <td className="muted">{p.category?.name ?? '–'}</td>
                  <td className="num">{formatRupiah(p.base_price)}</td>
                  <td className="num">
                    <Stock value={p.total_stock ?? 0} />
                  </td>
                  <td>
                    <Status active={p.is_active} />
                  </td>
                  <td className="actions">
                    <Link className="btn-link" to={`/products/${p.id}`}>
                      Varian & stok
                    </Link>
                    <button
                      className="ghost"
                      onClick={() => {
                        setEditing(p)
                        setShowForm(true)
                      }}
                    >
                      Ubah
                    </button>
                    <button className="ghost danger" onClick={() => handleDelete(p)}>
                      Hapus
                    </button>
                  </td>
                </tr>
              ))}
              {page?.data.length === 0 && (
                <tr>
                  <td colSpan={6} className="empty">
                    {q || categoryId
                      ? 'Tidak ada produk yang cocok. Coba kata kunci atau kategori lain.'
                      : 'Katalog masih kosong. Tambahkan produk pertama untuk mulai berjualan.'}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      {page && page.meta.last_page > 1 && (
        <div className="pagination">
          <button
            className="ghost"
            disabled={currentPage <= 1}
            onClick={() => setCurrentPage((p) => p - 1)}
          >
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

      {showForm && (
        <ProductForm
          productId={editing?.id ?? null}
          categories={categories}
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

function ProductForm({
  productId,
  categories,
  onClose,
  onSaved,
}: {
  productId: number | null
  categories: Category[]
  onClose: () => void
  onSaved: () => void
}) {
  const [form, setForm] = useState<ProductPayload>({
    category_id: categories[0]?.id ?? 0,
    name: '',
    description: '',
    base_price: 0,
    weight_grams: 0,
    is_active: true,
  })
  const [loadingProduct, setLoadingProduct] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    if (!productId) return
    setLoadingProduct(true)
    fetchProduct(productId)
      .then((p: Product) =>
        setForm({
          category_id: p.category_id,
          name: p.name,
          description: p.description ?? '',
          base_price: p.base_price,
          weight_grams: p.weight_grams,
          is_active: p.is_active,
        }),
      )
      .finally(() => setLoadingProduct(false))
  }, [productId])

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setSaving(true)
    setError(null)
    try {
      if (productId) {
        await updateProduct(productId, form)
      } else {
        await createProduct(form)
      }
      onSaved()
    } catch (err) {
      const ax = err as AxiosError<ApiError>
      setError(ax.response?.data?.message ?? 'Gagal menyimpan produk.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal title={productId ? 'Ubah produk' : 'Produk baru'} onClose={onClose}>
      {loadingProduct ? (
        <Spinner />
      ) : (
        <form onSubmit={handleSubmit} className="form">
          {error && <div className="alert">{error}</div>}
          <label>
            Nama
            <input
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              required
            />
          </label>
          <label>
            Kategori
            <select
              value={form.category_id}
              onChange={(e) => setForm({ ...form, category_id: Number(e.target.value) })}
              required
            >
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </label>
          <div className="form-row">
          <label>
            Harga dasar (Rp)
            <input
              type="number"
              min={0}
              value={form.base_price}
              onChange={(e) => setForm({ ...form, base_price: Number(e.target.value) })}
              required
            />
          </label>
          <label>
            Berat (gram)
            <input
              type="number"
              min={0}
              value={form.weight_grams}
              onChange={(e) => setForm({ ...form, weight_grams: Number(e.target.value) })}
            />
          </label>
          </div>
          <label>
            Deskripsi
            <textarea
              value={form.description ?? ''}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
              rows={3}
            />
          </label>
          <label className="checkbox">
            <input
              type="checkbox"
              checked={form.is_active}
              onChange={(e) => setForm({ ...form, is_active: e.target.checked })}
            />
            Tampilkan di aplikasi
          </label>
          <div className="form-actions">
            <button type="button" className="ghost" onClick={onClose}>
              Batal
            </button>
            <button type="submit" disabled={saving}>
              {saving ? 'Menyimpan…' : productId ? 'Simpan perubahan' : 'Tambah produk'}
            </button>
          </div>
        </form>
      )}
    </Modal>
  )
}
