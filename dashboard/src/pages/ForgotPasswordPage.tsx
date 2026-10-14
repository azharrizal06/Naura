import { useState, type FormEvent } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { LoginPanel } from '@/components/LoginPanel'
import { requestResetCode, resetPassword } from '@/lib/account'
import { apiErrorMessage } from '@/lib/api'

type Step = 'email' | 'code' | 'done'

/** Lupa password: email → kode 6 digit + password baru → masuk lagi. */
export function ForgotPasswordPage() {
  const [params] = useSearchParams()
  const navigate = useNavigate()
  const [step, setStep] = useState<Step>('email')
  const [email, setEmail] = useState(params.get('email') ?? '')
  const [code, setCode] = useState('')
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [info, setInfo] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  async function run(action: () => Promise<unknown>, fallback: string): Promise<boolean> {
    setBusy(true)
    setError(null)
    try {
      await action()
      return true
    } catch (err) {
      setError(apiErrorMessage(err, fallback))
      return false
    } finally {
      setBusy(false)
    }
  }

  async function handleEmail(e: FormEvent) {
    e.preventDefault()
    setInfo(null)
    const normalized = email.trim().toLowerCase()
    setEmail(normalized)
    if (await run(() => requestResetCode(normalized), 'Kode tidak bisa dikirim. Coba lagi.')) setStep('code')
  }

  async function handleResend() {
    setInfo(null)
    if (await run(() => requestResetCode(email), 'Kode tidak bisa dikirim. Coba lagi.')) {
      setInfo('Kode baru sudah dikirim. Kode sebelumnya tidak berlaku lagi.')
    }
  }

  async function handleReset(e: FormEvent) {
    e.preventDefault()
    setInfo(null)
    if (password !== confirm) {
      setError('Password baru dan ulangannya tidak sama.')
      return
    }
    if (await run(() => resetPassword(email, code.trim(), password), 'Password tidak bisa diganti. Coba lagi.')) {
      setStep('done')
    }
  }

  return (
    <div className="login">
      <LoginPanel />

      <div className="login-form-wrap">
        {step === 'email' && (
          <form className="login-form" onSubmit={handleEmail}>
            <h1>Lupa password</h1>
            <p className="muted" style={{ margin: 0 }}>
              Masukkan email akun Anda. Kami kirim kode 6 digit untuk membuat password baru.
            </p>
            {error && (
              <div className="alert" role="alert">
                {error}
              </div>
            )}
            <label>
              Email
              <input type="email" autoComplete="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
            </label>
            <button type="submit" disabled={busy}>
              {busy ? 'Mengirim…' : 'Kirim kode'}
            </button>
            <Link className="btn-link" to="/login">
              Kembali ke halaman masuk
            </Link>
          </form>
        )}

        {step === 'code' && (
          <form className="login-form" onSubmit={handleReset}>
            <h1>Masukkan kode</h1>
            <p className="muted" style={{ margin: 0 }}>
              Bila <strong>{email}</strong> terdaftar, kode sudah dikirim ke email tersebut. Kode berlaku 15 menit.
            </p>
            {error && (
              <div className="alert" role="alert">
                {error}
              </div>
            )}
            {info && <p className="status status-on" style={{ margin: 0 }}>{info}</p>}
            <label>
              Kode 6 digit
              <input
                inputMode="numeric"
                autoComplete="one-time-code"
                pattern="\d{6}"
                maxLength={6}
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, ''))}
                required
              />
            </label>
            <label>
              Password baru
              <input
                type="password"
                autoComplete="new-password"
                minLength={8}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Minimal 8 karakter"
                required
              />
            </label>
            <label>
              Ulangi password baru
              <input
                type="password"
                autoComplete="new-password"
                value={confirm}
                onChange={(e) => setConfirm(e.target.value)}
                required
              />
            </label>
            <button type="submit" disabled={busy}>
              {busy ? 'Menyimpan…' : 'Simpan password baru'}
            </button>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <button type="button" className="ghost" disabled={busy} onClick={() => setStep('email')}>
                Ganti email
              </button>
              <button type="button" className="ghost" disabled={busy} onClick={handleResend}>
                Kirim ulang kode
              </button>
            </div>
          </form>
        )}

        {step === 'done' && (
          <div className="login-form">
            <h1>Password diganti</h1>
            <p className="muted" style={{ margin: 0 }}>
              Silakan masuk dengan password baru. Sesi lain yang memakai password lama sudah dikeluarkan.
            </p>
            <button type="button" onClick={() => navigate('/login')}>
              Masuk
            </button>
          </div>
        )}
      </div>
    </div>
  )
}
