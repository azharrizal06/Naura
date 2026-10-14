import { useState, type FormEvent } from 'react'
import { useAuth } from '@/auth/AuthContext'
import { changePassword, updateProfile } from '@/lib/account'
import { apiErrorMessage } from '@/lib/api'

/** Profil sendiri (admin & owner): data diri dan ganti password. */
export function ProfilePage() {
  return (
    <div>
      <div className="page-header">
        <div>
          <h2>Profil</h2>
          <p className="muted">Data akun Anda untuk masuk ke dashboard.</p>
        </div>
      </div>
      <div className="settings-form">
        <ProfileForm />
        <PasswordForm />
      </div>
    </div>
  )
}

function ProfileForm() {
  const { user, setUser } = useAuth()
  const [name, setName] = useState(user?.name ?? '')
  const [phone, setPhone] = useState(user?.phone ?? '')
  const [email, setEmail] = useState(user?.email ?? '')
  const [currentPassword, setCurrentPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [saved, setSaved] = useState(false)
  const [busy, setBusy] = useState(false)

  const emailChanged = email.trim().toLowerCase() !== (user?.email ?? '').toLowerCase()

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setBusy(true)
    setError(null)
    setSaved(false)
    try {
      const updated = await updateProfile({
        name: name.trim(),
        phone: phone.trim() || null,
        email: email.trim(),
        ...(emailChanged ? { current_password: currentPassword } : {}),
      })
      setUser(updated)
      setCurrentPassword('')
      setSaved(true)
    } catch (err) {
      setError(apiErrorMessage(err, 'Profil tidak bisa disimpan.'))
    } finally {
      setBusy(false)
    }
  }

  return (
    <form className="form" onSubmit={handleSubmit}>
      <div className="section-header">
        <h3>Data diri</h3>
      </div>
      {error && <div className="alert">{error}</div>}
      <label>
        Nama
        <input value={name} onChange={(e) => setName(e.target.value)} required />
      </label>
      <div className="form-row">
        <label>
          Email (untuk masuk)
          <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
        </label>
        <label>
          Nomor HP
          <input type="tel" value={phone} onChange={(e) => setPhone(e.target.value)} />
        </label>
      </div>
      {emailChanged && (
        <label>
          Password saat ini
          <input
            type="password"
            autoComplete="current-password"
            value={currentPassword}
            onChange={(e) => setCurrentPassword(e.target.value)}
            placeholder="Wajib untuk mengganti email"
            required
          />
        </label>
      )}
      <div className="form-actions" style={{ justifyContent: 'flex-start' }}>
        <button type="submit" disabled={busy}>
          {busy ? 'Menyimpan…' : 'Simpan profil'}
        </button>
        {saved && <span className="status status-on">Tersimpan</span>}
      </div>
    </form>
  )
}

function PasswordForm() {
  const [current, setCurrent] = useState('')
  const [next, setNext] = useState('')
  const [confirm, setConfirm] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [saved, setSaved] = useState(false)
  const [busy, setBusy] = useState(false)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setSaved(false)
    if (next !== confirm) {
      setError('Password baru dan ulangannya tidak sama.')
      return
    }
    setBusy(true)
    setError(null)
    try {
      await changePassword(current, next)
      setCurrent('')
      setNext('')
      setConfirm('')
      setSaved(true)
    } catch (err) {
      setError(apiErrorMessage(err, 'Password tidak bisa diganti.'))
    } finally {
      setBusy(false)
    }
  }

  return (
    <form className="form" onSubmit={handleSubmit}>
      <div className="section-header">
        <h3>Ganti password</h3>
      </div>
      <p className="muted" style={{ margin: 0, fontSize: '0.88rem' }}>
        Sesi di perangkat atau browser lain akan dikeluarkan; sesi ini tetap masuk.
      </p>
      {error && <div className="alert">{error}</div>}
      <label>
        Password saat ini
        <input
          type="password"
          autoComplete="current-password"
          value={current}
          onChange={(e) => setCurrent(e.target.value)}
          required
        />
      </label>
      <div className="form-row">
        <label>
          Password baru
          <input
            type="password"
            autoComplete="new-password"
            minLength={8}
            value={next}
            onChange={(e) => setNext(e.target.value)}
            placeholder="Minimal 8 karakter"
            required
          />
        </label>
        <label>
          Ulangi password baru
          <input type="password" autoComplete="new-password" value={confirm} onChange={(e) => setConfirm(e.target.value)} required />
        </label>
      </div>
      <div className="form-actions" style={{ justifyContent: 'flex-start' }}>
        <button type="submit" disabled={busy}>
          {busy ? 'Menyimpan…' : 'Ganti password'}
        </button>
        {saved && <span className="status status-on">Password diganti</span>}
      </div>
    </form>
  )
}
