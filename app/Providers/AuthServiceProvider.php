<?php

namespace App\Providers;

use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;

class AuthServiceProvider extends ServiceProvider
{
    protected $policies = [
        Business::class => BusinessPolicy::class,
    ];
    

    public function boot(): void
    {
        $this->registerPolicies();
    }
}