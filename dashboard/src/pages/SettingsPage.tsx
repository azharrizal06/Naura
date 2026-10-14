import { useEffect, useState, type FormEvent } from 'react'
import { Spinner } from '@/components/Spinner'
import { apiErrorMessage } from '@/lib/api'
import { fetchSettings, updateSettings, type SettingsPayload } from '@/lib/owner'
import type { BankAccount, OwnerSettings } from '@/types'

const emptyBank: BankAccount = { bank: '', number: '', holder: '' }

export function SettingsPage() {
  const [settings, setSettings] = useState<OwnerSettings | null>(null)
  const [form, setForm] = useState<SettingsPayload | null>(null)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [saved, setSaved] = useState(false)
  const [saving, setSaving] = useState(false)

  function fill(s: OwnerSettings) {
    setSettings(s)
    setForm({
      store_name: s.store_name,
      store_email: s.store_email ?? '',
      store_phone: s.store_phone ?? '',
      store_address: s.store_address ?? '',
      flat_shipping_cost: s.flat_shipping_cost,
      bank_accounts: s.bank_accounts,
    })
  }

  useEffect(() => {
    fetchSettings()
      .then(fill)
      .catch((err) => setLoadError(apiErrorMessage(err, 'Pengaturan tidak bisa dimuat.')))
  }, [])

  if (loadError) return <div className="alert">{loadError}</div>
  if (!form || !settings) return <Spinner />

  const set = (patch: Partial<SettingsPayload>) => {
    setSaved(false)
    setForm({ ...form, ...patch })
  }
  const setBank = (i: number, patch: Partial<BankAccount>) =>
    set({ bank_accounts: form.bank_accounts.map((b, j) => (j === i ? { ...b, ...patch } : b)) })

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    if (!form) return
    setSaving(true)
    setError(null)
    try {
      fill(
        await updateSettings({
          ...form,
          store_email: form.store_email || null,
          store_phone: form.store_phone || null,
          store_address: form.store_address || null,
        }),
      )
      setSaved(true)
    } catch (err) {
      setError(apiErrorMessage(err, 'Pengaturan tidak bisa disimpan.'))
    } finally {
      setSaving(false)
    }
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h2>Pengaturan Toko</h2>
          <p className="muted">Info toko dan rekening transfer yang tampil di aplikasi customer.</p>
        </div>
      </div>

      <form className="form settings-form" onSubmit={handleSubmit}>
        {error && <div className="alert">{error}</div>}

        <div className="section-header">
          <h3>Info toko</h3>
        </div>
        <label>
          Nama toko
          <input value={form.store_name} onChange={(e) => set({ store_name: e.target.value })} required />
        </label>
        <div className="form-row">
          <label>
            Email layanan
            <input
              type="email"
              value={form.store_email ?? ''}
              onChange={(e) => set({ store_email: e.target.value })}
            />
          </label>
          <label>
            Telepon / WhatsApp
            <input value={form.store_phone ?? ''} onChange={(e) => set({ store_phone: e.target.value })} />
          </label>
        </div>
        <label>
          Alamat toko
          <textarea
            rows={2}
            value={form.store_address ?? ''}
            onChange={(e) => set({ store_address: e.target.value })}
          />
        </label>

        <div className="section-header">
          <h3>Rekening transfer</h3>
          <button
            type="button"
            className="ghost"
            onClick={() => set({ bank_accounts: [...form.bank_accounts, { ...emptyBank }] })}
          >
            Tambah rekening
          </button>
        </div>
        <p className="muted" style={{ margin: 0, fontSize: '0.88rem' }}>
          Langsung tampil di checkout aplikasi setelah disimpan. Pesanan lama tetap memakai rekening yang dipilih saat itu.
        </p>
        {form.bank_accounts.length === 0 && (
          <div className="alert">Belum ada rekening — customer tidak bisa membuat pesanan sampai rekening ditambahkan.</div>
        )}
        {form.bank_accounts.map((b, i) => (
          <fieldset key={i} className="bank-row">
            <legend className="sr-only">Rekening {i + 1}</legend>
            <label>
              Bank
              <input value={b.bank} onChange={(e) => setBank(i, { bank: e.target.value })} placeholder="BCA" required />
            </label>
            <label>
              Nomor rekening
              <input
                inputMode="numeric"
                value={b.number}
                onChange={(e) => setBank(i, { number: e.target.value.replace(/\D/g, '') })}
                required
              />
            </label>
            <label>
              Atas nama
              <input value={b.holder} onChange={(e) => setBank(i, { holder: e.target.value })} required />
            </label>
            <button
              type="button"
              className="ghost danger"
              aria-label={`Hapus rekening ${b.bank || i + 1}`}
              onClick={() => set({ bank_accounts: form.bank_accounts.filter((_, j) => j !== i) })}
            >
              Hapus
            </button>
          </fieldset>
        ))}

        <div className="section-header">
          <h3>Pengiriman</h3>
        </div>
        <label style={{ maxWidth: 260 }}>
          Ongkir flat (Rp)
          <input
            type="number"
            min={0}
            step={500}
            value={form.flat_shipping_cost}
            onChange={(e) => set({ flat_shipping_cost: Number(e.target.value) })}
            required
          />
        </label>
        <p className="muted" style={{ margin: 0, fontSize: '0.88rem' }}>
          Dipakai sebagai "Kurir toko" bila ongkir RajaOngkir tidak aktif. Lokasi asal ongkir:{' '}
          <strong>{settings.shipping_origin_label ?? 'belum diatur'}</strong> — diubah lewat perintah{' '}
          <code>php artisan store:shipping-origin</code>.
        </p>

        <div className="form-actions" style={{ justifyContent: 'flex-start' }}>
          <button type="submit" disabled={saving}>
            {saving ? 'Menyimpan…' : 'Simpan pengaturan'}
          </button>
          {saved && <span className="status status-on">Tersimpan</span>}
        </div>
      </form>
    </div>
  )
}
