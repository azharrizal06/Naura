<?php

namespace App\Console\Commands;

use Database\Seeders\DemoSeeder;
use GdImage;
use Illuminate\Console\Command;
use Illuminate\Support\Str;

/**
 * Gambar produk dummy (alat dev, butuh ekstensi GD): siluet busana per kategori dengan warna kain varian.
 * Hasil di public/demo/{slug}-{n}.jpg (file statis, ikut di-commit) — server produksi tidak perlu GD.
 */
class GenerateDemoImages extends Command
{
    protected $signature = 'demo:images {--force : Timpa gambar yang sudah ada}';

    protected $description = 'Buat gambar produk dummy untuk DemoSeeder (public/demo)';

    private const W = 600;

    private const H = 800;

    private const SCALE = 2; // gambar 2× lalu diperkecil = tepi halus

    /** Warna kain — sama dengan kamus swatch dashboard/mobile. */
    private const HEX = [
        'broken white' => 'EEE8DC', 'dusty pink' => 'D2A3A3', 'dusty blue' => '8EA3B8', 'hitam' => '1F1A20',
        'putih' => 'FAF9F6', 'abu' => '9C9AA1', 'navy' => '24304F', 'maroon' => '6C1F2B', 'mocca' => 'A07E62',
        'milo' => '8A6A57', 'coksu' => 'B08A6E', 'taro' => 'B6A2C8', 'lilac' => 'C7B5DC', 'lavender' => 'C9C0E3',
        'sage' => 'A2B299', 'army' => '5A5D3B', 'olive' => '76743F', 'mustard' => 'C89E39', 'emerald' => '2E6D59',
        'tosca' => '3D9A98', 'mint' => 'BEDACA', 'biru' => '3C69A6', 'peach' => 'EFBE9F', 'krem' => 'E9DEC7',
        'cream' => 'E9DEC7', 'khaki' => 'BEAE83', 'hijau' => '4D7949', 'terracotta' => 'B45F3E',
    ];

    public function handle(): int
    {
        if (! function_exists('imagecreatetruecolor')) {
            $this->error('Ekstensi GD tidak aktif.');

            return self::FAILURE;
        }
        $dir = public_path('demo');
        if (! is_dir($dir)) {
            mkdir($dir, 0755, true);
        }

        $count = 0;
        foreach (DemoSeeder::CATALOG as $category => $products) {
            foreach ($products as $name => [, $colors]) {
                foreach (array_slice($colors, 0, DemoSeeder::IMAGES_PER_PRODUCT) as $i => $color) {
                    $file = $dir.'/'.Str::slug($name).'-'.($i + 1).'.jpg';
                    if (! $this->option('force') && is_file($file)) {
                        continue;
                    }
                    $this->render($category, $name, $color, $file);
                    $count++;
                }
            }
        }
        $this->info("{$count} gambar dibuat di {$dir}");

        return self::SUCCESS;
    }

    private function render(string $category, string $name, string $color, string $file): void
    {
        $w = self::W * self::SCALE;
        $h = self::H * self::SCALE;
        $img = imagecreatetruecolor($w, $h);
        imagealphablending($img, true);

        // Latar studio: gradasi lembut + bayangan lantai.
        for ($y = 0; $y < $h; $y++) {
            $t = $y / $h;
            imageline($img, 0, $y, $w, $y, $this->rgb($img, $this->mix([246, 242, 239], [233, 226, 231], $t)));
        }
        imagefilledellipse($img, (int) ($w * 0.5), (int) ($h * 0.875), (int) ($w * 0.56), (int) ($h * 0.035), $this->rgba($img, [43, 24, 48], 105));

        $base = $this->hex($color);
        $shape = match ($category) {
            'Hijab' => $this->hijab(),
            'Mukena' => str_contains($name, 'Sajadah') ? $this->prayerMat() : $this->mukena(),
            'Atasan' => $this->dress(0.60),
            'Bawahan' => str_contains($name, 'Kulot') || str_contains($name, 'Celana') ? $this->culottes() : $this->skirt(str_contains($name, 'Plisket')),
            default => $this->dress(0.86),
        };
        if (str_contains($name, 'Anak')) {
            $shape = $this->scaleShape($shape, 0.8);
        }

        $light = $this->luminance($base) > 0.82;
        foreach ($shape['parts'] as [$points, $shade]) {
            $fill = $shade === 0 ? $base : $this->shade($base, $shade);
            imagefilledpolygon($img, $this->px($points, $w, $h), $this->rgb($img, $fill));
            if ($light) { // kain terang: garis tepi tipis agar tidak menyatu dengan latar
                imagesetthickness($img, 3);
                imagepolygon($img, $this->px($points, $w, $h), $this->rgba($img, $this->shade($base, -0.25), 40));
            }
        }
        foreach ($shape['folds'] as [$points, $shade]) {
            $alpha = $shade < 0 ? 88 : 96; // 0 = penuh, 127 = transparan
            imagefilledpolygon($img, $this->px($points, $w, $h), $this->rgba($img, $this->shade($base, $shade), $alpha));
        }
        foreach ($shape['holes'] ?? [] as [$cx, $cy, $rx, $ry]) { // bukaan wajah hijab/mukena
            imagefilledellipse($img, (int) ($cx * $w), (int) ($cy * $h), (int) ($rx * 2 * $w), (int) ($ry * 2 * $h), $this->rgb($img, [241, 236, 236]));
            imagesetthickness($img, 4);
            imageellipse($img, (int) ($cx * $w), (int) ($cy * $h), (int) ($rx * 2 * $w), (int) ($ry * 2 * $h), $this->rgb($img, $this->shade($base, -0.3)));
        }

        $out = imagecreatetruecolor(self::W, self::H);
        imagecopyresampled($out, $img, 0, 0, 0, 0, self::W, self::H, $w, $h);
        imagejpeg($out, $file, 82);
        imagedestroy($img);
        imagedestroy($out);
    }

    // --- Bentuk (koordinat 0..1). parts: [titik, shade]; folds: lipatan semi-transparan. ---

    private function dress(float $hem): array
    {
        $body = [[0.42, 0.13], [0.58, 0.13], [0.64, 0.17], [0.61, 0.38], ...$this->curve([0.70, $hem], [0.50, $hem + 0.025], [0.30, $hem]), [0.39, 0.38], [0.36, 0.17]];
        $sleeveL = [[0.36, 0.17], [0.30, 0.20], [0.235, 0.50], [0.29, 0.515], [0.355, 0.28]];
        $sleeveR = $this->mirror($sleeveL);
        $folds = [];
        foreach ([[0.46, 0.405], [0.50, 0.50], [0.54, 0.595]] as [$top, $bottom]) {
            $folds[] = [[[$top - 0.004, 0.40], [$top + 0.004, 0.40], [$bottom + 0.02, $hem], [$bottom - 0.02, $hem]], -0.18];
        }
        $folds[] = [[[0.43, 0.40], [0.44, 0.40], [0.37, $hem], [0.345, $hem]], 0.25];
        $folds[] = [[[0.43, 0.135], [0.57, 0.135], [0.555, 0.16], [0.445, 0.16]], -0.35]; // garis leher

        return ['parts' => [[$sleeveL, -0.08], [$sleeveR, -0.08], [$body, 0]], 'folds' => $folds];
    }

    private function hijab(): array
    {
        $drape = [...$this->arc(0.5, 0.30, 0.17, 0.20, 190, 350), [0.70, 0.40], ...$this->curve([0.78, 0.78], [0.50, 0.84], [0.22, 0.78]), [0.30, 0.40]];
        $folds = [];
        foreach ([-0.16, -0.06, 0.06, 0.16] as $dx) {
            $folds[] = [[[0.5 + $dx * 0.3, 0.47], [0.5 + $dx * 0.3 + 0.01, 0.47], [0.5 + $dx * 1.6 + 0.02, 0.80], [0.5 + $dx * 1.6 - 0.02, 0.80]], -0.17];
        }
        $folds[] = [[[0.34, 0.36], [0.36, 0.36], [0.30, 0.76], [0.26, 0.76]], 0.22];

        return ['parts' => [[$drape, 0]], 'folds' => $folds, 'holes' => [[0.5, 0.33, 0.085, 0.11]]];
    }

    private function mukena(): array
    {
        $top = [...$this->arc(0.5, 0.29, 0.18, 0.19, 190, 350), [0.72, 0.38], ...$this->curve([0.84, 0.64], [0.50, 0.68], [0.16, 0.64]), [0.28, 0.38]];
        $skirt = [[0.31, 0.62], [0.69, 0.62], ...$this->curve([0.75, 0.88], [0.50, 0.90], [0.25, 0.88])];
        $folds = [];
        foreach ([0.38, 0.46, 0.54, 0.62] as $x) {
            $folds[] = [[[$x, 0.66], [$x + 0.008, 0.66], [$x + ($x - 0.5) * 0.3 + 0.014, 0.88], [$x + ($x - 0.5) * 0.3 - 0.006, 0.88]], -0.12];
        }
        foreach ([-0.14, 0, 0.14] as $dx) {
            $folds[] = [[[0.5 + $dx * 0.4, 0.46], [0.5 + $dx * 0.4 + 0.01, 0.46], [0.5 + $dx * 2.2 + 0.02, 0.64], [0.5 + $dx * 2.2 - 0.02, 0.64]], -0.15];
        }

        return ['parts' => [[$skirt, -0.06], [$top, 0]], 'folds' => $folds, 'holes' => [[0.5, 0.32, 0.09, 0.115]]];
    }

    private function skirt(bool $pleated): array
    {
        $band = [[0.38, 0.17], [0.62, 0.17], [0.62, 0.215], [0.38, 0.215]];
        $skirt = [[0.38, 0.215], [0.62, 0.215], ...$this->curve([0.73, 0.84], [0.50, 0.865], [0.27, 0.84])];
        $folds = [];
        $n = $pleated ? 11 : 4;
        for ($i = 1; $i < $n; $i++) {
            $t = $i / $n;
            $x0 = 0.38 + 0.24 * $t;
            $x1 = 0.27 + 0.46 * $t;
            $folds[] = [[[$x0 - 0.002, 0.22], [$x0 + 0.002, 0.22], [$x1 + 0.008, 0.85], [$x1 - 0.008, 0.85]], $i % 2 ? -0.2 : 0.18];
        }

        return ['parts' => [[$skirt, 0], [$band, -0.15]], 'folds' => $folds];
    }

    private function culottes(): array
    {
        $band = [[0.37, 0.17], [0.63, 0.17], [0.63, 0.215], [0.37, 0.215]];
        $left = [[0.37, 0.215], [0.505, 0.215], [0.505, 0.40], [0.495, 0.85], [0.29, 0.85]];
        $right = $this->mirror($left);
        $folds = [
            [[[0.42, 0.42], [0.43, 0.42], [0.40, 0.85], [0.37, 0.85]], -0.16],
            [[[0.58, 0.42], [0.57, 0.42], [0.60, 0.85], [0.63, 0.85]], -0.16],
        ];

        return ['parts' => [[$left, 0], [$right, -0.05], [$band, -0.15]], 'folds' => $folds];
    }

    private function prayerMat(): array
    {
        $mat = [[0.27, 0.14], [0.73, 0.14], [0.73, 0.86], [0.27, 0.86]];
        $inner = [[0.31, 0.18], [0.69, 0.18], [0.69, 0.82], [0.31, 0.82]];
        $arch = [[0.35, 0.78], [0.35, 0.36], ...$this->arc(0.5, 0.36, 0.15, 0.13, 180, 360), [0.65, 0.78]];

        return ['parts' => [[$mat, -0.12], [$inner, 0], [$arch, 0.18]], 'folds' => []];
    }

    // --- Geometri & warna ---

    /** Kurva kuadrat dari $a lewat kendali $c ke $b (titik-titik). */
    private function curve(array $a, array $c, array $b, int $steps = 14): array
    {
        $pts = [];
        for ($i = 0; $i <= $steps; $i++) {
            $t = $i / $steps;
            $pts[] = [(1 - $t) ** 2 * $a[0] + 2 * (1 - $t) * $t * $c[0] + $t ** 2 * $b[0], (1 - $t) ** 2 * $a[1] + 2 * (1 - $t) * $t * $c[1] + $t ** 2 * $b[1]];
        }

        return $pts;
    }

    private function arc(float $cx, float $cy, float $rx, float $ry, float $from, float $to, int $steps = 18): array
    {
        $pts = [];
        for ($i = 0; $i <= $steps; $i++) {
            $a = deg2rad($from + ($to - $from) * $i / $steps);
            $pts[] = [$cx + $rx * cos($a), $cy + $ry * sin($a)];
        }

        return $pts;
    }

    private function mirror(array $points): array
    {
        return array_map(fn ($p) => [1 - $p[0], $p[1]], $points);
    }

    /** Perkecil bentuk terhadap tengah-bawah (busana anak). */
    private function scaleShape(array $shape, float $k): array
    {
        $f = fn ($p) => [0.5 + ($p[0] - 0.5) * $k, 0.87 - (0.87 - $p[1]) * $k];
        $shape['parts'] = array_map(fn ($p) => [array_map($f, $p[0]), $p[1]], $shape['parts']);
        $shape['folds'] = array_map(fn ($p) => [array_map($f, $p[0]), $p[1]], $shape['folds']);
        $shape['holes'] = array_map(fn ($o) => [...$f([$o[0], $o[1]]), $o[2] * $k, $o[3] * $k], $shape['holes'] ?? []);

        return $shape;
    }

    /** @return list<int> */
    private function px(array $points, int $w, int $h): array
    {
        $flat = [];
        foreach ($points as [$x, $y]) {
            $flat[] = (int) round($x * $w);
            $flat[] = (int) round($y * $h);
        }

        return $flat;
    }

    private function hex(string $color): array
    {
        $hex = self::HEX[mb_strtolower($color)] ?? 'A07E62';

        return [hexdec(substr($hex, 0, 2)), hexdec(substr($hex, 2, 2)), hexdec(substr($hex, 4, 2))];
    }

    /** shade < 0 lebih gelap, > 0 lebih terang. */
    private function shade(array $c, float $k): array
    {
        return $k < 0 ? $this->mix($c, [0, 0, 0], -$k) : $this->mix($c, [255, 255, 255], $k);
    }

    private function mix(array $a, array $b, float $t): array
    {
        return [(int) ($a[0] + ($b[0] - $a[0]) * $t), (int) ($a[1] + ($b[1] - $a[1]) * $t), (int) ($a[2] + ($b[2] - $a[2]) * $t)];
    }

    private function luminance(array $c): float
    {
        return (0.2126 * $c[0] + 0.7152 * $c[1] + 0.0722 * $c[2]) / 255;
    }

    private function rgb(GdImage $img, array $c): int
    {
        return imagecolorallocate($img, $c[0], $c[1], $c[2]);
    }

    private function rgba(GdImage $img, array $c, int $alpha): int
    {
        return imagecolorallocatealpha($img, $c[0], $c[1], $c[2], $alpha);
    }
}
