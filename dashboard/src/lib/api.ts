import axios, { type AxiosError } from 'axios'
import type { ApiError } from '@/types'

const TOKEN_KEY = 'naura_token'

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000/api',
  headers: {
    Accept: 'application/json',
  },
})

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY)
}

export function setToken(token: string | null): void {
  if (token) {
    localStorage.setItem(TOKEN_KEY, token)
  } else {
    localStorage.removeItem(TOKEN_KEY)
  }
}

// Sisipkan Bearer token otomatis.
api.interceptors.request.use((config) => {
  const token = getToken()
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Jika 401, bersihkan token (sesi kedaluwarsa).
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      setToken(null)
    }
    return Promise.reject(error)
  },
)

/** Pesan untuk ditampilkan dari error API: pesan field pertama (422), lalu `message`. */
export function apiErrorMessage(err: unknown, fallback: string): string {
  const data = (err as AxiosError<ApiError>).response?.data
  const field = data?.errors ? Object.values(data.errors)[0]?.[0] : undefined
  return field ?? data?.message ?? fallback
}

// --- Server tidur (hosting gratis): banner "sedang dinyalakan" + coba ulang GET ---

const SLOW_AFTER_MS = 4000
const RETRY_DELAY_MS = 3000
const MAX_RETRIES = 5

let pending = 0
let slowTimer: ReturnType<typeof setTimeout> | undefined
let waking = false
const listeners = new Set<() => void>()

function setWaking(next: boolean) {
  if (waking === next) return
  waking = next
  listeners.forEach((l) => l())
}

/** Untuk useSyncExternalStore: apakah ada permintaan yang lambat (server kemungkinan sedang bangun). */
export const serverWaking = {
  subscribe(listener: () => void) {
    listeners.add(listener)
    return () => listeners.delete(listener)
  },
  get: () => waking,
}

function started() {
  pending++
  if (pending === 1) slowTimer = setTimeout(() => setWaking(true), SLOW_AFTER_MS)
}

function finished() {
  pending = Math.max(0, pending - 1)
  if (pending === 0) {
    clearTimeout(slowTimer)
    setWaking(false)
  }
}

/** Server belum siap: tanpa respons (jaringan) atau 502/503/504 dari proxy. */
function isWakeError(error: AxiosError): boolean {
  const status = error.response?.status
  return !error.response || status === 502 || status === 503 || status === 504
}

api.interceptors.request.use((config) => {
  started()
  return config
})

api.interceptors.response.use(
  (response) => {
    finished()
    return response
  },
  async (error: AxiosError) => {
    const config = error.config as (typeof error.config & { _retries?: number }) | undefined
    // Hanya permintaan baca yang aman diulang.
    if (config && config.method === 'get' && isWakeError(error) && (config._retries ?? 0) < MAX_RETRIES) {
      config._retries = (config._retries ?? 0) + 1
      setWaking(true)
      await new Promise((r) => setTimeout(r, RETRY_DELAY_MS))
      finished()
      return api.request(config)
    }
    finished()
    return Promise.reject(error)
  },
)
