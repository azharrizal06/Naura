import { NavLink, Outlet, useNavigate } from 'react-router-dom'
import { useAuth } from '@/auth/AuthContext'

export function DashboardLayout() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  async function handleLogout() {
    await logout()
    navigate('/login')
  }

  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="wordmark">naura</div>
        <nav aria-label="Menu utama">
          <NavLink to="/" end>
            Ringkasan
          </NavLink>
          <NavLink to="/products">Produk</NavLink>
          <NavLink to="/categories">Kategori</NavLink>
          <NavLink to="/orders">Pesanan</NavLink>
          {user?.role === 'owner' && <NavLink to="/reports">Laporan</NavLink>}
          {user?.role === 'owner' && <NavLink to="/settings">Pengaturan</NavLink>}
        </nav>
        <div className="sidebar-user">
          <span>
            <strong>{user?.name}</strong>
            {user?.role_label}
          </span>
          <button onClick={handleLogout}>Keluar</button>
        </div>
      </aside>

      <main className="content">
        <Outlet />
      </main>
    </div>
  )
}
