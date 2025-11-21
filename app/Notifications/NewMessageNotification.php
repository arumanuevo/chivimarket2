<?php

// app/Notifications/NewMessageNotification.php
namespace App\Notifications;

use App\Models\Message;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class NewMessageNotification extends Notification
{
    use Queueable;

    protected $message;

    public function __construct(Message $message)
    {
        $this->message = $message;
    }

    public function via($notifiable)
    {
        return ['mail', 'database', 'broadcast']; // Guardar en BD y enviar por Pusher
    }

    public function toArray($notifiable)
    {
        return [
            'message_id' => $this->message->id,
            'conversation_id' => $this->message->conversation_id,
            'sender_id' => $this->message->sender_id,
            'sender_name' => $this->message->sender->name,
            'message' => $this->message->message,
            'created_at' => $this->message->created_at->toDateTimeString()
        ];
    }

    // Opcional: para enviar por email
    public function toMail($notifiable)
    {
        return (new MailMessage)
            ->subject('Nuevo mensaje de ' . $this->message->sender->name)
            ->line('Has recibido un nuevo mensaje:')
            ->line($this->message->message)
            ->action('Ver conversación', url('/conversations/' . $this->message->conversation_id));
    }
}

