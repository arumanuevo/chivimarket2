<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Subscription;
use App\Services\SubscriptionService;
use Carbon\Carbon;

class DegradeExpiredSubscriptions extends Command
{
    protected $signature = 'subscriptions:degrade-expired';
    protected $description = 'Degradar suscripciones vencidas a plan free';

    public function handle()
    {
        $now = Carbon::now();
        $expiredSubscriptions = Subscription::where('ends_at', '<', $now)
            ->where('type', '!=', 'free')
            ->where('is_active', true)
            ->get();

        foreach ($expiredSubscriptions as $subscription) {
            $user = $subscription->user;
            SubscriptionService::degradeToFree($user);
            $this->info("Suscripción del usuario {$user->id} degradada a 'free'.");
        }

        $this->info('Proceso de degradación completado.');
    }
}

