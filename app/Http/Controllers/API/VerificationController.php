<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Auth\Events\Verified;

class VerificationController extends Controller
{
    /**
     * Marca el correo del usuario como verificado y lo redirige a la App de Flutter.
     */
    public function verify(Request $request, $id, $hash)
    {
        // 1. Buscamos el usuario
        $user = User::findOrFail($id);

        // 2. Validamos que el hash del click coincida con el hash de seguridad real de su correo
        if (!hash_equals((string) $hash, sha1($user->getEmailForVerification()))) {
            // Si alguien intentó hackear la URL
            return response()->json(['message' => 'El enlace de verificación es inválido o está corrupto.'], 403);
        }

        // 3. Si ya estaba verificado previamente, lo enviamos al éxito de Flutter directamente
        if ($user->hasVerifiedEmail()) {
            return redirect('https://chivimarket.arumasoft.com/cuenta-verificada');
        }

        // 4. Lo verificamos en la base de datos (Coloca la fecha actual en email_verified_at)
        if ($user->markEmailAsVerified()) {
            event(new Verified($user));
        }

        // 5. Redirección final hacia Flutter Web (Tu vista de éxito)
        return redirect('https://chivimarket.arumasoft.com/cuenta-verificada');
    }
}
