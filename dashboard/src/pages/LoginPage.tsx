import { useState, type FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { AxiosError } from 'axios'
import { useAuth } from '@/auth/AuthContext'
import { LoginPanel } from '@/components/LoginPanel'
import type { ApiError } from '@/types'

const DEMO = import.meta.env.VITE_DEMO_MODE === 'true'
// Terisi otomatis hanya saat development atau demo.
const PREFILL = import.meta.env.DEV || DEMO

export function LoginPage() {
  const { login } = useAuth()
  const navigate = useNavigate()
  const [email, setEmail] = useState(PREFILL ? 'admin@naura.test' : '')
  const [password, setPassword] = useState(PREFILL ? 'password' : '')
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
      <LoginPanel />

      <div className="login-form-wrap">
        <form className="login-form" onSubmit={handleSubmit}>
          <h1>Masuk</h1>
          <p className="muted" style={{ margin: 0 }}>
            Untuk admin dan pemilik toko.
          </p>

          {DEMO && (
            <div className="demo-accounts">
              Versi demo dengan data toko contoh. Password semua akun: <strong>password</strong>
              <div>
                {[
                  ['Masuk sebagai Owner', 'owner@naura.test'],
                  ['Masuk sebagai Admin', 'admin@naura.test'],
                ].map(([label, demoEmail]) => (
                  <button
                    key={demoEmail}
                    type="button"
                    className="ghost"
                    onClick={() => {
                      setEmail(demoEmail)
                      setPassword('password')
                    }}
                  >
                    {label}
                  </button>
                ))}
              </div>
            </div>
          )}

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
          <Link className="btn-link" to={`/forgot-password?email=${encodeURIComponent(email)}`}>
            Lupa password?
          </Link>
        </form>
      </div>
    </div>
  )
}
