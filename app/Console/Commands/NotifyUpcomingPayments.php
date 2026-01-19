<?php
// app/Console/Commands/NotifyUpcomingPayments.php
namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Subscription;
use App\Notifications\UpcomingPaymentNotification;

class NotifyUpcomingPayments extends Command
{
    protected $signature = 'subscriptions:notify-upcoming';
    protected $description = 'Notifica pagos próximos a vencer (5 días antes)';

    public function handle()
    {
        $in5Days = now()->addDays(5);
        $subscriptions = Subscription::where('next_payment_due', '>=', now())
            ->where('next_payment_due', '<=', $in5Days)
            ->where('type', '!=', 'free')
            ->get();

        foreach ($subscriptions as $subscription) {
            $subscription->user->notify(new UpcomingPaymentNotification($subscription));
        }

        $this->info('Notificaciones de pagos próximos enviadas: ' . $subscriptions->count());
    }
}
