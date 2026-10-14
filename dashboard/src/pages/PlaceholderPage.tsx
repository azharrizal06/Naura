export function PlaceholderPage({ title, phase }: { title: string; phase: string }) {
  return (
    <div>
      <h2>{title}</h2>
      <div className="placeholder">
        <p className="muted" style={{ margin: 0 }}>
          Halaman ini belum bisa dipakai. Modulnya dikerjakan pada {phase}.
        </p>
      </div>
    </div>
  )
}
