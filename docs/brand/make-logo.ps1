# Buat ulang aset logo dari docs/brand/logo-source.jpeg (lihat docs/brand/README.md).
param(
  [Parameter(Mandatory)] [string] $Source,
  [Parameter(Mandatory)] [string] $OutDir
)
# Hapus latar putih logo (un-blend dari putih), potong rapat, buat varian latar gelap & simbol.
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class Logo {
  static byte[] Read(Bitmap b, out BitmapData d) {
    d = b.LockBits(new Rectangle(0,0,b.Width,b.Height), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
    var px = new byte[d.Stride * b.Height]; Marshal.Copy(d.Scan0, px, 0, px.Length); return px;
  }
  static void Write(Bitmap b, BitmapData d, byte[] px) { Marshal.Copy(px, 0, d.Scan0, px.Length); b.UnlockBits(d); }

  // Piksel dianggap campuran warna asli + putih: alpha = jarak terbesar dari putih.
  public static Bitmap RemoveWhite(Bitmap src, double floor) {
    var b = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
    using (var g = Graphics.FromImage(b)) g.DrawImage(src, 0, 0, src.Width, src.Height);
    BitmapData d; var px = Read(b, out d);
    for (int i = 0; i < px.Length; i += 4) {
      double bl = px[i], gr = px[i+1], r = px[i+2];
      double a = Math.Max(Math.Max(255 - r, 255 - gr), 255 - bl) / 255.0;
      a = (a - floor) / (1 - floor);             // buang noise JPEG & bayangan tipis
      if (a <= 0) { px[i] = px[i+1] = px[i+2] = px[i+3] = 0; continue; }
      a = Math.Min(1, a);
      Func<double,byte> un = c => (byte)Math.Max(0, Math.Min(255, (c - 255 * (1 - a)) / a));
      px[i] = un(bl); px[i+1] = un(gr); px[i+2] = un(r); px[i+3] = (byte)Math.Round(a * 255);
    }
    Write(b, d, px); return b;
  }

  // Magenta (simbol hijab, kupu-kupu) cerah: R >= 120. Ungu "Naura" & merah tua "Fashion" gelap: R < 120.
  static bool IsMagenta(byte[] px, int i) { return px[i+2] >= 120; }

  // Teks gelap jadi putih untuk latar gelap; magenta tetap.
  public static Bitmap PurpleToWhite(Bitmap src) {
    var b = (Bitmap)src.Clone(); BitmapData d; var px = Read(b, out d);
    for (int i = 0; i < px.Length; i += 4) {
      if (px[i+3] == 0) continue;
      if (!IsMagenta(px, i)) { px[i] = px[i+1] = px[i+2] = 255; }
    }
    Write(b, d, px); return b;
  }

  // Area logo yang sudah dipotong (pecahan lebar/tinggi, diukur dari gambar ini):
  // simbol hijab di kiri; ekornya melengkung di bawah huruf "N"; kupu-kupu di kanan atas.
  // Magenta: R > B. Ungu "Naura" / batang "N": B > R.
  static bool Pinkish(byte[] px, int i) { return px[i+2] > px[i]; }

  public static bool InSymbol(byte[] px, int i, int x, int y, int w, int h) {
    if (x < w * 0.25) return true;                                   // tepi kiri simbol: utuh
    if (x < w * 0.34) return Pinkish(px, i);                         // kepala hijab; batang "N" ungu dibuang
    return x < w * 0.55 && y >= h * 0.78 && Pinkish(px, i);          // ekor di bawah huruf "N"
  }
  public static bool InButterfly(byte[] px, int i, int x, int y, int w, int h) {
    return x >= w * 0.86 && y < h * 0.36 && Pinkish(px, i);          // coretan ungu huruf "a" bukan kupu-kupu
  }

  // Varian latar gelap: simbol & kupu-kupu tetap, semua teks jadi putih.
  public static Bitmap ForDark(Bitmap src) {
    var b = (Bitmap)src.Clone(); BitmapData d; var px = Read(b, out d);
    for (int y = 0; y < b.Height; y++) for (int x = 0; x < b.Width; x++) {
      int i = y * d.Stride + x * 4;
      if (px[i+3] == 0 || InSymbol(px, i, x, y, b.Width, b.Height) || InButterfly(px, i, x, y, b.Width, b.Height)) continue;
      px[i] = px[i+1] = px[i+2] = 255;
    }
    Write(b, d, px); return b;
  }

  // Hanya simbol hijab; sisanya transparan.
  public static Bitmap SymbolOnly(Bitmap src) {
    var b = (Bitmap)src.Clone(); BitmapData d; var px = Read(b, out d);
    for (int y = 0; y < b.Height; y++) for (int x = 0; x < b.Width; x++) {
      int i = y * d.Stride + x * 4;
      if (!InSymbol(px, i, x, y, b.Width, b.Height)) { px[i] = px[i+1] = px[i+2] = px[i+3] = 0; }
    }
    Write(b, d, px); return b;
  }

  // Hanya piksel magenta (simbol & kupu-kupu); teks dibuat transparan.
  public static Bitmap MagentaOnly(Bitmap src) {
    var b = (Bitmap)src.Clone(); BitmapData d; var px = Read(b, out d);
    for (int i = 0; i < px.Length; i += 4) {
      if (px[i+3] != 0 && !IsMagenta(px, i)) { px[i] = px[i+1] = px[i+2] = px[i+3] = 0; }
    }
    Write(b, d, px); return b;
  }

  // Kotak pembatas piksel dengan alpha >= minA di dalam area [x0, x1).
  public static Rectangle Bounds(Bitmap b, int minA, int x0, int x1) {
    BitmapData d; var px = Read(b, out d);
    int l = int.MaxValue, t = int.MaxValue, rr = -1, bt = -1;
    for (int y = 0; y < b.Height; y++) for (int x = x0; x < Math.Min(x1, b.Width); x++) {
      if (px[y * d.Stride + x * 4 + 3] >= minA) { l = Math.Min(l, x); t = Math.Min(t, y); rr = Math.Max(rr, x); bt = Math.Max(bt, y); }
    }
    b.UnlockBits(d); return Rectangle.FromLTRB(l, t, rr + 1, bt + 1);
  }
}
"@

function Crop([System.Drawing.Bitmap] $b, [System.Drawing.Rectangle] $r, [int] $pad) {
  $r = [System.Drawing.Rectangle]::FromLTRB([Math]::Max(0, $r.Left - $pad), [Math]::Max(0, $r.Top - $pad),
    [Math]::Min($b.Width, $r.Right + $pad), [Math]::Min($b.Height, $r.Bottom + $pad))
  return $b.Clone($r, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
}

# Ikon persegi: simbol di tengah kotak berlatar [bg] (null = transparan).
function Square([System.Drawing.Bitmap] $sym, [int] $size, [double] $fill, $bg) {
  $out = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($out)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  if ($bg) { $g.Clear($bg) }
  $scale = [Math]::Min($size * $fill / $sym.Width, $size * $fill / $sym.Height)
  $w = [int]($sym.Width * $scale); $h = [int]($sym.Height * $scale)
  $g.DrawImage($sym, [int](($size - $w) / 2), [int](($size - $h) / 2), $w, $h)
  $g.Dispose(); return $out
}

New-Item -ItemType Directory -Force $OutDir | Out-Null
$src = [System.Drawing.Bitmap]::FromFile($Source)
$clean = [Logo]::RemoveWhite($src, 0.06)

$box = [Logo]::Bounds($clean, 40, 0, $clean.Width)
$logo = Crop $clean $box 6
$logo.Save("$OutDir\logo.png", [System.Drawing.Imaging.ImageFormat]::Png)
$light = [Logo]::ForDark($logo)
$light.Save("$OutDir\logo-light.png", [System.Drawing.Imaging.ImageFormat]::Png)

# Simbol hijab saja (koordinat relatif terhadap logo yang sudah dipotong).
$symOnly = [Logo]::SymbolOnly($logo)
$symBox = [Logo]::Bounds($symOnly, 40, 0, $symOnly.Width)
$sym = Crop $symOnly $symBox 2
$sym.Save("$OutDir\symbol.png", [System.Drawing.Imaging.ImageFormat]::Png)

$white = [System.Drawing.Color]::White
(Square $sym 512 0.78 $white).Save("$OutDir\icon-512.png", [System.Drawing.Imaging.ImageFormat]::Png)
(Square $sym 64 0.86 $null).Save("$OutDir\favicon-64.png", [System.Drawing.Imaging.ImageFormat]::Png)

"logo: $($logo.Width)x$($logo.Height)  simbol: $($sym.Width)x$($sym.Height) (kotak $symBox)"
$src.Dispose()

# Ikon launcher Android (legacy, persegi putih; simbol 72% agar aman bila launcher memotong jadi lingkaran).
foreach ($d in @(@('mdpi', 48), @('hdpi', 72), @('xhdpi', 96), @('xxhdpi', 144), @('xxxhdpi', 192))) {
  New-Item -ItemType Directory -Force "$OutDir\mipmap-$($d[0])" | Out-Null
  (Square $sym $d[1] 0.72 $white).Save("$OutDir\mipmap-$($d[0])\ic_launcher.png", [System.Drawing.Imaging.ImageFormat]::Png)
}
(Square $sym 32 0.9 $null).Save("$OutDir\favicon-32.png", [System.Drawing.Imaging.ImageFormat]::Png)
