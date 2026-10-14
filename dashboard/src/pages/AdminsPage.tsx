import { useEffect, useState, type FormEvent } from 'react'
import { Modal } from '@/components/Modal'
import { Spinner } from '@/components/Spinner'
import { Status } from '@/components/Swatch'
import { apiErrorMessage } from '@/lib/api'
import { createAdmin, fetchAdmins, updateAdmin, type AdminPayload } from '@/lib/owner'
import type { User } from '@/types'

export function AdminsPage() {
  const [admins, setAdmins] = useState<User[] | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [editing, setEditing] = useState<User | 'new' | null>(null)

  async function load() {
    try {
      setAdmins(await fetchAdmins())
    } catch (err) {
      setError(apiErrorMessage(err, 'Daftar admin tidak bisa dimuat.'))
    }
  }

  useEffect(() => {
    void load()
  }, [])

  async function toggleActive(admin: User) {
    const next = !admin.is_active
    const question = next
      ? `Aktifkan lagi akun ${admin.name}?`
      : `Nonaktifkan ${admin.name}? Ia langsung keluar dari dashboard dan tidak bisa masuk sampai diaktifkan lagi.`
    if (!confirm(question)) return
    setError(null)
    try {
      await updateAdmin(admin.id, { is_active: next })
      await load()
    } catch (err) {
      setError(apiErrorMessage(err, 'Status admin tidak bisa diubah.'))
    }
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h2>Admin</h2>
          <p className="muted">Akun yang bisa mengelola produk dan memproses pesanan.</p>
        </div>
        <button onClick={() => setEditing('new')}>Tambah admin</button>
      </div>

      {error && <div className="alert">{error}</div>}

      {!admins ? (
        !error && <Spinner />
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Nama</th>
                <th>Email</th>
                <th>HP</th>
                <th>Status</th>
                <th>
                  <span className="sr-only">Aksi</span>
                </th>
              </tr>
            </thead>
            <tbody>
              {admins.map((a) => (
                <tr key={a.id}>
                  <td>
                    <strong>{a.name}</strong>
                  </td>
                  <td className="muted">{a.email}</td>
                  <td className="muted">{a.phone ?? '–'}</td>
                  <td>
                    <Status active={a.is_active} />
                  </td>
                  <td className="actions">
                    <button className="ghost" onClick={() => setEditing(a)}>
                      Ubah
                    </button>
                    <button className={a.is_active ? 'ghost danger' : 'ghost'} onClick={() => toggleActive(a)}>
                      {a.is_active ? 'Nonaktifkan' : 'Aktifkan'}
                    </button>
                  </td>
                </tr>
              ))}
              {admins.length === 0 && (
                <tr>
                  <td colSpan={5} className="empty">
                    Belum ada admin. Tambahkan akun untuk staf yang membantu memproses pesanan.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      {editing && (
        <AdminForm
          admin={editing === 'new' ? null : editing}
          onClose={() => setEditing(null)}
          onSaved={async () => {
            setEditing(null)
            await load()
          }}
        />
      )}
    </div>
  )
}

function AdminForm({ admin, onClose, onSaved }: { admin: User | null; onClose: () => void; onSaved: () => void }) {
  const [form, setForm] = useState({
    name: admin?.name ?? '',
    email: admin?.email ?? '',
    phone: admin?.phone ?? '',
    password: '',
  })
  const [error, setError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setSaving(true)
    setError(null)
    const payload: AdminPayload = {
      name: form.name,
      email: form.email,
      phone: form.phone || null,
      // Saat ubah, password kosong = tidak diganti.
      ...(form.password ? { password: form.password } : {}),
    }
    try {
      if (admin) await updateAdmin(admin.id, payload)
      else await createAdmin(payload)
      onSaved()
    } catch (err) {
      setError(apiErrorMessage(err, 'Akun admin tidak bisa disimpan.'))
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal title={admin ? `Ubah ${admin.name}` : 'Admin baru'} onClose={onClose}>
      <form className="form" onSubmit={handleSubmit}>
        {error && <div className="alert">{error}</div>}
        <label>
          Nama
          <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required autoFocus />
        </label>
        <label>
          Email (untuk masuk)
          <input
            type="email"
            value={form.email}
            onChange={(e) => setForm({ ...form, email: e.target.value })}
            required
          />
        </label>
        <label>
          Nomor HP
          <input type="tel" value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} />
        </label>
        <label>
          {admin ? 'Password baru' : 'Password'}
          <input
            type="password"
            autoComplete="new-password"
            minLength={8}
            value={form.password}
            onChange={(e) => setForm({ ...form, password: e.target.value })}
            required={!admin}
            placeholder={admin ? 'Kosongkan bila tidak diganti' : 'Minimal 8 karakter'}
          />
        </label>
        <div className="form-actions">
          <button type="button" className="ghost" onClick={onClose}>
            Batal
          </button>
          <button type="submit" disabled={saving}>
            {saving ? 'Menyimpan…' : admin ? 'Simpan perubahan' : 'Tambah admin'}
          </button>
        </div>
      </form>
    </Modal>
  )
}
