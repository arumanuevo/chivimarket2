<?php
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\API\BusinessController;
use App\Http\Controllers\API\ProductController;
use App\Http\Controllers\API\SubscriptionController;
use App\Http\Controllers\API\CategoryController;
use App\Http\Controllers\API\SearchController; // Nuevo controlador para búsquedas globales
use App\Http\Controllers\Api\TestSwaggerController;
use App\Http\Controllers\API\BusinessLogoController;
use App\Http\Controllers\API\ProductImageController;
use App\Http\Controllers\API\ContactController;
use App\Http\Controllers\API\DiscountTokenController;
use App\Http\Controllers\API\TestPusherController;
use App\Http\Controllers\API\MessageController;
use App\Http\Controllers\API\ImageController;
use App\Http\Controllers\API\ActivationController;
use App\Http\Resources\SubscriptionResource;
use App\Http\Resources\UserResource;
use App\Models\EspMessage;
use App\Models\Device;
use App\Models\AccessToken;
use Illuminate\Support\Str;

use App\Models\ReleActivation;
use App\Models\ActivationLog;
use App\Http\Controllers\DeviceController;

/*
// =============================================
// RUTAS PÚBLICAS (sin autenticación)
// =============================================
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);
Route::get('/test', fn() => response()->json(['message' => '¡API funcionando!']));

// Categorías (solo lectura para apps móviles)
Route::apiResource('business-categories', CategoryController::class)->only(['index', 'show']);
Route::apiResource('product-categories', CategoryController::class)->only(['index', 'show']);

// =============================================
// RUTAS PROTEGIDAS (requieren autenticación)
// =============================================
Route::middleware('auth:sanctum')->group(function () {
    // Autenticación
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', function (Request $request) {
        return $request->user()->load(['roles', 'permissions', 'businesses', 'subscription']);
    });

    // Usuarios (con permisos Spatie)
    Route::middleware('permission:create-users')->post('/users', [UserController::class, 'store']);
    Route::middleware('permission:view-users')->get('/users', [UserController::class, 'index']);

    // Negocios y productos
    //Route::apiResource('businesses', BusinessController::class);
    Route::apiResource('businesses.products', ProductController::class)->shallow();

    // Suscripciones
    Route::get('subscription', [SubscriptionController::class, 'show']);
    Route::post('subscription/upgrade', [SubscriptionController::class, 'upgrade']);

    // Administración de categorías (requiere permiso adicional)
    Route::middleware('permission:manage-categories')->group(function () {
        Route::apiResource('business-categories', CategoryController::class)->only(['store']);
        Route::apiResource('business-categories', CategoryController::class)->only(['update', 'destroy']);
    });
    Route::post('businesses/{business}/images', [\App\Http\Controllers\API\BusinessImageController::class, 'store']);
    Route::delete('businesses/{business}/images/{image}', [\App\Http\Controllers\API\BusinessImageController::class, 'destroy']);
    Route::delete('businesses/{business}/categories/{category}', [\App\Http\Controllers\API\BusinessController::class, 'removeCategory']);
    Route::put('businesses/{business}/categories', [\App\Http\Controllers\API\BusinessController::class, 'updateCategories']);

    Route::apiResource('product-categories', \App\Http\Controllers\API\ProductCategoryController::class)
        ->except(['index', 'show']);
    
    Route::get('businesses/search', [BusinessController::class, 'search']);
    Route::get('businesses/nearby', [BusinessController::class, 'nearby']);
    Route::get('businesses/category/{category}', [BusinessController::class, 'byCategory']);

    Route::resource('businesses', BusinessController::class)->only([
        'index', 'store', 'update', 'destroy'  // Excluye 'show'
    ]);
        
});

Route::apiResource('product-categories', \App\Http\Controllers\API\ProductCategoryController::class)
    ->only(['index', 'show']);*/

    
    
// =============================================
// RUTAS PÚBLICAS (sin autenticación)
// =============================================
Route::post('/login', [AuthController::class, 'login']);
Route::post('/acceso-usuario', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);
Route::get('/test', fn() => response()->json(['message' => '¡API funcionando!']));
// Categorías (solo lectura para apps móviles)
Route::apiResource('business-categories', CategoryController::class)->only(['index', 'show']);
Route::apiResource('product-categories', \App\Http\Controllers\API\ProductCategoryController::class)->only(['index', 'show']);
// Búsqueda global y de productos (PÚBLICAS)
Route::get('search', [SearchController::class, 'globalSearch']);
Route::get('products/search', [ProductController::class, 'search']);
Route::get('products/category/{category}', [ProductController::class, 'byCategory']);
Route::get('products/business/{business}', [ProductController::class, 'byBusiness']);
Route::get('products/{product}', [ProductController::class, 'show']);
// Búsqueda de negocios (PÚBLICA)
Route::get('businesses/search', [BusinessController::class, 'search']); // <-- Mover esta línea aquí
Route::get('businesses/category/{category}', [BusinessController::class, 'byCategory']); // <-- También mover esta línea aquí
Route::get('/businesses/top-rated', [BusinessController::class, 'getTopRatedBusinesses']);

Route::get('/api/business-image/{filename}', [ImageController::class, 'showBusinessImage']);
Route::get('/image/{filename}', [ImageController::class, 'show'])->name('image.show');

// =============================================
// RUTAS PROTEGIDAS (requieren autenticación)
// =============================================
Route::middleware('auth:sanctum')->group(function () {
    // Autenticación
    Route::post('/logout', [AuthController::class, 'logout']);
    /*Route::get('/user', function (Request $request) {
        return $request->user()->load(['roles', 'permissions', 'businesses', 'subscription']);
    });*/
    Route::get('/user', function (Request $request) {
        $user = $request->user()->load([
            'roles',
            'permissions',
            'businesses.categories',
            'businesses.images', // Asegúrate de cargar las imágenes de los negocios
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
    Route::post('/businesses-with-images', [BusinessController::class, 'storeWithImages'])->middleware('auth:sanctum');

   // Route::post('businesses/{business}/images', [\App\Http\Controllers\API\BusinessImageController::class, 'store']);

    Route::delete('businesses/{business}/images/{image}', [\App\Http\Controllers\API\BusinessImageController::class, 'destroy']);

    // Productos
    Route::apiResource('businesses.products', ProductController::class)->shallow();

    // Suscripciones
    Route::get('subscription', [SubscriptionController::class, 'show']);
    Route::post('subscription/upgrade', [SubscriptionController::class, 'upgrade']);

    // Administración de categorías (requiere permiso adicional)
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

    // Listar mensajes de una conversación
    Route::get('/conversations/{conversation}/messages', [MessageController::class, 'listMessages']);

    // Listar conversaciones del usuario
    Route::get('/conversations', [MessageController::class, 'listConversations']);
    
});

Route::get('/check-business/{business}', function (Request $request, Business $business) {
    $user = $request->user();
    return response()->json([
        'user_id' => $user->id,
        'business_user_id' => $business->user_id,
        'user_id_type' => gettype($user->id),
        'business_user_id_type' => gettype($business->user_id),
        'is_owner' => (int)$user->id === (int)$business->user_id
    ]);
})->middleware('auth:sanctum');

Route::post('businesses/{business}/images', [\App\Http\Controllers\API\BusinessImageController::class, 'store'])->middleware('auth:sanctum');

Route::patch('businesses/{business}/images/{image}', [\App\Http\Controllers\API\BusinessImageController::class, 'update'])->middleware('auth:sanctum');

// Búsqueda de negocios (PÚBLICA)
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

// Rutas para calificaciones de negocios
Route::middleware('auth:sanctum')->group(function () {
    Route::post('businesses/{business}/ratings', [BusinessRatingController::class, 'store']);
    Route::get('businesses/{business}/ratings', [BusinessRatingController::class, 'index']);
});

// Rutas para calificaciones de productos
Route::middleware('auth:sanctum')->group(function () {
    Route::post('products/{product}/ratings', [ProductRatingController::class, 'store']);
    Route::get('products/{product}/ratings', [ProductRatingController::class, 'index']);
});


Route::get('/test-broadcast-config', function() {
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
            'message' => '¡Hola desde Laravel, Santiago!',
            'color' => '0x07FF', // Color cyan en hexadecimal para la pantalla
            'action' => 'show_message' // Acción que el ESP32 debe realizar
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
        \Log::info("CheckToken: Token válido encontrado y marcado como usado, ID = " . $token->id . ", token = " . $token->token);
        return response()->json([
            'status' => 'valid',
            'token' => $token->token
        ]);
    } else {
        \Log::info("CheckToken: No se encontró un token válido");
        return response()->json(['status' => 'invalid']);
    }
});










    


