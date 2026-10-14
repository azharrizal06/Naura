import { api } from '@/lib/api'
import type { User } from '@/types'

// --- Lupa password (kode 6 digit via email) ---

/** Server selalu menjawab sama, email terdaftar atau tidak. */
export async function requestResetCode(email: string): Promise<string> {
  const res = await api.post<{ message: string }>('/auth/forgot-password', { email })
  return res.data.message
}

export async function resetPassword(email: string, code: string, password: string): Promise<string> {
  const res = await api.post<{ message: string }>('/auth/reset-password', {
    email,
    code,
    password,
    password_confirmation: password,
  })
  return res.data.message
}

// --- Profil & password sendiri ---

export interface ProfilePayload {
  name: string
  phone: string | null
  email: string
  /** Wajib bila email diganti. */
  current_password?: string
}

export async function updateProfile(payload: ProfilePayload): Promise<User> {
  const res = await api.patch<{ data: User }>('/auth/profile', payload)
  return res.data.data
}

export async function changePassword(current_password: string, password: string): Promise<string> {
  const res = await api.put<{ message: string }>('/auth/password', {
    current_password,
    password,
    password_confirmation: password,
  })
  return res.data.message
}
