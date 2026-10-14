import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import { api, getToken, setToken } from '@/lib/api'
import type { LoginResponse, User } from '@/types'

interface AuthContextValue {
  user: User | null
  loading: boolean
  login: (email: string, password: string) => Promise<User>
  logout: () => Promise<void>
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  // Muat ulang sesi dari token yang tersimpan.
  useEffect(() => {
    const token = getToken()
    if (!token) {
      setLoading(false)
      return
    }
    api
      .get<{ data: User }>('/auth/me')
      .then((res) => setUser(res.data.data))
      .catch(() => setToken(null))
      .finally(() => setLoading(false))
  }, [])

  async function login(email: string, password: string): Promise<User> {
    const res = await api.post<LoginResponse>('/auth/login', {
      email,
      password,
      device_name: 'dashboard-web',
    })
    setToken(res.data.token)
    setUser(res.data.user)
    return res.data.user
  }

  async function logout(): Promise<void> {
    try {
      await api.post('/auth/logout')
    } finally {
      setToken(null)
      setUser(null)
    }
  }

  const value = useMemo(() => ({ user, loading, login, logout }), [user, loading])

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext)
  if (!ctx) {
    throw new Error('useAuth harus dipakai di dalam <AuthProvider>')
  }
  return ctx
}
