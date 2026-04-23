<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckShowerAdminToken
{
    public function handle(Request $request, Closure $next): Response
    {
        if (!$request->user() || !$request->user()->tokenCan('shower-admin')) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        return $next($request);
    }
}