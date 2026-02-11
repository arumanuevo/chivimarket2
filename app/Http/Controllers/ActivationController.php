<?php

// app/Http/Controllers/ActivationController.php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Device;
use App\Models\ActivationLog;
use Illuminate\Support\Str;

class ActivationController extends Controller
{
    public function validate(Request $request)
    {
        $request->validate([
            'device_id' => 'required|string',
            'token' => 'required|string',
            'temp_token' => 'required|string'
        ]);

        $device = Device::where('device_id', $request->device_id)->first();
        if (!$device) {
            return response()->json(['status' => 'error', 'message' => 'Dispositivo no encontrado'], 404);
        }

        if (!Str::startsWith($request->token, 'PAY_')) {
            return response()->json(['status' => 'error', 'message' => 'Token inválido'], 403);
        }

        ActivationLog::create([
            'device_id' => $request->device_id,
            'token' => $request->token,
            'duration_seconds' => 10,
            'source_ip' => $request->ip(),
            'status' => 'completed'
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Relé activado por 10 segundos'
        ]);
    }
}

