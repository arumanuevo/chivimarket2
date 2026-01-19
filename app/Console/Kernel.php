<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    /**
     * Define the application's command schedule.
     */
    protected function schedule(Schedule $schedule): void
    {
        // Verificar suscripciones vencidas y degradarlas a 'free'
        $schedule->command('subscriptions:check-expired')
                 ->dailyAt('09:00')  // Ejecutar a las 9 AM (hora Argentina)
                 ->timezone('America/Buenos_Aires');  // Zona horaria de Argentina

        // Notificar pagos próximos a vencer (5 días antes)
        $schedule->command('subscriptions:notify-upcoming')
                 ->dailyAt('10:00')  // Ejecutar a las 10 AM
                 ->timezone('America/Buenos_Aires');
    }

    /**
     * Register the commands for the application.
     */
    protected function commands(): void
    {
        $this->load(__DIR__.'/Commands');

        // Registrar los comandos personalizados (opcional, pero útil para depuración)
        $this->commands([
            \App\Console\Commands\CheckExpiredSubscriptions::class,
            \App\Console\Commands\NotifyUpcomingPayments::class,
        ]);
    }
}

