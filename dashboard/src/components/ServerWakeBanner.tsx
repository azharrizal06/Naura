import { useSyncExternalStore } from 'react'
import { serverWaking } from '@/lib/api'

/** Muncul bila permintaan ke server lambat — server gratis sedang bangun dari tidur. */
export function ServerWakeBanner() {
  const waking = useSyncExternalStore(serverWaking.subscribe, serverWaking.get)
  if (!waking) return null
  return (
    <div className="wake-banner" role="status">
      Server sedang dinyalakan… Bila toko lama tidak dikunjungi, ini butuh hingga satu menit. Halaman akan termuat
      otomatis.
    </div>
  )
}
