<?php

namespace App\Http\Controllers;

use App\Models\ShowerPrice;
use App\Models\ShowerUsage;
use App\Models\AccessToken;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class ShowerAdminController extends Controller
{
    // Obtener el precio actual de la ducha
    public function getPrice()
    {
        $price = ShowerPrice::latest()->first();
        return response()->json(['price' => $price->price]);
    }

    // Actualizar el precio de la ducha
    public function updatePrice(Request $request)
    {
        $request->validate([
            'price' => 'required|numeric|min:0.01'
        ]);

        $price = ShowerPrice::create([
            'price' => $request->price
        ]);

        return response()->json(['message' => 'Precio actualizado correctamente', 'price' => $price->price]);
    }

    // Obtener el historial de uso de duchas
    public function getUsageHistory(Request $request)
    {
        $usageHistory = ShowerUsage::orderBy('used_at', 'desc')->get();
        return response()->json($usageHistory);
    }

    // Registrar el uso de una ducha
    public function logUsage(Request $request)
    {
        $request->validate([
            'device_id' => 'required|string',
            'token' => 'required|string'
        ]);

        $accessToken = AccessToken::where('token', $request->token)->first();

        if (!$accessToken) {
            return response()->json(['message' => 'Token no encontrado'], 404);
        }

        $usage = ShowerUsage::create([
            'device_id' => $request->device_id,
            'token' => $request->token,
            'user_id' => auth()->id(),
            'used_at' => now()
        ]);

        return response()->json(['message' => 'Uso registrado correctamente', 'usage' => $usage]);
    }

    // Método para manejar el login
    public function login(Request $request)
{
    \Log::info('=== INICIO DE SOLICITUD DE LOGIN PARA DUCHAS ===');
    \Log::info('Email recibido:', [$request->input('email')]);
    \Log::info('Password recibido:', [$request->input('password') ? '*****' : 'No recibido']);

    $request->validate([
        'email' => 'required|email',
        'password' => 'required',
    ]);

    $credentials = $request->only('email', 'password');
    \Log::info('Credenciales:', $credentials);

    if (!Auth::attempt($credentials)) {
        \Log::warning('Credenciales incorrectas para email:', ['email' => $request->input('email')]);
        return response()->json(['message' => 'Credenciales incorrectas'], 422);
    }

    $user = Auth::user();

    \Log::info('Usuario autenticado:', ['user_id' => $user->id, 'email' => $user->email]);

    if (!$user->hasRole('admin')) {
        \Log::warning('Usuario sin permisos para acceder al panel de duchas:', ['email' => $user->email]);
        return response()->json(['message' => 'No tienes permisos para acceder a esta sección'], 403);
    }

    $token = $user->createToken('shower-admin-token', ['shower-admin'])->plainTextToken;

    \Log::info('Login exitoso para usuario de duchas:', ['user_id' => $user->id, 'email' => $user->email]);

    return response()->json([
        'user' => $user,
        'token' => $token,
    ]);
}
}