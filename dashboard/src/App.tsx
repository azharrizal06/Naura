import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { AuthProvider } from '@/auth/AuthContext'
import { ProtectedRoute } from '@/auth/ProtectedRoute'
import { DashboardLayout } from '@/layouts/DashboardLayout'
import { LoginPage } from '@/pages/LoginPage'
import { DashboardHome } from '@/pages/DashboardHome'
import { PlaceholderPage } from '@/pages/PlaceholderPage'
import { ProductsPage } from '@/pages/ProductsPage'
import { ProductDetailPage } from '@/pages/ProductDetailPage'
import { CategoriesPage } from '@/pages/CategoriesPage'

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />

          {/* Admin & Owner */}
          <Route element={<ProtectedRoute />}>
            <Route element={<DashboardLayout />}>
              <Route path="/" element={<DashboardHome />} />
              <Route path="/products" element={<ProductsPage />} />
              <Route path="/products/:id" element={<ProductDetailPage />} />
              <Route path="/categories" element={<CategoriesPage />} />
              <Route path="/orders" element={<PlaceholderPage title="Pesanan" phase="Fase 4 & 5" />} />
            </Route>
          </Route>

          {/* Khusus Owner */}
          <Route element={<ProtectedRoute roles={['owner']} />}>
            <Route element={<DashboardLayout />}>
              <Route path="/reports" element={<PlaceholderPage title="Laporan & Omzet" phase="Fase 6" />} />
              <Route path="/settings" element={<PlaceholderPage title="Pengaturan Toko" phase="Fase 6" />} />
            </Route>
          </Route>

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}
