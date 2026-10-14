const rupiah = new Intl.NumberFormat('id-ID', {
  style: 'currency',
  currency: 'IDR',
  maximumFractionDigits: 0,
})

export function formatRupiah(value: number): string {
  return rupiah.format(value)
}

const dateTime = new Intl.DateTimeFormat('id-ID', {
  day: 'numeric',
  month: 'short',
  year: 'numeric',
  hour: '2-digit',
  minute: '2-digit',
})

/** "14 Okt 2026, 10.00" — waktu lokal browser. */
export function formatDateTime(iso: string): string {
  return dateTime.format(new Date(iso))
}
