<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;

class UserController extends Controller
{
    public function index(Request $request)
    {
        // 1. Verificación manual Estricta de Dios (Super Admin)
        if (!$request->user() || !$request->user()->hasRole('super-admin')) {
            return response()->json(['error' => 'No tienes permisos de Súper Administrador'], 403);
        }

        // 2. Traemos a todos los usuarios con su suscripción y cantidad de comercios
        $users = User::with('subscription')->withCount('businesses')->orderBy('id', 'desc')->get();
        return response()->json($users);
    }

    /**
     * Súper Admin: Cambiar plan manualmente a un cliente.
     */
    public function updateSubscription(Request $request, $id)
    {
        if (!$request->user() || !$request->user()->hasRole('super-admin')) {
            return response()->json(['error' => 'Acceso denegado.'], 403);
        }

        $request->validate([
            'type' => 'required|string|in:free,basic,premium,enterprise'
        ]);

        $targetUser = User::findOrFail($id);

        // Buscamos o creamos la suscripción si no la tiene
        $subscription = $targetUser->subscription ?? new \App\Models\Subscription(['user_id' => $targetUser->id]);

        $subscription->type = strtolower($request->type);
        // Si no es free, caduca en 30 días, si es free no caduca nunca (ejemplo base)
        $subscription->starts_at = now();
        $subscription->ends_at = $request->type === 'free' ? null : now()->addDays(30);
        $subscription->is_active = true;
        $subscription->save();

        return response()->json([
            'message' => 'Suscripción de ' . $targetUser->name . ' actualizada a ' . strtoupper($request->type),
            'subscription' => $subscription
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:8',
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => bcrypt($request->password),
        ]);

        return response()->json($user, 201);
    }
}