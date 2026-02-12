<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Illuminate\Support\Facades\Session;

class CheckTempToken
{
    public function handle(Request $request, Closure $next): Response
    {
        $tempToken = $request->input('temp_token');

        if (Session::has('used_temp_token_' . $tempToken)) {
            return redirect()->back()->with('error', 'El código QR ya ha sido usado. Escanea el QR nuevamente.');
        }

        return $next($request);
    }
}