<?php

// app/Http/Controllers/API/TestPusherController.php
namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Pusher\Pusher;

class TestPusherController extends Controller
{
    protected $pusher;

    public function __construct()
    {
        $this->pusher = new Pusher(
            config('broadcasting.connections.pusher.key'),
            config('broadcasting.connections.pusher.secret'),
            config('broadcasting.connections.pusher.app_id'),
            [
                'cluster' => config('broadcasting.connections.pusher.options.cluster'),
                'useTLS' => true
            ]
        );
    }

    public function sendTestMessage(Request $request)
    {
        $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
            'channel' => 'required|string',
            'message' => 'required|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Error de validación',
                'errors' => $validator->errors()
            ], 400);
        }

        $this->pusher->trigger(
            $request->channel,
            'test-event',
            [
                'message' => $request->message,
                'timestamp' => now()->toDateTimeString()
            ]
        );

        return response()->json([
            'message' => 'Mensaje enviado a Pusher exitosamente',
            'channel' => $request->channel,
            'data' => [
                'message' => $request->message,
                'timestamp' => now()->toDateTimeString()
            ]
        ]);
    }
}

