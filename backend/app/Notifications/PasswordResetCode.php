<?php

namespace App\Notifications;

use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/** Email berisi kode 6 digit untuk reset password. */
class PasswordResetCode extends Notification
{
    public function __construct(
        public readonly string $code,
        public readonly int $minutes,
    ) {}

    /** @return list<string> */
    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('Kode reset password '.config('app.name'))
            ->greeting('Assalamu\'alaikum, '.$notifiable->name)
            ->line('Gunakan kode berikut untuk membuat password baru:')
            ->line('**'.$this->code.'**')
            ->line("Kode berlaku {$this->minutes} menit dan hanya bisa dipakai sekali.")
            ->line('Abaikan email ini bila Anda tidak meminta reset password — password Anda tidak berubah.');
    }
}
