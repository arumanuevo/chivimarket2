<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Notifications\Messages\MailMessage;

class ResetPasswordNotification extends Notification
{
    use Queueable;

    public $code;

    public function __construct($code)
    {
        $this->code = $code;
    }

    public function via($notifiable)
    {
        return ['mail'];
    }

    public function toMail($notifiable)
    {
        return (new MailMessage)
            ->subject('Recuperación de contraseña - ChiviMarket')
            ->greeting('¡Hola ' . $notifiable->name . '!')
            ->line('Recibimos una solicitud para restablecer la contraseña de tu cuenta en ChiviMarket.')
            ->line('Tu código de verificación de 6 dígitos es:')
            ->line('# **' . $this->code . '**')
            ->line('Ingresa este código en la aplicación junto con tu nueva contraseña. Este código expirará en 30 minutos.')
            ->line('Si tú no solicitaste este cambio, puedes ignorar este mensaje de manera segura. Tu contraseña actual no ha sido modificada.')
            ->salutation('Saludos, el equipo de ChiviMarket');
    }
}
