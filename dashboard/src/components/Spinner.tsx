export function Spinner({ label = 'Memuat…' }: { label?: string }) {
  return <div className="muted" style={{ padding: '1rem 0' }}>{label}</div>
}
