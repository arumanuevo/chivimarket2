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

        if (empty($token)) {
            return $next($request);
        }

        $accessToken = AccessToken::where('device_id', $deviceId)
            ->where('token', $token)
            ->where('used', false)
            ->where('expires_at', '>', now())
            ->first();

        if ($accessToken) {
            $accessToken->used = true;
            $accessToken->save();
            Log::info("Token marcado como usado: ID = " . $accessToken->id);
        }

        return $next($request);
    }
}