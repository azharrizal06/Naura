import { useEffect, useState, type FormEvent } from 'react'
import { AxiosError } from 'axios'
import { Modal } from '@/components/Modal'
import { Spinner } from '@/components/Spinner'
import { Status } from '@/components/Swatch'
import {
  createCategory,
  deleteCategory,
  fetchCategories,
  updateCategory,
} from '@/lib/catalog'
import type { ApiError, Category } from '@/types'

export function CategoriesPage() {
  const [categories, setCategories] = useState<Category[]>([])
  const [loading, setLoading] = useState(true)
  const [editing, setEditing] = useState<Category | null>(null)
  const [creating, setCreating] = useState(false)

  async function load() {
    setLoading(true)
    try {
      setCategories(await fetchCategories())
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  async function handleDelete(cat: Category) {
    if (!confirm(`Hapus kategori "${cat.name}"?`)) return
    try {
      await deleteCategory(cat.id)
      await load()
    } catch (err) {
      const ax = err as AxiosError<ApiError>
      alert(ax.response?.data?.message ?? 'Gagal menghapus kategori.')
    }
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h2>Kategori</h2>
          <p className="muted">Kelompok yang tampil sebagai tab di aplikasi pembeli.</p>
        </div>
        <button onClick={() => setCreating(true)}>Tambah kategori</button>
      </div>

      {loading ? (
        <Spinner />
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Nama</th>
                <th>Slug</th>
                <th className="num">Produk</th>
                <th>Status</th>
                <th>
                  <span className="sr-only">Aksi</span>
                </th>
              </tr>
            </thead>
            <tbody>
              {categories.map((cat) => (
                <tr key={cat.id}>
                  <td style={{ fontWeight: 600 }}>{cat.name}</td>
                  <td className="sku">{cat.slug}</td>
                  <td className="num">{cat.products_count ?? 0}</td>
                  <td>
                    <Status active={cat.is_active} />
                  </td>
                  <td className="actions">
                    <button className="ghost" onClick={() => setEditing(cat)}>
                      Ubah
                    </button>
                    <button className="ghost danger" onClick={() => handleDelete(cat)}>
                      Hapus
                    </button>
                  </td>
                </tr>
              ))}
              {categories.length === 0 && (
                <tr>
                  <td colSpan={5} className="empty">
                    Belum ada kategori. Buat satu, misalnya Gamis atau Hijab, lalu kelompokkan produk ke dalamnya.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      {(creating || editing) && (
        <CategoryForm
          category={editing}
          onClose={() => {
            setCreating(false)
            setEditing(null)
          }}
          onSaved={async () => {
            setCreating(false)
            setEditing(null)
            await load()
          }}
        />
      )}
    </div>
  )
}

function CategoryForm({
  category,
  onClose,
  onSaved,
}: {
  category: Category | null
  onClose: () => void
  onSaved: () => void
}) {
  const [name, setName] = useState(category?.name ?? '')
  const [description, setDescription] = useState(category?.description ?? '')
  const [isActive, setIsActive] = useState(category?.is_active ?? true)
  const [error, setError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setSaving(true)
    setError(null)
    try {
      const payload = { name, description, is_active: isActive }
      if (category) {
        await updateCategory(category.id, payload)
      } else {
        await createCategory(payload)
      }
      onSaved()
    } catch (err) {
      const ax = err as AxiosError<ApiError>
      setError(ax.response?.data?.message ?? 'Gagal menyimpan.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal title={category ? 'Ubah kategori' : 'Kategori baru'} onClose={onClose}>
      <form onSubmit={handleSubmit} className="form">
        {error && <div className="alert">{error}</div>}
        <label>
          Nama
          <input value={name} onChange={(e) => setName(e.target.value)} required />
        </label>
        <label>
          Deskripsi
          <textarea value={description ?? ''} onChange={(e) => setDescription(e.target.value)} rows={3} />
        </label>
        <label className="checkbox">
          <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} />
          Tampilkan di aplikasi
        </label>
        <div className="form-actions">
          <button type="button" className="ghost" onClick={onClose}>
            Batal
          </button>
          <button type="submit" disabled={saving}>
            {saving ? 'Menyimpan…' : category ? 'Simpan perubahan' : 'Tambah kategori'}
          </button>
        </div>
      </form>
    </Modal>
  )
}
