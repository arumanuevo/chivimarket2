<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use App\Models\AccessToken;

class CheckTempToken
{
    public function handle(Request $request, Closure $next)
    {
        $deviceId = $request->input('device_id');
        $token = $request->input('token');

        Log::info("CheckToken: Buscando token para device_id = " . $deviceId);
        Log::info("CheckToken: token = " . $token);

        if (empty($token)) {
            Log::info("CheckToken: No se encontró un token en la solicitud");
            return $next($request);
        }

        $accessTokens = AccessToken::where('device_id', $deviceId)
            ->where('token', $token)
            ->where('used', false)
            ->where('expires_at', '>', now())
            ->get();

        Log::info("CheckToken: Tokens encontrados = " . $accessTokens->count());

        if ($accessTokens->count() > 0) {
            $accessToken = $accessTokens->first();
            Log::info("CheckToken: Token ID = " . $accessToken->id . ", token = " . $accessToken->token . ", used = " . $accessToken->used);
            $accessToken->used = true;
            $accessToken->save();
            Log::info("CheckToken: Token marcado como usado");
            return $next($request);
        } else {
            Log::info("CheckToken: No se encontró un token válido");
            return $next($request);
        }
    }
}