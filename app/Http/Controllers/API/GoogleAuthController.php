<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Laravel\Socialite\Facades\Socialite;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;

class GoogleAuthController extends Controller
{
    /**
     * Endpoint para validar un de Google Sign-in originado en Flutter
     * Flutter usa el paquete google_sign_in, obtiene el accessToken y lo manda aquí.
     */
    public function verifyGoogleToken(Request $request)
    {
        $request->validate([
            'access_token' => 'required|string',
            'recaptcha_token' => 'nullable|string' // Opcional dependiendo si lo exiges siempre
        ]);

        // 1. (Opcional) Validar el reCAPTCHA si viene desde Flutter Web
        /*
        if ($request->has('recaptcha_token')) {
            $recaptchaResponse = Http::asForm()->post('https://www.google.com/recaptcha/api/siteverify', [
                'secret' => env('RECAPTCHA_SECRET_KEY'),
                'response' => $request->recaptcha_token,
            ]);
            if (!$recaptchaResponse->json('success') || $recaptchaResponse->json('score') < 0.5) {
                return response()->json(['message' => 'Validación anti-spam (reCAPTCHA) fallida.'], 403);
            }
        }
        */

        try {
            // 2. Extraer usuario desde Google usando el token directo
            $googleUser = Socialite::driver('google')->stateless()->userFromToken($request->access_token);

            // 3. Buscar usuario por email, sino lo creamos
            $user = User::where('email', $googleUser->getEmail())->first();

            if (!$user) {
                $user = User::create([
                    'name' => $googleUser->getName(),
                    'email' => $googleUser->getEmail(),
                    'password' => Hash::make(Str::random(24)), // Random password imposible de adivinar
                ]);

                // Si usas Spatie, aquí le asignarías un rol:
                // $user->assignRole('comercio');
            }

            // 4. Crear el token Sanctum para nuestra API
            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'message' => 'Login con Google Exitoso',
                'user' => $user,
                'token' => $token,
            ]);

        } catch (\Exception $e) {
            Log::error('Error validando token Google: ' . $e->getMessage());
            return response()->json([
                'message' => 'Error al validar el acceso con Google.',
                'error' => $e->getMessage()
            ], 401);
        }
    }

    /** 
     * Endpoint clásico si abrieras una ventana de navegador (Method A)
     */
    public function handleGoogleRedirect()
    {
        return Socialite::driver('google')->stateless()->redirect();
    }

    public function handleGoogleCallback()
    {
        try {
            $googleUser = Socialite::driver('google')->stateless()->user();

            $user = User::where('email', $googleUser->getEmail())->first();

            if (!$user) {
                $user = User::create([
                    'name' => $googleUser->getName(),
                    'email' => $googleUser->getEmail(),
                    'password' => Hash::make(Str::random(24)),
                ]);
            }

            $token = $user->createToken('auth_token')->plainTextToken;

            // Al ser un flujo web completo, puedes redirigir a un scheme de Flutter Ej: chivimarket://login?token=...
            // o a una página web de éxito.
            return response()->json([
                'token' => $token,
                'user_id' => $user->id,
                'message' => 'Por favor intercepta este token y envíalo a tu app.'
            ]);

        } catch (\Exception $e) {
            return response()->json(['message' => 'Error en Callback de Google'], 500);
        }
    }
}
