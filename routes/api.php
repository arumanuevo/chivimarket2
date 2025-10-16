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

    // Negocios
    Route::apiResource('businesses', BusinessController::class);
    Route::get('businesses/nearby', [BusinessController::class, 'nearby']);
    Route::put('businesses/{business}/categories', [BusinessController::class, 'updateCategories']);
    Route::delete('businesses/{business}/categories/{category}', [BusinessController::class, 'removeCategory']);
    Route::post('businesses/{business}/categories/{category}', [BusinessController::class, 'addCategory']);
    Route::post('businesses/{business}/images', [\App\Http\Controllers\API\BusinessImageController::class, 'store']);

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




    


