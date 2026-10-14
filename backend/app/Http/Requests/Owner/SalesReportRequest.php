<?php

namespace App\Http\Requests\Owner;

use Carbon\CarbonImmutable;
use Closure;
use Illuminate\Foundation\Http\FormRequest;

class SalesReportRequest extends FormRequest
{
    /** Batas panjang periode agar grafik harian tetap terbaca. */
    public const MAX_DAYS = 366;

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'from' => ['nullable', 'date_format:Y-m-d'],
            'to' => [
                'nullable',
                'date_format:Y-m-d',
                'after_or_equal:from',
                function (string $attribute, mixed $value, Closure $fail) {
                    $from = $this->input('from');
                    if ($from && CarbonImmutable::parse($from)->diffInDays(CarbonImmutable::parse($value)) >= self::MAX_DAYS) {
                        $fail('Periode laporan paling panjang '.self::MAX_DAYS.' hari.');
                    }
                },
            ],
        ];
    }

    public function messages(): array
    {
        return ['to.after_or_equal' => 'Tanggal akhir tidak boleh sebelum tanggal awal.'];
    }

    /** Default: 30 hari terakhir sampai hari ini. */
    public function period(): array
    {
        $to = $this->filled('to') ? CarbonImmutable::parse($this->input('to')) : CarbonImmutable::today();
        $from = $this->filled('from') ? CarbonImmutable::parse($this->input('from')) : $to->subDays(29);

        return [$from, $to];
    }
}
