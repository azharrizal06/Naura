<?php

namespace App\Services\Shipping;

use Illuminate\Http\JsonResponse;
use RuntimeException;

/** Ongkir tidak bisa dihitung; dirender sebagai JSON { message } dengan status HTTP-nya. */
class ShippingException extends RuntimeException
{
    public function __construct(string $message, private readonly int $status)
    {
        parent::__construct($message);
    }

    public static function notConfigured(): self
    {
        return new self('Pencarian kecamatan belum tersedia. Isi kota, provinsi, dan kode pos secara manual.', 503);
    }

    public static function searchFailed(): self
    {
        return new self('Pencarian wilayah tidak bisa dilakukan saat ini. Coba lagi beberapa saat lagi.', 502);
    }

    public static function providerFailed(): self
    {
        return new self('Ongkir tidak bisa dihitung saat ini. Coba lagi beberapa saat lagi.', 502);
    }

    public function render(): JsonResponse
    {
        return response()->json(['message' => $this->getMessage()], $this->status);
    }
}
