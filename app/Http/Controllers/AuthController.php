<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
use App\Models\User;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if (!Auth::attempt($request->only('email', 'password'))) {
            throw ValidationException::withMessages([
                'email' => ['Credenciales incorrectas'],
            ]);
        }

        $user = Auth::user();

        // 👇 Cargar roles y permisos
        $user->load('roles', 'permissions');

        $token = $user->createToken('auth-token')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token,
        ]);
    }
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Sesión cerrada']);
    }

    // En AuthController.php (método register)
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string',
            'email' => 'required|email|unique:users',
            'password' => 'required|string|min:8',
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => bcrypt($request->password),
        ]);

        // Asignar rol por defecto
        $user->assignRole('user');

        // 👇 Crear suscripción FREE por defecto
        $user->subscription()->create([
            'type' => 'free',
            'product_limit' => 10,  // Límite para usuarios free
            'starts_at' => now(),
            'ends_at' => now()->addYear(),  // 1 año de validez
            'is_active' => true
        ]);

        // Cargar relaciones para la respuesta
        $user->load('roles', 'subscription');

        return response()->json(['message' => 'Usuario creado', 'user' => $user], 201);
    }

}
