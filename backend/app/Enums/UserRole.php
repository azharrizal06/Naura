<?php

namespace App\Enums;

enum UserRole: string
{
    case Customer = 'customer';
    case Admin = 'admin';
    case Owner = 'owner';

    public function label(): string
    {
        return match ($this) {
            self::Customer => 'Customer',
            self::Admin => 'Admin',
            self::Owner => 'Owner',
        };
    }

    /** Role yang boleh mengakses dashboard (React). */
    public static function dashboardRoles(): array
    {
        return [self::Admin->value, self::Owner->value];
    }
}
