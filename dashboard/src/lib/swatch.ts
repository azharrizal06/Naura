/**
 * Kosakata warna busana muslimah → warna kain.
 * Dipakai untuk menampilkan swatch dari nama varian ("Mocca / L", "Dusty Pink").
 * Salinan tabel ini juga ada di mobile/lib/utils/swatch.dart — jaga tetap sama.
 */
export const FABRIC_COLORS: Record<string, string> = {
  'broken white': '#EEE8DC',
  'dusty pink': '#D2A3A3',
  'dusty blue': '#8EA3B8',
  'cokelat susu': '#B08A6E',
  hitam: '#1F1A20',
  putih: '#FAF9F6',
  abu: '#9C9AA1',
  navy: '#24304F',
  maroon: '#6C1F2B',
  marun: '#6C1F2B',
  mocca: '#A07E62',
  milo: '#8A6A57',
  coksu: '#B08A6E',
  cokelat: '#6A4834',
  coklat: '#6A4834',
  taro: '#B6A2C8',
  lilac: '#C7B5DC',
  lavender: '#C9C0E3',
  sage: '#A2B299',
  army: '#5A5D3B',
  olive: '#76743F',
  mustard: '#C89E39',
  emerald: '#2E6D59',
  tosca: '#3D9A98',
  mint: '#BEDACA',
  biru: '#3C69A6',
  denim: '#4E698B',
  merah: '#B03838',
  salem: '#E6A48E',
  peach: '#EFBE9F',
  nude: '#D8B89F',
  krem: '#E9DEC7',
  cream: '#E9DEC7',
  khaki: '#BEAE83',
  ungu: '#6B4989',
  hijau: '#4D7949',
  kuning: '#E2BF4A',
  oranye: '#D8783A',
  terracotta: '#B45F3E',
}

const KEYS = Object.keys(FABRIC_COLORS).sort((a, b) => b.length - a.length)

export interface Swatch {
  label: string
  hex: string
}

/** Cari warna pertama yang disebut dalam nama varian; null jika tidak ada. */
export function swatchFor(variantName: string): Swatch | null {
  const lower = variantName.toLowerCase()
  const key = KEYS.find((k) => lower.includes(k))
  return key ? { label: key, hex: FABRIC_COLORS[key] } : null
}

/** Bagian warna dari "Mocca / L" → "Mocca". */
export function colorPart(variantName: string): string {
  return variantName.split('/')[0].trim()
}
