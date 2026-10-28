<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;

class GoogleAuthController extends Controller
{
    /**
     * Endpoint directo si se envía access_token o id_token desde Flutter
     */
    public function verifyGoogleToken(Request $request)
    {
        $request->validate([
            'access_token' => 'required|string',
        ]);

        try {
            $token = $request->access_token;

            // Consultar datos de usuario a Google UserInfo API
            $response = Http::withToken($token)->get('https://www.googleapis.com/oauth2/v3/userinfo');

            if (!$response->successful()) {
                // Intentar validar como id_token alternativamente
                $response = Http::get('https://oauth2.googleapis.com/tokeninfo', ['id_token' => $token]);
            }

            if (!$response->successful()) {
                return response()->json(['message' => 'Token de Google inválido o expirado.'], 401);
            }

            $googleData = $response->json();
            $email = $googleData['email'] ?? null;
            $name = $googleData['name'] ?? $googleData['given_name'] ?? 'Usuario Google';

            if (!$email) {
                return response()->json(['message' => 'No se pudo obtener el correo de Google.'], 422);
            }

            $user = User::where('email', $email)->first();

            if (!$user) {
                $user = User::create([
                    'name' => $name,
                    'email' => $email,
                    'password' => Hash::make(Str::random(24)),
                ]);
            }

            if (!$user->hasVerifiedEmail()) {
                $user->markEmailAsVerified();
            }

            $sanctumToken = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'message' => 'Login con Google Exitoso',
                'user' => $user,
                'token' => $sanctumToken,
            ]);

        } catch (\Exception $e) {
            Log::error('Error validando token Google: ' . $e->getMessage());
            return response()->json([
                'message' => 'Error al validar el acceso con Google.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /** 
     * Redirige al consentimiento oficial de Google OAuth 2.0 (Nativo sin dependencias)
     */
    public function handleGoogleRedirect()
    {
        $clientId = config('services.google.client_id');
        $redirectUri = config('services.google.redirect');

        if (!$clientId) {
            Log::error('Google OAuth: GOOGLE_CLIENT_ID no configurado en el archivo .env');
            return response()->json(['message' => 'GOOGLE_CLIENT_ID no configurado en .env'], 500);
        }

        $params = http_build_query([
            'client_id' => $clientId,
            'redirect_uri' => $redirectUri,
            'response_type' => 'code',
            'scope' => 'openid profile email',
            'access_type' => 'online',
            'prompt' => 'select_account',
        ]);

        return redirect('https://accounts.google.com/o/oauth2/v2/auth?' . $params);
    }

    /**
     * Procesa el retorno de Google, intercambia code por token y redirige a Flutter
     */
    public function handleGoogleCallback(Request $request)
    {
        try {
            $code = $request->get('code');

            if (!$code) {
                Log::warning('Google Callback: No se recibió parámetro code de Google.');
                return redirect('/?error=google_auth_failed');
            }

            $clientId = config('services.google.client_id');
            $clientSecret = config('services.google.client_secret');
            $redirectUri = config('services.google.redirect');

            // 1. Intercambiar authorization code por access_token con Google
            $tokenResponse = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                'client_id' => $clientId,
                'client_secret' => $clientSecret,
                'code' => $code,
                'grant_type' => 'authorization_code',
                'redirect_uri' => $redirectUri,
            ]);

            if (!$tokenResponse->successful()) {
                Log::error('Error intercambiando code por token en Google: ' . $tokenResponse->body());
                return redirect('/?error=google_auth_token_failed');
            }

            $accessToken = $tokenResponse->json('access_token');

            // 2. Obtener la información del perfil del usuario
            $profileResponse = Http::withToken($accessToken)->get('https://www.googleapis.com/oauth2/v3/userinfo');

            if (!$profileResponse->successful()) {
                Log::error('Error obteniendo perfil de Google: ' . $profileResponse->body());
                return redirect('/?error=google_profile_failed');
            }

            $profile = $profileResponse->json();
            $email = $profile['email'] ?? null;
            $name = $profile['name'] ?? $profile['given_name'] ?? 'Usuario Google';

            if (!$email) {
                Log::error('Google OAuth: El perfil de Google no devolvió email.');
                return redirect('/?error=google_no_email');
            }

            // 3. Buscar o registrar al usuario en la base de datos
            $user = User::where('email', $email)->first();

            if (!$user) {
                $user = User::create([
                    'name' => $name,
                    'email' => $email,
                    'password' => Hash::make(Str::random(24)),
                ]);
            }

            if (!$user->hasVerifiedEmail()) {
                $user->markEmailAsVerified();
            }

            // 4. Generar token Sanctum de sesión
            $token = $user->createToken('auth_token')->plainTextToken;

            // Redirigir a la app Flutter con el token para autologuear
            return redirect('/?token=' . $token);

        } catch (\Exception $e) {
            Log::error('Excepción en Callback de Google: ' . $e->getMessage());
            return redirect('/?error=google_auth_exception');
        }
    }
}
