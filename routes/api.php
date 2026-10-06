<?php
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\API\BusinessController;
use App\Http\Controllers\API\ProductController;
use App\Http\Controllers\API\SubscriptionController;
use App\Http\Controllers\API\CategoryController;
use App\Http\Controllers\API\SearchController; // Nuevo controlador para bÃºsquedas globales
use App\Http\Controllers\Api\TestSwaggerController;
use App\Http\Controllers\API\BusinessLogoController;
use App\Http\Controllers\API\ProductImageController;
use App\Http\Controllers\API\ContactController;
use App\Http\Controllers\API\DiscountTokenController;
use App\Http\Controllers\API\TestPusherController;
use App\Http\Controllers\API\MessageController;
use App\Http\Controllers\API\ImageController;
use App\Http\Controllers\API\ActivationController;
use App\Http\Controllers\API\FavoriteController;
use App\Http\Controllers\API\BusinessRatingController;
use App\Http\Controllers\API\ProductRatingController;
use App\Http\Controllers\API\PromotionController;
use App\Http\Controllers\API\VoucherController;
use App\Http\Controllers\ShowerAdminController;
use App\Http\Resources\SubscriptionResource;
use App\Http\Resources\UserResource;
use App\Models\EspMessage;
use App\Models\Device;
use App\Models\AccessToken;
use Illuminate\Support\Str;

use App\Models\ReleActivation;
use App\Models\ActivationLog;
use App\Http\Controllers\DeviceController;

/* Bloque comentado eliminado para limpieza de rutas */



// =============================================
// RUTAS PÃšBLICAS (sin autenticaciÃ³n)
// =============================================
Route::post('/login', [AuthController::class, 'login']);
Route::post('/acceso-usuario', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);
Route::get('/explore/products', [\App\Http\Controllers\API\ProductController::class, 'explore']);
Route::get('/test', fn() => response()->json(['message' => 'Â¡API funcionando!']));
// CategorÃ­as (solo lectura para apps mÃ³viles)
Route::apiResource('business-categories', CategoryController::class)->only(['index', 'show']);
Route::apiResource('product-categories', \App\Http\Controllers\API\ProductCategoryController::class)->only(['index', 'show']);
// BÃºsqueda global y de productos (PÃšBLICAS)
Route::get('search', [SearchController::class, 'globalSearch']);
Route::get('products/search', [ProductController::class, 'search']);
Route::get('products/category/{category}', [ProductController::class, 'byCategory']);
Route::get('products/business/{business}', [ProductController::class, 'byBusiness']);
Route::get('products/{product}', [ProductController::class, 'show']);
// BÃºsqueda de negocios (PÃšBLICA)
Route::get('businesses/search', [BusinessController::class, 'search']); // <-- Mover esta lÃ­nea aquÃ­
Route::get('businesses/category/{category}', [BusinessController::class, 'byCategory']); // <-- TambiÃ©n mover esta lÃ­nea aquÃ­
Route::get('/businesses/top-rated', [BusinessController::class, 'getTopRatedBusinesses']);

Route::get('/business-image/{filename}', [ImageController::class, 'showBusinessImage']);
Route::get('/image/{filename}', [ImageController::class, 'show'])->name('image.show');


// =============================================
// RUTAS PROTEGIDAS (requieren autenticaciÃ³n)
// =============================================
Route::middleware('auth:sanctum')->group(function () {
    // AutenticaciÃ³n
    Route::post('/logout', [AuthController::class, 'logout']);
    /*Route::get('/user', function (Request $request) {
        return $request->user()->load(['roles', 'permissions', 'businesses', 'subscription']);
    });*/
    Route::get('/user', function (Request $request) {
        $user = $request->user()->load([
            'roles',
            'permissions',
            'businesses.categories',
            'businesses.images', // AsegÃºrate de cargar las imÃ¡genes de los negocios
            'subscription'
        ]);
        return new UserResource($user);
    })->middleware('auth:sanctum');



    // Usuarios (con permisos Spatie)
    Route::middleware('permission:create-users')->post('/users', [UserController::class, 'store']);
    Route::middleware('permission:view-users')->get('/users', [UserController::class, 'index']);

    // Negocios
    Route::apiResource('businesses', BusinessController::class);
    Route::get('businesses/nearby', [BusinessController::class, 'nearby']);
    Route::put('businesses/{business}/categories', [BusinessController::class, 'updateCategories']);
    Route::delete('businesses/{business}/categories/{category}', [BusinessController::class, 'removeCategory']);
    Route::post('businesses/{business}/categories/{category}', [BusinessController::class, 'addCategory']);
    Route::post('/businesses-with-images', [BusinessController::class, 'storeWithImages']);

    Route::post('/businesses/{business}/update2', [BusinessController::class, 'update2']);

    Route::post('/businesses/{business}/update', [BusinessController::class, 'update']);

    // Route::post('businesses/{business}/images', [\App\Http\Controllers\API\BusinessImageController::class, 'store']);

    Route::delete('businesses/{business}/images/{image}', [\App\Http\Controllers\API\BusinessImageController::class, 'destroy']);
    // Rutas para gestiÃ³n individual de imÃ¡genes de negocios (simplificadas)
    Route::post('/my-business/images/{position}', [BusinessController::class, 'updateMyBusinessImage']);
    Route::delete('/my-business/images/{position}', [BusinessController::class, 'deleteMyBusinessImage']);
    Route::get('/my-business/images/{position}', [BusinessController::class, 'getMyBusinessImage']);


    Route::get('/my-business/images', [BusinessController::class, 'listMyBusinessImages']);


    // Productos
    Route::apiResource('businesses.products', ProductController::class)->shallow();

    // Suscripciones
    Route::get('subscription', [SubscriptionController::class, 'show']);
    Route::post('subscription/upgrade', [SubscriptionController::class, 'upgrade']);

    // AdministraciÃ³n de categorÃ­as (requiere permiso adicional)
    Route::middleware('permission:manage-categories')->group(function () {
        Route::apiResource('business-categories', CategoryController::class)->only(['store', 'update', 'destroy']);
        Route::apiResource('product-categories', \App\Http\Controllers\API\ProductCategoryController::class)
            ->except(['index', 'show']);
    });
    Route::get('/subscription/check-business', [SubscriptionController::class, 'checkBusinessCreation']);
    Route::get('/subscription/check-product/{business}', [SubscriptionController::class, 'checkProductCreation']);
    Route::post('/subscription/change-plan', [SubscriptionController::class, 'changePlan']);
    Route::get('/subscription/status', [SubscriptionController::class, 'status']);
    Route::put('/subscription/upgrade', [SubscriptionController::class, 'upgrade']);

    // Favoritos
    Route::post('/favorites/businesses/{business}', [FavoriteController::class, 'toggleBusiness']);
    Route::post('/favorites/products/{product}', [FavoriteController::class, 'toggleProduct']);
    Route::get('/favorites', [FavoriteController::class, 'myFavorites']);

    Route::post('/track-contact', [ContactController::class, 'trackContact']);

    // Generar tokens de descuento
    Route::post('businesses/{business}/discount-tokens', [DiscountTokenController::class, 'store']);
    Route::get('users/me/discount-tokens', [DiscountTokenController::class, 'index']);

    // Usar y confirmar tokens
    Route::post('discount-tokens/{token}/use', [DiscountTokenController::class, 'useToken']);
    Route::post('discount-tokens/{token}/confirm', [DiscountTokenController::class, 'confirmUse']);

    Route::post('/conversations/start', [MessageController::class, 'startConversation']);

    // Enviar mensaje
    Route::post('/messages', [MessageController::class, 'sendMessage']);

    // Listar mensajes de una conversaciÃ³n
    Route::get('/conversations/{conversation}/messages', [MessageController::class, 'listMessages']);

    // Listar conversaciones del usuario
    Route::get('/conversations', [MessageController::class, 'listConversations']);

    //_______________________________DUCHA____________________________________

    /*Route::get('/shower/price', [ShowerAdminController::class, 'getPrice']);
    Route::post('/shower/price', [ShowerAdminController::class, 'updatePrice']);
    Route::get('/shower/usage', [ShowerAdminController::class, 'getUsageHistory']);
    Route::post('/shower/log-usage', [ShowerAdminController::class, 'logUsage']);*/

});

Route::get('/check-business/{business}', function (Request $request, Business $business) {
    $user = $request->user();
    return response()->json([
        'user_id' => $user->id,
        'business_user_id' => $business->user_id,
        'user_id_type' => gettype($user->id),
        'business_user_id_type' => gettype($business->user_id),
        'is_owner' => (int) $user->id === (int) $business->user_id
    ]);
})->middleware('auth:sanctum');

Route::post('businesses/{business}/images', [\App\Http\Controllers\API\BusinessImageController::class, 'store'])->middleware('auth:sanctum');

Route::patch('businesses/{business}/images/{image}', [\App\Http\Controllers\API\BusinessImageController::class, 'update'])->middleware('auth:sanctum');

// BÃºsqueda de negocios (PÃšBLICA)
Route::get('businesses/{business}', [BusinessController::class, 'show']);

Route::get('/test', [TestSwaggerController::class, 'index']);

Route::patch('businesses/{business}/images/reset-primary', [BusinessImageController::class, 'resetPrimary'])->middleware('auth:sanctum');

// Rutas para el logo del negocio (protegidas)
//Route::post('businesses/{business}/logo', [BusinessLogoController::class, 'store'])->middleware('auth:sanctum');
//Route::delete('businesses/{business}/logo', [BusinessLogoController::class, 'destroy'])->middleware('auth:sanctum');

Route::post('businesses/{business}/logo', [BusinessLogoController::class, 'store'])->middleware('auth:sanctum');
Route::delete('businesses/{business}/logo', [BusinessLogoController::class, 'destroy'])->middleware('auth:sanctum');

Route::post('products/{product}/images', [ProductImageController::class, 'store'])->middleware('auth:sanctum');
Route::get('products/{product}/images', [ProductImageController::class, 'index']);
Route::delete('products/{product}/images/{image}', [ProductImageController::class, 'destroy'])->middleware('auth:sanctum');
Route::patch('products/{product}/images/{image}/set-primary', [ProductImageController::class, 'setPrimary'])->middleware('auth:sanctum');

// Rutas PUBLICAS para leer calificaciones
Route::get('businesses/{business}/ratings', [BusinessRatingController::class, 'index']);
Route::get('products/{product}/ratings', [ProductRatingController::class, 'index']);

// Rutas PROTEGIDAS para publicar calificaciones
Route::middleware('auth:sanctum')->group(function () {
    Route::post('businesses/{business}/ratings', [BusinessRatingController::class, 'store']);
    Route::post('products/{product}/ratings', [ProductRatingController::class, 'store']);
});

// ----------------------------------------------------
// ECOSSISTEMA O2O / RPG (Promociones y Vouchers)
// ----------------------------------------------------
Route::get('businesses/{business}/promotions', [PromotionController::class, 'index']);
Route::get('products/{product}/promotions', [PromotionController::class, 'productPromotions']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('businesses/{business}/promotions', [PromotionController::class, 'store']);
    Route::put('promotions/{promotion}', [PromotionController::class, 'update']);
    Route::delete('promotions/{promotion}', [PromotionController::class, 'destroy']);

    Route::post('promotions/{promotion}/claim', [VoucherController::class, 'claim']);
    Route::get('vouchers/my-vouchers', [VoucherController::class, 'myVouchers']);
    Route::post('vouchers/redeem', [VoucherController::class, 'redeem']);
});


Route::get('/test-broadcast-config', function () {
    return [
        'default' => config('broadcasting.default'),
        'pusher_config' => config('broadcasting.connections.pusher'),
        'env_check' => [
            'app_id' => env('PUSHER_APP_ID'),
            'app_key' => env('PUSHER_APP_KEY'),
            'app_cluster' => env('PUSHER_APP_CLUSTER')
        ]
    ];
});

Route::post('/test-pusher/send', [TestPusherController::class, 'sendTestMessage']);

Route::get('/notifications', [MessageController::class, 'listNotifications'])
    ->middleware('auth:sanctum');

Route::post('/notifications/{notification}/read', [MessageController::class, 'markAsRead'])
    ->middleware('auth:sanctum');


Route::get('/esp32/message', function () {
    return response()->json([
        'message' => 'Â¡Hola desde Laravel, Santiago!',
        'color' => '0x07FF', // Color cyan en hexadecimal para la pantalla
        'action' => 'show_message' // AcciÃ³n que el ESP32 debe realizar
    ]);
});

// En routes/api.php
Route::get('/esp32/pending-messages', function () {
    $lastMessage = EspMessage::orderBy('created_at', 'desc')->first();

    if ($lastMessage) {
        return response()->json([
            'message' => $lastMessage->content,
            'color' => $lastMessage->color,
            'action' => 'show_message'
        ]);
    } else {
        return response()->json([
            'message' => 'No hay mensajes nuevos',
            'color' => '0xFFFF',
            'action' => 'no_action'
        ]);
    }
});

//Route::get('/validate-activation', [DeviceController::class, 'validateActivation']);

// routes/api.php
// routes/api.php
Route::get('/check-token', function (Request $request) {
    $deviceId = $request->input('device_id');

    \Log::info("CheckToken: Buscando token para device_id = " . $deviceId);

    $tokens = AccessToken::where('device_id', $deviceId)
        ->where('expires_at', '>', now())
        ->get();

    \Log::info("CheckToken: Tokens encontrados = " . $tokens->count());

    foreach ($tokens as $token) {
        \Log::info("CheckToken: Token ID = " . $token->id . ", token = " . $token->token . ", used = " . $token->used);
    }

    $token = AccessToken::where('device_id', $deviceId)
        ->where('expires_at', '>', now())
        ->where('used', false)
        ->first();

    if ($token) {
        $token->update(['used' => true]);
        \Log::info("CheckToken: Token vÃ¡lido encontrado y marcado como usado, ID = " . $token->id . ", token = " . $token->token);
        return response()->json([
            'status' => 'valid',
            'token' => $token->token
        ]);
    } else {
        \Log::info("CheckToken: No se encontrÃ³ un token vÃ¡lido");
        return response()->json(['status' => 'invalid']);
    }
});

Route::post('/shower-admin/login', [ShowerAdminController::class, 'login']);

Route::middleware(['auth:sanctum', 'shower.admin'])->group(function () {
    Route::get('/shower-admin/price', [ShowerAdminController::class, 'getPrice']);
    Route::post('/shower-admin/price', [ShowerAdminController::class, 'updatePrice']);
    Route::get('/shower-admin/usage', [ShowerAdminController::class, 'getUsageHistory']);
});














// Rutas de Google Socialite (Agregadas por el agente)
Route::post('/auth/google/verify', [\App\Http\Controllers\API\GoogleAuthController::class, 'verifyGoogleToken']);
Route::get('/auth/google', [\App\Http\Controllers\API\GoogleAuthController::class, 'handleGoogleRedirect']);
Route::get('/auth/google/callback', [\App\Http\Controllers\API\GoogleAuthController::class, 'handleGoogleCallback']);


// Ruta para validar email desde el link del correo (OBLIGATORIO que se llame verification.verify)
Route::get('/email/verify/{id}/{hash}', [\App\Http\Controllers\API\VerificationController::class, 'verify'])->name('verification.verify');

// Ruta oculta importador de MercadoLibre
Route::get('/admin/importar-ml', [\App\Http\Controllers\API\MLSyncController::class, 'importTopCategories']);

@

    // Perfil din�mico desde Flutter SDK
    Route::get('/me', [\App\Http\Controllers\AuthController::class, 'me'])->middleware('auth:sanctum');

@

    // ----------------------------------------------------
// RUTAS S�PER ADMINISTRADOR (God Mode)
// ----------------------------------------------------
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/admin/users', [\App\Http\Controllers\UserController::class, 'index']);
        Route::patch('/admin/users/{id}/subscription', [\App\Http\Controllers\UserController::class, 'updateSubscription']);

        // Gestión dinámica de alcances
        Route::get('/admin/subscription-plans', [\App\Http\Controllers\API\SubscriptionPlanController::class, 'index']);
        Route::patch('/admin/subscription-plans', [\App\Http\Controllers\API\SubscriptionPlanController::class, 'updateMassive']);
    });

