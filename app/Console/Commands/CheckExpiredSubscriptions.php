<?php
// app/Console/Commands/CheckExpiredSubscriptions.php
namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Subscription;
use App\Notifications\SubscriptionExpiredNotification;

class CheckExpiredSubscriptions extends Command
{
    protected $signature = 'subscriptions:check-expired';
    protected $description = 'Degrada suscripciones vencidas a free';

    public function handle()
    {
        $now = now();
        $subscriptions = Subscription::where('next_payment_due', '<=', $now)
            ->where('type', '!=', 'free')
            ->where('payment_status', '!=', 'paid')
            ->get();

        foreach ($subscriptions as $subscription) {
            $subscription->update([
                'type' => 'free',
                'product_limit' => 10, // Límite para plan free
                'payment_status' => 'cancelled',
                'can_downgrade' => true,
                'downgrade_lock_until' => null,
                'next_payment_due' => null
            ]);

            // Notificar al usuario
            $subscription->user->notify(new SubscriptionExpiredNotification($subscription));
        }

        $this->info('Suscripciones vencidas procesadas: ' . $subscriptions->count());
    }
}

