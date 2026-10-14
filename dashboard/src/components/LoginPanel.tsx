// Warna yang dijual toko, dari gelap ke terang — tampil sebagai gulungan kain.
const BOLTS = ['#6C1F2B', '#A07E62', '#D2A3A3', '#B6A2C8', '#A2B299', '#5A5D3B', '#24304F', '#EEE8DC']
const BOLT_HEIGHTS = [78, 100, 64, 88, 72, 94, 58, 82]

/** Panel kiri halaman masuk & lupa password. */
export function LoginPanel() {
  return (
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
  )
}
