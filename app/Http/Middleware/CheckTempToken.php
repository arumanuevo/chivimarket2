<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class CheckTempToken
{
    public function handle(Request $request, Closure $next)
    {
        $deviceId = $request->input('device_id');
        $tempToken = $request->input('temp_token');

        Log::info("CheckToken: Buscando token para device_id = " . $deviceId);
        Log::info("CheckToken: temp_token = " . $tempToken);

        // Solo registramos en el log, no bloqueamos el acceso
        return $next($request);
    }
}