import { useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { AxiosError } from 'axios'
import { useAuth } from '@/auth/AuthContext'
import type { ApiError } from '@/types'

// Warna yang dijual toko, dari gelap ke terang — tampil sebagai gulungan kain.
const BOLTS = ['#6C1F2B', '#A07E62', '#D2A3A3', '#B6A2C8', '#A2B299', '#5A5D3B', '#24304F', '#EEE8DC']
const BOLT_HEIGHTS = [78, 100, 64, 88, 72, 94, 58, 82]

export function LoginPage() {
  const { login } = useAuth()
  const navigate = useNavigate()
  const [email, setEmail] = useState('admin@naura.test')
  const [password, setPassword] = useState('password')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError(null)
    setSubmitting(true)
    try {
      const user = await login(email, password)
      if (!['admin', 'owner'].includes(user.role)) {
        setError('Akun pelanggan tidak bisa masuk ke sini. Gunakan akun admin atau pemilik toko.')
        return
      }
      navigate('/')
    } catch (err) {
      const ax = err as AxiosError<ApiError>
      setError(ax.response?.data?.message ?? 'Server tidak bisa dihubungi. Pastikan backend sedang berjalan.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="login">
      <section className="login-panel">
        <div>
          <div className="wordmark">naura</div>
          <p>Kelola koleksi, stok, dan pesanan toko dari satu tempat.</p>
        </div>
        <div className="bolts" aria-hidden="true">
          {BOLTS.map((color, i) => (
            <span
              key={color}
              className="bolt"
              style={{ background: color, height: `${BOLT_HEIGHTS[i]}%`, animationDelay: `${i * 70}ms` }}
            />
          ))}
        </div>
      </section>

      <div className="login-form-wrap">
        <form className="login-form" onSubmit={handleSubmit}>
          <h1>Masuk</h1>
          <p className="muted" style={{ margin: 0 }}>
            Untuk admin dan pemilik toko.
          </p>

          {error && (
            <div className="alert" role="alert">
              {error}
            </div>
          )}

          <label>
            Email
            <input
              type="email"
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </label>
          <label>
            Password
            <input
              type="password"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </label>

          <button type="submit" disabled={submitting}>
            {submitting ? 'Memeriksa…' : 'Masuk'}
          </button>
        </form>
      </div>
    </div>
  )
}
