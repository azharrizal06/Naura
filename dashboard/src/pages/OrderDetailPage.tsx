import { useEffect, useState, type FormEvent } from 'react'
import { Link, useParams } from 'react-router-dom'
import { apiErrorMessage } from '@/lib/api'
import { Modal } from '@/components/Modal'
import { Spinner } from '@/components/Spinner'
import { Thumb } from '@/components/Swatch'
import { OrderStatusBadge } from '@/components/OrderStatusBadge'
import { formatDateTime, formatRupiah } from '@/lib/format'
import {
  cancelOrder,
  completeOrder,
  confirmPayment,
  fetchOrder,
  processOrder,
  shipOrder,
} from '@/lib/orders'
import type { Order } from '@/types'

function courierLabel(order: Order): string {
  const s = order.shipment
  if (!s?.courier) return '–'
  return [s.courier.toUpperCase(), s.service].filter(Boolean).join(' ')
}

export function OrderDetailPage() {
  const { id } = useParams<{ id: string }>()
  const orderId = Number(id)
  const [order, setOrder] = useState<Order | null>(null)
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [dialog, setDialog] = useState<'pay' | 'ship' | null>(null)

  useEffect(() => {
    setLoading(true)
    fetchOrder(orderId)
      .then(setOrder)
      .catch(() => setOrder(null))
      .finally(() => setLoading(false))
  }, [orderId])

  /** Jalankan aksi status; berhasil → tampilkan pesanan terbaru dari server. */
  async function run(action: () => Promise<Order>, fallback: string): Promise<boolean> {
    setBusy(true)
    setError(null)
    try {
      setOrder(await action())
      return true
    } catch (err) {
      setError(apiErrorMessage(err, fallback))
      return false
    } finally {
      setBusy(false)
    }
  }

  async function handleCancel() {
    if (!order) return
    const paid = order.status !== 'pending'
    const note = paid ? '\n\nPembayaran sudah diterima — kembalikan dana ke customer secara manual.' : ''
    if (!confirm(`Batalkan pesanan ${order.order_number}? Stok barang dikembalikan.${note}`)) return
    await run(() => cancelOrder(order.id), 'Pesanan tidak bisa dibatalkan.')
  }

  if (loading) return <Spinner />
  if (!order)
    return (
      <div className="placeholder">
        Pesanan tidak ditemukan. <Link to="/orders">Kembali ke daftar pesanan</Link>
      </div>
    )

  const a = order.shipping_address
  const bank = order.payment?.bank
  const canCancel = ['pending', 'paid', 'processing'].includes(order.status)

  return (
    <div>
      <div className="breadcrumb">
        <Link to="/orders">Pesanan</Link>
      </div>

      <div className="page-header">
        <div>
          <h2>{order.order_number}</h2>
          <p className="muted">Dipesan {formatDateTime(order.created_at)}</p>
        </div>
        <OrderStatusBadge status={order.status} />
      </div>

      <dl className="facts">
        <div>
          <dt>Customer</dt>
          <dd>{order.customer?.name ?? '–'}</dd>
        </div>
        <div>
          <dt>Total bayar</dt>
          <dd>{formatRupiah(order.total)}</dd>
        </div>
        <div>
          <dt>Transfer ke</dt>
          <dd>{bank ? `${bank.bank} ${bank.number}` : '–'}</dd>
        </div>
        <div>
          <dt>Kurir</dt>
          <dd>{courierLabel(order)}</dd>
        </div>
      </dl>

      {error && (
        <div className="alert" style={{ marginTop: '1.25rem' }}>
          {error}
        </div>
      )}

      <OrderActions
        order={order}
        busy={busy}
        canCancel={canCancel}
        onPay={() => setDialog('pay')}
        onProcess={() => run(() => processOrder(order.id), 'Pesanan tidak bisa diproses.')}
        onShip={() => setDialog('ship')}
        onComplete={() => {
          if (confirm('Tandai pesanan selesai? Lakukan ini bila paket sudah diterima customer.')) {
            void run(() => completeOrder(order.id), 'Pesanan tidak bisa diselesaikan.')
          }
        }}
        onCancel={handleCancel}
      />

      <div className="section-header">
        <h3>Barang</h3>
      </div>
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Produk</th>
              <th className="num">Harga</th>
              <th className="num">Jumlah</th>
              <th className="num">Subtotal</th>
            </tr>
          </thead>
          <tbody>
            {order.items.map((i) => (
              <tr key={i.id}>
                <td>
                  <div className="product-cell">
                    <Thumb src={i.product?.primary_image} />
                    <div>
                      <strong>{i.product_name}</strong>
                      <div className="muted">{i.variant_name}</div>
                    </div>
                  </div>
                </td>
                <td className="num">{formatRupiah(i.unit_price)}</td>
                <td className="num">{i.quantity}</td>
                <td className="num">{formatRupiah(i.subtotal)}</td>
              </tr>
            ))}
          </tbody>
          <tbody className="totals">
            <tr>
              <td colSpan={3} className="num muted">
                Subtotal
              </td>
              <td className="num">{formatRupiah(order.subtotal)}</td>
            </tr>
            <tr>
              <td colSpan={3} className="num muted">
                Ongkos kirim ({courierLabel(order)})
              </td>
              <td className="num">{formatRupiah(order.shipping_cost)}</td>
            </tr>
            {order.discount > 0 && (
              <tr>
                <td colSpan={3} className="num muted">
                  Potongan
                </td>
                <td className="num">-{formatRupiah(order.discount)}</td>
              </tr>
            )}
            <tr className="grand">
              <td colSpan={3} className="num">
                Total
              </td>
              <td className="num">{formatRupiah(order.total)}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div className="order-grid">
        <div>
          <div className="section-header">
            <h3>Dikirim ke</h3>
          </div>
          <address>
            <strong>{a.recipient_name}</strong>
            <br />
            {a.phone}
            <br />
            {a.address_line}
            <br />
            {[a.subdistrict, a.district, a.city, a.province, a.postal_code].filter(Boolean).join(', ')}
          </address>
          {order.customer && (
            <p className="muted" style={{ fontSize: '0.88rem' }}>
              Akun: {order.customer.email}
              {order.customer.phone ? ` · ${order.customer.phone}` : ''}
            </p>
          )}
          {order.notes && (
            <>
              <div className="section-header">
                <h3>Catatan customer</h3>
              </div>
              <p className="description">{order.notes}</p>
            </>
          )}
        </div>

        <div>
          <div className="section-header">
            <h3>Riwayat</h3>
          </div>
          <Timeline order={order} />
        </div>
      </div>

      {dialog === 'pay' && (
        <Modal title="Konfirmasi pembayaran" onClose={() => setDialog(null)}>
          <div className="form">
            <p style={{ margin: 0 }}>
              Pastikan transfer <strong>{formatRupiah(order.payment?.amount ?? order.total)}</strong> sudah masuk ke
              rekening <strong>{bank ? `${bank.bank} ${bank.number} a.n. ${bank.holder}` : 'toko'}</strong>.
            </p>
            <div className="form-actions">
              <button type="button" className="ghost" onClick={() => setDialog(null)}>
                Belum
              </button>
              <button
                type="button"
                disabled={busy}
                onClick={async () => {
                  if (await run(() => confirmPayment(order.id), 'Pembayaran tidak bisa dikonfirmasi.')) setDialog(null)
                }}
              >
                {busy ? 'Menyimpan…' : 'Ya, transfer sudah masuk'}
              </button>
            </div>
          </div>
        </Modal>
      )}

      {dialog === 'ship' && (
        <ShipDialog
          order={order}
          onClose={() => setDialog(null)}
          onShip={async (tracking, courier) => {
            if (await run(() => shipOrder(order.id, tracking, courier), 'Pesanan tidak bisa dikirim.')) setDialog(null)
          }}
          busy={busy}
          error={error}
        />
      )}
    </div>
  )
}

function OrderActions(props: {
  order: Order
  busy: boolean
  canCancel: boolean
  onPay: () => void
  onProcess: () => void
  onShip: () => void
  onComplete: () => void
  onCancel: () => void
}) {
  const { order, busy, canCancel } = props
  let text: string
  let primary: { label: string; onClick: () => void } | null = null

  switch (order.status) {
    case 'pending':
      text = 'Menunggu transfer dari customer. Cocokkan mutasi rekening sebelum konfirmasi.'
      primary = { label: 'Konfirmasi pembayaran', onClick: props.onPay }
      break
    case 'paid':
      text = 'Pembayaran diterima. Siapkan dan kemas barang.'
      primary = { label: 'Mulai proses', onClick: props.onProcess }
      break
    case 'processing':
      text = 'Barang sedang disiapkan. Isi nomor resi setelah paket diserahkan ke kurir.'
      primary = { label: 'Input resi & kirim', onClick: props.onShip }
      break
    case 'shipped':
      text = 'Paket dalam perjalanan. Customer bisa menandai diterima dari aplikasi.'
      primary = { label: 'Tandai selesai', onClick: props.onComplete }
      break
    case 'completed':
      text = 'Pesanan selesai.'
      break
    case 'cancelled':
      text = 'Pesanan dibatalkan dan stoknya sudah dikembalikan.'
      break
  }

  return (
    <div className="order-actions">
      <p>{text}</p>
      {primary && (
        <button type="button" disabled={busy} onClick={primary.onClick}>
          {primary.label}
        </button>
      )}
      {canCancel && (
        <button type="button" className="ghost danger" disabled={busy} onClick={props.onCancel}>
          Batalkan pesanan
        </button>
      )}
    </div>
  )
}

function ShipDialog(props: {
  order: Order
  busy: boolean
  error: string | null
  onClose: () => void
  onShip: (tracking: string, courier: string) => void
}) {
  const [tracking, setTracking] = useState('')
  const [courier, setCourier] = useState(props.order.shipment?.courier ?? '')

  function handleSubmit(e: FormEvent) {
    e.preventDefault()
    props.onShip(tracking.trim(), courier.trim())
  }

  return (
    <Modal title="Kirim pesanan" onClose={props.onClose}>
      <form className="form" onSubmit={handleSubmit}>
        {props.error && <div className="alert">{props.error}</div>}
        <label>
          Nomor resi
          <input value={tracking} onChange={(e) => setTracking(e.target.value)} required autoFocus />
        </label>
        <label>
          Kode kurir
          <input value={courier} onChange={(e) => setCourier(e.target.value)} placeholder="mis. jne, jnt" />
        </label>
        <p className="muted" style={{ margin: 0, fontSize: '0.85rem' }}>
          Pilihan customer: {courierLabel(props.order)}. Ubah hanya bila paket diserahkan ke kurir lain.
        </p>
        <div className="form-actions">
          <button type="button" className="ghost" onClick={props.onClose}>
            Batal
          </button>
          <button type="submit" disabled={props.busy || !tracking.trim()}>
            {props.busy ? 'Menyimpan…' : 'Simpan & tandai dikirim'}
          </button>
        </div>
      </form>
    </Modal>
  )
}

function Timeline({ order }: { order: Order }) {
  const steps: { label: string; at: string | null | undefined }[] = [
    { label: 'Pesanan dibuat', at: order.created_at },
    { label: 'Pembayaran dikonfirmasi', at: order.payment?.paid_at },
    {
      label: order.shipment?.tracking_number ? `Dikirim · resi ${order.shipment.tracking_number}` : 'Dikirim',
      at: order.shipment?.shipped_at,
    },
    { label: 'Diterima', at: order.shipment?.delivered_at },
  ]

  return (
    <ol className="timeline">
      {steps.map((s) => (
        <li key={s.label} className={s.at ? undefined : 'todo'}>
          <span>{s.label}</span>
          <span className="muted">{s.at ? formatDateTime(s.at) : '–'}</span>
        </li>
      ))}
      {order.status === 'cancelled' && (
        <li>
          <span style={{ color: 'var(--marun)' }}>Dibatalkan</span>
          <span />
        </li>
      )}
    </ol>
  )
}
