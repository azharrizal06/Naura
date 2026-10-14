import { Navigate, Outlet } from 'react-router-dom'
import { useAuth } from '@/auth/AuthContext'
import type { UserRole } from '@/types'

/**
 * Lindungi rute dashboard. `roles` membatasi role yang diizinkan.
 * Dashboard hanya untuk Admin & Owner.
 */
export function ProtectedRoute({ roles }: { roles?: UserRole[] }) {
  const { user, loading } = useAuth()

  if (loading) {
    return <div className="center-screen">Memuat…</div>
  }

  if (!user) {
    return <Navigate to="/login" replace />
  }

  // Customer tidak boleh masuk dashboard.
  if (!['admin', 'owner'].includes(user.role)) {
    return <div className="center-screen">Akun Customer tidak memiliki akses dashboard.</div>
  }

  if (roles && !roles.includes(user.role)) {
    return <Navigate to="/" replace />
  }

  return <Outlet />
}
