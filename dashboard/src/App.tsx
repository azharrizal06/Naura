import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { AuthProvider } from '@/auth/AuthContext'
import { ServerWakeBanner } from '@/components/ServerWakeBanner'
import { ProtectedRoute } from '@/auth/ProtectedRoute'
import { DashboardLayout } from '@/layouts/DashboardLayout'
import { LoginPage } from '@/pages/LoginPage'
import { DashboardHome } from '@/pages/DashboardHome'
import { ProductsPage } from '@/pages/ProductsPage'
import { ProductDetailPage } from '@/pages/ProductDetailPage'
import { CategoriesPage } from '@/pages/CategoriesPage'
import { OrdersPage } from '@/pages/OrdersPage'
import { OrderDetailPage } from '@/pages/OrderDetailPage'
import { ReportsPage } from '@/pages/ReportsPage'
import { AdminsPage } from '@/pages/AdminsPage'
import { SettingsPage } from '@/pages/SettingsPage'
import { ForgotPasswordPage } from '@/pages/ForgotPasswordPage'
import { ProfilePage } from '@/pages/ProfilePage'

export default function App() {
  return (
    <AuthProvider>
      <ServerWakeBanner />
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/forgot-password" element={<ForgotPasswordPage />} />

          {/* Admin & Owner */}
          <Route element={<ProtectedRoute />}>
            <Route element={<DashboardLayout />}>
              <Route path="/" element={<DashboardHome />} />
              <Route path="/products" element={<ProductsPage />} />
              <Route path="/products/:id" element={<ProductDetailPage />} />
              <Route path="/categories" element={<CategoriesPage />} />
              <Route path="/orders" element={<OrdersPage />} />
              <Route path="/orders/:id" element={<OrderDetailPage />} />
              <Route path="/profile" element={<ProfilePage />} />
            </Route>
          </Route>

          {/* Khusus Owner */}
          <Route element={<ProtectedRoute roles={['owner']} />}>
            <Route element={<DashboardLayout />}>
              <Route path="/reports" element={<ReportsPage />} />
              <Route path="/admins" element={<AdminsPage />} />
              <Route path="/settings" element={<SettingsPage />} />
            </Route>
          </Route>

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}
