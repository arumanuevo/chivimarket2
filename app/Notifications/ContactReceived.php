<?php
// app/Notifications/ContactReceived.php
namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Notifications\Messages\MailMessage;

class ContactReceived extends Notification
{
    use Queueable;

    protected $contactType;

    public function __construct($contactType)
    {
        $this->contactType = $contactType;
    }

    public function via($notifiable)
    {
        return ['mail', 'database'];
    }

    public function toMail($notifiable)
    {
        return (new MailMessage)
            ->subject('Nuevo contacto en tu negocio')
            ->line('¡Buenas noticias! Alguien ha mostrado interés en tu negocio.')
            ->line("Tipo de contacto: " . $this->formatContactType($this->contactType))
            ->action('Ver estadísticas', url('/businesses/' . $notifiable->business->id . '/stats'))
            ->line('Gracias por usar nuestra plataforma!');
    }

    public function toArray($notifiable)
    {
        return [
            'message' => 'Nuevo contacto en tu negocio',
            'contact_type' => $this->contactType,
            'contact_type_formatted' => $this->formatContactType($this->contactType), // 👈 Añadido para la base de datos
            'business_id' => $notifiable->business->id
        ];
    }

    /**
     * Formatea el tipo de contacto para mostrarlo de manera legible.
     *
     * @param string $type
     * @return string
     */
    protected function formatContactType($type)
    {
        $types = [
            'phone_view' => 'Visualización de teléfono',
            'email_view' => 'Visualización de email',
            'address_view' => 'Visualización de dirección',
            'website_click' => 'Clic al sitio web',
            'social_click' => 'Clic a redes sociales',
            'copy_contact' => 'Copia de información de contacto',
            'favorite' => 'Guardado como favorito',
            'share' => 'Compartido en redes sociales',
            'map_view' => 'Visualización de mapa',
            'catalog_download' => 'Descarga de catálogo'
        ];

        return $types[$type] ?? ucfirst(str_replace('_', ' ', $type));
    }
}

