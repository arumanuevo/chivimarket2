<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
use App\Models\User;
use Illuminate\Support\Facades\Log;

class AuthController extends Controller
{
    /**
     * @OA\Post(
     *     path="/api/login",
     *     summary="Iniciar sesión de usuario",
     *     description="Autentica al usuario con email y contraseña, devolviendo el token de acceso y sus datos.",
     *     tags={"Autenticación"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"email","password"},
     *             @OA\Property(property="email", type="string", example="usuario@ejemplo.com"),
     *             @OA\Property(property="password", type="string", example="12345678")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Inicio de sesión exitoso",
     *         @OA\JsonContent(
     *             @OA\Property(property="user", type="object"),
     *             @OA\Property(property="token", type="string", example="1|eyJ0eXAiOiJKV1Qi...")
     *         )
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Credenciales incorrectas"
     *     )
     * )
     */

    public function login(Request $request)
    {
        // Registrar información detallada en el log
        Log::info('=== INICIO DE SOLICITUD DE LOGIN ===');
        Log::info('Headers recibidos:', $request->header());
        Log::info('Content-Type:', [$request->header('Content-Type')]);
        Log::info('¿Es JSON?', [$request->isJson()]);
        Log::info('Método HTTP:', [$request->method()]);
        Log::info('Datos recibidos (all):', $request->all());
        Log::info('Email recibido:', [$request->input('email')]);
        Log::info('Password recibido:', [$request->input('password') ? '*****' : 'No recibido']);
        Log::info('Contenido crudo:', [$request->getContent()]);

        try {
            // Validar datos
            $request->validate([
                'email' => 'required',
                'password' => 'required',
            ]);

            // Intentar autenticación
            if (!Auth::attempt($request->only('email', 'password'))) {
                Log::warning('Credenciales incorrectas para email:', ['email' => $request->input('email')]);
                return response()->json([
                    'message' => 'Credenciales incorrectas',
                ], 422);
            }

            $user = Auth::user();
            $user->load('roles', 'permissions');

            $token = $user->createToken('auth-token')->plainTextToken;

            Log::info('Login exitoso para usuario:', ['user_id' => $user->id, 'email' => $user->email]);

            return response()->json([
                'user' => $user,
                'token' => $token,
            ])->header('Content-Type', 'application/json');

        } catch (\Exception $e) {
            Log::error('Error en login:', ['error' => $e->getMessage(), 'trace' => $e->getTraceAsString()]);
            return response()->json([
                'message' => 'Error interno del servidor',
            ], 500);
        }
    }
    /* public function login(Request $request)
 {
     // Depurar: Devuelve toda la información recibida en la solicitud
     return response()->json([
         'message' => 'Depuración: Datos recibidos en el servidor',
         'headers' => $request->header(), // Todos los headers de la solicitud
         'content_type' => $request->getContentType(), // Tipo de contenido (ej.: application/json)
         'is_json' => $request->isJson(), // ¿Es JSON?
         'all_data' => $request->all(), // Todos los datos recibidos (parámetros, body, etc.)
         'email' => $request->input('email'), // Email específico
         'password' => $request->input('password') ? '*****' : 'No recibido', // Contraseña (oculta por seguridad)
         'method' => $request->method(), // Método HTTP (GET, POST, etc.)
     ], 200);
 }*/


    /*  public function login(Request $request)
   {
       $request->validate([
           'email' => 'required|email',
           'password' => 'required',
       ]);

       if (!Auth::attempt($request->only('email', 'password'))) {
           // Devolver un JSON con código 422 en lugar de lanzar una excepción
           return response()->json([
               'message' => 'Credenciales incorrectas',
           ], 422); // Código HTTP 422 para errores de validación
       }

       $user = Auth::user();
       $user->load('roles', 'permissions');

       $token = $user->createToken('auth-token')->plainTextToken;

       return response()->json([
           'user' => $user,
           'token' => token,
       ]);
   }*/
    /**
     * @OA\Post(
     *     path="/api/logout",
     *     summary="Cerrar sesión",
     *     description="Invalida el token actual del usuario autenticado.",
     *     tags={"Autenticación"},
     *     security={{"bearerAuth":{}}},
     *     @OA\Response(
     *         response=200,
     *         description="Sesión cerrada correctamente",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Sesión cerrada")
     *         )
     *     )
     * )
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Sesión cerrada']);
    }

    /**
     * @OA\Post(
     *     path="/api/register",
     *     summary="Registrar nuevo usuario",
     *     description="Crea un nuevo usuario con rol 'user' y suscripción gratuita.",
     *     tags={"Autenticación"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"name","email","password"},
     *             @OA\Property(property="name", type="string", example="Juan Pérez"),
     *             @OA\Property(property="email", type="string", example="usuario@ejemplo.com"),
     *             @OA\Property(property="password", type="string", example="12345678")
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Usuario creado correctamente",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Usuario creado"),
     *             @OA\Property(property="user", type="object")
     *         )
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Datos inválidos"
     *     )
     * )
     */

    // En AuthController.php (método register)
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string',
            'email' => 'required|email|unique:users',
            'password' => 'required|string|min:8',
            'recaptcha_token' => 'required|string',
        ]);

        // Validación Anti-Spam de Google reCAPTCHA
        $recaptchaResponse = \Illuminate\Support\Facades\Http::asForm()->post('https://www.google.com/recaptcha/api/siteverify', [
            'secret' => env('RECAPTCHA_SECRET_KEY'),
            'response' => $request->recaptcha_token,
        ]);

        if (!$recaptchaResponse->json('success') || $recaptchaResponse->json('score') < 0.5) {
            return response()->json(['message' => 'Detectado como bot. Validación anti-spam fallida.'], 403);
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => bcrypt($request->password),
        ]);

        // Asignar rol por defecto
        $user->assignRole('user');

        // Crear suscripción FREE por defecto
        $user->subscription()->create([
            'type' => 'free',
            'product_limit' => 10,
            'starts_at' => now(),
            'ends_at' => now()->addYear(),
            'is_active' => true
        ]);

        // Disparar evento para que Laravel mande el Email de Verificación
        event(new \Illuminate\Auth\Events\Registered($user));

        // Cargar relaciones para la respuesta
        $user->load('roles', 'subscription');
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Usuario creado. Por favor verifica tu email.',
            'user' => $user,
            'token' => $token
        ], 201);
    }

    public function me(\Illuminate\Http\Request $request)
    {
        $user = $request->user();
        $user->load('roles', 'subscription');

        $subscription = $user->subscription ?? \App\Services\SubscriptionService::createDefaultSubscription($user);
        $maxBusinesses = \App\Services\SubscriptionService::getMaxBusinessesForSubscription($subscription->type);
        $currentBusinesses = $user->businesses()->count();

        return response()->json([
            'user' => $user,
            'is_super_admin' => $user->hasRole('super-admin'),
            'subscription_stats' => [
                'plan' => ucfirst($subscription->type),
                'current' => $currentBusinesses,
                'limit' => $maxBusinesses,
            ]
        ]);
    }

}
