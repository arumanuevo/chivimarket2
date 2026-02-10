<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\BusinessCategory;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use App\Services\SubscriptionService;
use Illuminate\Support\Facades\DB; 
use App\Models\BusinessRating;
use Illuminate\Support\Facades\Log;

class BusinessController extends Controller
{
    use AuthorizesRequests;

    /**
     * @OA\Get(
     *     path="/api/businesses",
     *     summary="Listar negocios del usuario autenticado",
     *     description="Devuelve todos los negocios asociados al usuario autenticado, incluyendo sus categorías e imágenes.",
     *     tags={"Negocios"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Response(
     *         response=200,
     *         description="Lista de negocios del usuario",
     *         @OA\JsonContent(type="array", @OA\Items(ref="#/components/schemas/Business"))
     *     )
     * )
     */
    public function index()
    {
        $businesses = Auth::user()->businesses()->with(['categories', 'images'])->get();
        return response()->json($businesses);
    }

    /**
     * @OA\Get(
     *     path="/api/businesses/{business}",
     *     summary="Mostrar un negocio específico",
     *     description="Devuelve la información detallada de un negocio por su ID, incluyendo sus categorías, imágenes y productos (si el usuario autenticado es el dueño).",
     *     tags={"Negocios"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="business",
     *         in="path",
     *         required=true,
     *         description="ID del negocio",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Detalle del negocio",
     *         @OA\JsonContent(
     *             type="object",
     *             allOf={
     *                 @OA\Schema(ref="#/components/schemas/Business"),
     *                 @OA\Schema(
     *                     @OA\Property(
     *                         property="images",
     *                         type="array",
     *                         @OA\Items(
     *                             @OA\Property(property="id", type="integer", example=1),
     *                             @OA\Property(property="business_id", type="integer", example=1),
     *                             @OA\Property(property="url", type="string", example="http://tudominio.com/business_images/1.jpg"),
     *                             @OA\Property(property="is_primary", type="boolean", example=false),
     *                             @OA\Property(property="description", type="string", example="Imagen de la fachada"),
     *                             @OA\Property(property="created_at", type="string", format="date-time", example="2025-10-25T19:45:20.000000Z"),
     *                             @OA\Property(property="updated_at", type="string", format="date-time", example="2025-10-25T19:45:20.000000Z")
     *                         )
     *                     ),
     *                     @OA\Property(
     *                         property="first_image_url",
     *                         type="string",
     *                         example="http://tudominio.com/business_images/1.jpg",
     *                         description="URL de la primera imagen del negocio (o imagen por defecto si no hay imágenes)"
     *                     )
     *                 )
     *             }
     *         )
     *     )
     * )
     */
   /* public function show(Business $business)
    {
        // Cargar siempre las categorías e imágenes
        $business->load(['categories', 'images']);

        // Si el usuario autenticado es el dueño, también cargar los productos
        if (Auth::check() && Auth::user()->id === $business->id) {
            $business->load('products');
        }

        // Añadir la primera imagen (o imagen por defecto) al objeto raíz del negocio
        $firstImageUrl = null;
        if ($business->images->isNotEmpty()) {
            $firstImage = $business->images->first();
            $firstImageUrl = $firstImage->url;
        } else {
            $firstImageUrl = 'https://via.placeholder.com/300x200?text=Sin+Imagen';
        }
        $business->first_image_url = $firstImageUrl;

        return response()->json($business);
    }*/

    public function show(Business $business)
    {
        // Cargar siempre las categorías e imágenes
        $business->load(['categories', 'images']);

        // Si el usuario autenticado es el dueño, también cargar los productos
        if (Auth::check() && Auth::user()->id === $business->user_id) {
            $business->load('products');
        }

        return response()->json(new BusinessResource($business));
    }

/**
 * @OA\Post(
 *     path="/api/businesses",
 *     summary="Crear un nuevo negocio",
 *     description="Crear un nuevo negocio asociado al usuario autenticado. Valida el límite de negocios según la suscripción del usuario.",
 *     tags={"Negocios"},
 *     security={{"bearerAuth": {}}},
 *     @OA\RequestBody(
 *         required=true,
 *         @OA\MediaType(
 *             mediaType="multipart/form-data",
 *             @OA\Schema(
 *                 required={"name", "address"},
 *                 @OA\Property(property="name", type="string", example="Panadería San Jorge"),
 *                 @OA\Property(property="description", type="string", example="Panadería artesanal con más de 20 años de experiencia"),
 *                 @OA\Property(property="address", type="string", example="Calle Falsa 123"),
 *                 @OA\Property(property="latitude", type="number", format="float", nullable=true, example=-34.6037),
 *                 @OA\Property(property="longitude", type="number", format="float", nullable=true, example=-58.3816),
 *                 @OA\Property(property="categories", type="array", @OA\Items(type="integer", example=1)),
 *                 @OA\Property(property="cover_image", type="string", format="binary", description="Imagen de portada del negocio")
 *             )
 *         )
 *     ),
 *     @OA\Response(
 *         response=201,
 *         description="Negocio creado correctamente",
 *         @OA\JsonContent(ref="#/components/schemas/Business")
 *     ),
 *     @OA\Response(
 *         response=403,
 *         description="No autorizado para crear más negocios según su suscripción"
 *     ),
 *     @OA\Response(
 *         response=422,
 *         description="Error de validación de los datos enviados"
 *     )
 * )
 */
public function store(Request $request)
{
    $user = Auth::user();
    $subscriptionCheck = SubscriptionService::canCreateBusiness($user);

    if (!$subscriptionCheck['can_create']) {
        return response()->json([
            'message' => $subscriptionCheck['message']
        ], 403);
    }

    // Logs para depuración (opcional, puedes comentarlos o eliminarlos)
    Log::info('Datos recibidos en la solicitud:', ['data' => $request->all()]);
    Log::info('Tipo de categories:', ['type' => gettype($request->categories)]);
    Log::info('Valor de categories:', ['value' => $request->categories]);

    // Convertir 'categories' de string a array si es necesario
    if ($request->has('categories') && is_string($request->categories)) {
        $categories = json_decode($request->categories, true);
        $request->merge(['categories' => $categories]);
    }

    // Validación de datos del negocio
    $validator = Validator::make($request->all(), [
        'name' => [
            'required',
            'string',
            'max:255',
            Rule::unique('businesses')->where(function ($query) use ($user) {
                return $query->where('user_id', $user->id);
            })
        ],
        'description' => 'nullable|string',
        'address' => 'required|string',
        'latitude' => 'nullable|numeric|between:-90,90',
        'longitude' => 'nullable|numeric|between:-180,180',
        'categories' => 'nullable|array',
        'categories.*' => 'exists:business_categories,id',
        'cover_image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
    ]);

    if ($validator->fails()) {
        return response()->json($validator->errors(), 422);
    }

    // Crear el negocio
    $businessData = $request->except('categories', 'cover_image');
    $businessData['user_id'] = $user->id;
    $business = Business::create($businessData);

    // Asignar categorías si existen
    if ($request->has('categories')) {
        $business->categories()->attach($request->categories);
    }

    // Manejar la imagen de portada
    if ($request->hasFile('cover_image')) {
        $imageFile = $request->file('cover_image');
        $filename = uniqid() . '.' . $imageFile->getClientOriginalExtension();
        $imageFile->move(public_path('business_covers'), $filename);
        $business->cover_image_url = 'business_covers/' . $filename;
        $business->save();
    }

    return response()->json($business->load('categories'), 201);
}



    /**
     * @OA\Put(
     *     path="/api/businesses/{business}",
     *     summary="Actualizar un negocio",
     *     description="Actualiza la información de un negocio. Solo el dueño del negocio puede actualizarlo.",
     *     tags={"Negocios"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="business",
     *         in="path",
     *         required=true,
     *         description="ID del negocio",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="name", type="string", example="Panadería San Jorge (Actualizado)"),
     *             @OA\Property(property="description", type="string", example="Panadería artesanal con más de 25 años de experiencia"),
     *             @OA\Property(property="address", type="string", example="Calle Falsa 456"),
     *             @OA\Property(property="latitude", type="number", format="float", nullable=true, example=-34.6037),
     *             @OA\Property(property="longitude", type="number", format="float", nullable=true, example=-58.3816),
     *             @OA\Property(property="categories", type="array", @OA\Items(type="integer", example=1))
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Negocio actualizado correctamente",
     *         @OA\JsonContent(ref="#/components/schemas/Business")
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado para actualizar este negocio"
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Error de validación de los datos enviados"
     *     )
     * )
     */
    public function update(Request $request, Business $business)
    {
        $this->authorize('update', $business);

        $validator = Validator::make($request->all(), [
            'name' => [
                'sometimes',
                'required',
                'string',
                'max:255',
                Rule::unique('businesses')->ignore($business->id)->where(function ($query) {
                    return $query->where('user_id', Auth::id());
                })
            ],
            'description' => 'nullable|string',
            'address' => 'sometimes|required|string',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'categories' => 'nullable|array',
            'categories.*' => 'exists:business_categories,id'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $business->update($request->except('categories'));

        if ($request->has('categories')) {
            $business->categories()->sync($request->categories);
        }

        return response()->json($business->fresh()->load('categories'));
    }

    /**
     * @OA\Delete(
     *     path="/api/businesses/{business}",
     *     summary="Eliminar un negocio",
     *     description="Elimina un negocio existente. Solo el dueño del negocio puede eliminarlo.",
     *     tags={"Negocios"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="business",
     *         in="path",
     *         required=true,
     *         description="ID del negocio",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Negocio eliminado correctamente",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="message", type="string", example="Negocio eliminado correctamente")
     *         )
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado para eliminar este negocio"
     *     )
     * )
     */
    public function destroy(Business $business)
    {
        $this->authorize('update', $business);
    
        // Registrar los datos del negocio en los logs para depuración
        Log::info('Datos del negocio a eliminar:', [
            'business_id' => $business->id,
            'business_data' => $business->toArray(),
        ]);
    

         $business->delete();
         return response()->json(['message' => 'Negocio eliminado correctamente']);
    }

    /**
     * @OA\Delete(
     *     path="/api/businesses/{business}/categories/{category}",
     *     summary="Eliminar una categoría de un negocio",
     *     description="Elimina una categoría específica de un negocio. Solo el dueño del negocio puede realizar esta acción.",
     *     tags={"Negocios"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="business",
     *         in="path",
     *         required=true,
     *         description="ID del negocio",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Parameter(
     *         name="category",
     *         in="path",
     *         required=true,
     *         description="ID de la categoría",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Categoría eliminada del negocio correctamente",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="message", type="string", example="Categoría eliminada del negocio correctamente"),
     *             @OA\Property(property="business", ref="#/components/schemas/Business")
     *         )
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado para eliminar categorías de este negocio"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="El negocio no tiene asignada esta categoría"
     *     )
     * )
     */
    public function removeCategory(Business $business, BusinessCategory $category)
    {
        $this->authorize('update', $business);

        if (!$business->categories->contains($category)) {
            return response()->json([
                'message' => 'El negocio no tiene asignada esta categoría'
            ], 404);
        }

        $business->categories()->detach($category->id);
        return response()->json([
            'message' => 'Categoría eliminada del negocio correctamente',
            'business' => $business->load('categories')
        ]);
    }

    /**
     * @OA\Put(
     *     path="/api/businesses/{business}/categories",
     *     summary="Actualizar las categorías de un negocio",
     *     description="Actualiza todas las categorías asociadas a un negocio. Solo el dueño del negocio puede realizar esta acción.",
     *     tags={"Negocios"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="business",
     *         in="path",
     *         required=true,
     *         description="ID del negocio",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="categories", type="array", @OA\Items(type="integer", example=1))
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Categorías actualizadas correctamente",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="message", type="string", example="Categorías actualizadas correctamente"),
     *             @OA\Property(property="business", ref="#/components/schemas/Business")
     *         )
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado para actualizar categorías de este negocio"
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Error de validación de los datos enviados"
     *     )
     * )
     */
    public function updateCategories(Request $request, Business $business)
    {
        $this->authorize('update', $business);

        $validator = Validator::make($request->all(), [
            'categories' => 'required|array',
            'categories.*' => 'exists:business_categories,id'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Error de validación',
                'errors' => $validator->errors()
            ], 422);
        }

        $business->categories()->sync($request->categories);
        return response()->json([
            'message' => 'Categorías actualizadas correctamente',
            'business' => $business->fresh()->load('categories')
        ]);
    }
    /**
     * @OA\Get(
     *     path="/api/businesses/search",
     *     summary="Buscar negocios",
     *     description="Busca negocios por nombre, categoría o ubicación.",
     *     tags={"Negocios"},
     *     @OA\Parameter(name="name", in="query", required=false, description="Nombre del negocio", @OA\Schema(type="string")),
     *     @OA\Parameter(name="category", in="query", required=false, description="ID de la categoría", @OA\Schema(type="integer")),
     *     @OA\Parameter(name="lat", in="query", required=false, description="Latitud para búsqueda por ubicación", @OA\Schema(type="number", format="float")),
     *     @OA\Parameter(name="lng", in="query", required=false, description="Longitud para búsqueda por ubicación", @OA\Schema(type="number", format="float")),
     *     @OA\Parameter(name="radius", in="query", required=false, description="Radio de búsqueda en metros", @OA\Schema(type="integer")),
     *     @OA\Response(
     *         response=200,
     *         description="Lista de negocios encontrados",
     *         @OA\JsonContent(type="array", @OA\Items(ref="#/components/schemas/Business"))
     *     )
     * )
     */
    public function search(Request $request)
    {
        $query = Business::query()->with(['categories', 'images']);

        if ($request->has('name')) {
            $query->where('name', 'like', '%' . $request->name . '%');
        }

        if ($request->has('category')) {
            $query->whereHas('categories', function($q) use ($request) {
                $q->where('business_category.category_id', $request->category);
            });
        }

        if ($request->has(['lat', 'lng'])) {
            $lat = $request->lat;
            $lng = $request->lng;
            $radius = $request->get('radius', 10000);
            $query->selectRaw("*, (6371 * ACOS(COS(RADIANS(?)) * COS(RADIANS(latitude)) * COS(RADIANS(longitude) - RADIANS(?)) + SIN(RADIANS(?)) * SIN(RADIANS(latitude)))) AS distance", [$lat, $lng, $lat])
                ->having('distance', '<=', $radius)
                ->orderBy('distance');
        }

        return response()->json($query->get());
    }

    /**
     * @OA\Get(
     *     path="/api/businesses/nearby",
     *     summary="Negocios cercanos",
     *     description="Devuelve los negocios cercanos a una ubicación específica, dentro de un radio determinado.",
     *     tags={"Negocios"},
     *     @OA\Parameter(name="lat", in="query", required=true, description="Latitud", @OA\Schema(type="number", format="float")),
     *     @OA\Parameter(name="lng", in="query", required=true, description="Longitud", @OA\Schema(type="number", format="float")),
     *     @OA\Parameter(name="radius", in="query", required=false, description="Radio de búsqueda en metros (por defecto: 10000)", @OA\Schema(type="integer")),
     *     @OA\Response(
     *         response=200,
     *         description="Lista de negocios cercanos",
     *         @OA\JsonContent(type="array", @OA\Items(ref="#/components/schemas/Business"))
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Error de validación de los parámetros de ubicación"
     *     )
     * )
     */
    public function nearby(Request $request)
    {
        $request->validate([
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
            'radius' => 'nullable|numeric|min:100|max:50000'
        ]);

        $lat = $request->lat;
        $lng = $request->lng;
        $radius = $request->get('radius', 10000);

        $businesses = Business::selectRaw("*, (6371 * ACOS(COS(RADIANS(?)) * COS(RADIANS(latitude)) * COS(RADIANS(longitude) - RADIANS(?)) + SIN(RADIANS(?)) * SIN(RADIANS(latitude)))) AS distance", [$lat, $lng, $lat])
            ->having('distance', '<=', $radius)
            ->orderBy('distance')
            ->with(['categories', 'images'])
            ->get();

        return response()->json($businesses);
    }

    /**
     * @OA\Get(
     *     path="/api/businesses/category/{category}",
     *     summary="Negocios por categoría",
     *     description="Devuelve todos los negocios que pertenecen a una categoría específica.",
     *     tags={"Negocios"},
     *     @OA\Parameter(
     *         name="category",
     *         in="path",
     *         required=true,
     *         description="ID de la categoría",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Lista de negocios en la categoría",
     *         @OA\JsonContent(type="array", @OA\Items(ref="#/components/schemas/Business"))
     *     )
     * )
     */
    public function byCategory($categoryId)
    {
        $businesses = Business::whereHas('categories', function($q) use ($categoryId) {
            $q->where('business_category.category_id', $categoryId);
        })->with(['categories', 'images'])->get();

        return response()->json($businesses);
    }

    public function contactStats(Business $business)
    {
        $this->authorize('view', $business);

        $last30Days = DB::table('contacts')
            ->where('contactable_type', 'business')
            ->where('contactable_id', $business->id)
            ->where('created_at', '>=', now()->subDays(30))
            ->select(DB::raw('DATE(created_at) as date'), DB::raw('COUNT(*) as count'))
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        $byType = DB::table('contacts')
            ->where('contactable_type', 'business')
            ->where('contactable_id', $business->id)
            ->where('created_at', '>=', now()->subDays(30))
            ->select('contact_type', DB::raw('COUNT(*) as count'))
            ->groupBy('contact_type')
            ->get();

        return response()->json([
            'last_30_days' => $last30Days,
            'by_type' => $byType,
            'total' => $last30Days->sum('count')
        ]);
    }

/**
 * @OA\Get(
 *     path="/api/businesses/top-rated",
 *     summary="Listar negocios por calificación",
 *     description="Devuelve una lista de negocios ordenados por su calificación promedio (de mayor a menor).
 *                  Incluye la primera imagen del negocio (o una imagen por defecto si no hay imágenes).",
 *     tags={"Negocios"},
 *     @OA\Parameter(
 *         name="limit",
 *         in="query",
 *         description="Límite de negocios a devolver (opcional, por defecto: 10).",
 *         required=false,
 *         @OA\Schema(type="integer", default=10, example=5)
 *     ),
 *     @OA\Parameter(
 *         name="category_id",
 *         in="query",
 *         description="ID de la categoría para filtrar negocios (opcional).",
 *         required=false,
 *         @OA\Schema(type="integer", example=1)
 *     ),
 *     @OA\Response(
 *         response=200,
 *         description="Lista de negocios ordenados por calificación (éxito).",
 *         @OA\JsonContent(
 *             type="object",
 *             @OA\Property(
 *                 property="data",
 *                 type="array",
 *                 @OA\Items(
 *                     allOf={
 *                         @OA\Schema(ref="#/components/schemas/Business"),
 *                         @OA\Schema(
 *                             @OA\Property(property="avg_rating", type="number", format="float", example=4.5, description="Promedio de calificaciones del negocio"),
 *                             @OA\Property(property="ratings_count", type="integer", example=25, description="Cantidad total de calificaciones"),
 *                             @OA\Property(property="first_image_url", type="string", example="http://tudominio.com/business_images/1.jpg", description="URL de la primera imagen del negocio (o imagen por defecto si no hay imágenes)")
 *                         )
 *                     }
 *                 )
 *             ),
 *             @OA\Property(property="links", type="object", description="Enlaces de paginación"),
 *             @OA\Property(property="meta", type="object", description="Metadatos de la paginación")
 *         )
 *     )
 * )
 */
public function getTopRatedBusinesses(Request $request)
{
    $limit = $request->input('limit', 10);
    $categoryId = $request->input('category_id');

    // Subconsulta para calcular el promedio de calificaciones
    $avgRatingSubQuery = \App\Models\BusinessRating::select('business_id', DB::raw('AVG(rating) as avg_rating'))
        ->groupBy('business_id');

    // Subconsulta para contar las calificaciones
    $ratingsCountSubQuery = \App\Models\BusinessRating::select('business_id', DB::raw('COUNT(*) as ratings_count'))
        ->groupBy('business_id');

    $query = Business::query()
        ->leftJoinSub($avgRatingSubQuery, 'avg_ratings', function($join) {
            $join->on('businesses.id', '=', 'avg_ratings.business_id');
        })
        ->leftJoinSub($ratingsCountSubQuery, 'ratings_counts', function($join) {
            $join->on('businesses.id', '=', 'ratings_counts.business_id');
        })
        ->with(['user', 'categories', 'images' => function($query) {
            $query->orderBy('is_primary', 'desc')->limit(1); // Optimizar: cargar solo la primera imagen
        }])
        ->select([
            'businesses.*',
            DB::raw('COALESCE(avg_ratings.avg_rating, 0) as avg_rating'),
            DB::raw('COALESCE(ratings_counts.ratings_count, 0) as ratings_count')
        ]);

    if ($categoryId) {
        $query->whereHas('categories', function($q) use ($categoryId) {
            $q->where('business_category.category_id', $categoryId);
        });
    }

    $businesses = $query->orderBy('avg_rating', 'desc')
        ->orderBy('ratings_count', 'desc')
        ->paginate($limit);

    // Añadir la primera imagen (o imagen por defecto) a cada negocio
    $businesses->getCollection()->transform(function ($business) {
        $firstImageUrl = null;

        // Si el negocio tiene imágenes, usar la primera
        if ($business->images->isNotEmpty()) {
            $firstImage = $business->images->first();
            $firstImageUrl = $firstImage->url;
        }

        // Si no tiene imágenes, usar una imagen por defecto
        if (!$firstImageUrl) {
            $firstImageUrl = 'https://via.placeholder.com/300x200?text=Sin+Imagen'; // Imagen por defecto
        }

        // Añadir la URL de la primera imagen al objeto raíz del negocio
        $business->first_image_url = $firstImageUrl;

        return $business;
    });

    return response()->json($businesses);
}

/**
 * @OA\Post(
 *     path="/api/businesses/{business}/cover-image",
 *     summary="Subir o actualizar la imagen de portada de un negocio",
 *     description="Sube o actualiza la imagen de portada de un negocio específico. Solo el dueño del negocio puede subir imágenes. La imagen se redimensiona automáticamente a 1200x630 píxeles (proporción 16:9) para optimizar el almacenamiento y la visualización.",
 *     tags={"Negocios"},
 *     security={{"bearerAuth": {}}},
 *     @OA\Parameter(
 *         name="business",
 *         in="path",
 *         required=true,
 *         description="ID del negocio",
 *         @OA\Schema(type="integer")
 *     ),
 *     @OA\RequestBody(
 *         required=true,
 *         description="Imagen de portada",
 *         @OA\MediaType(
 *             mediaType="multipart/form-data",
 *             @OA\Schema(
 *                 required={"cover_image"},
 *                 @OA\Property(property="cover_image", type="string", format="binary", description="Archivo de imagen de portada (JPEG, PNG, JPG, GIF). Máximo 2MB.")
 *             )
 *         )
 *     ),
 *     @OA\Response(
 *         response=200,
 *         description="Imagen de portada subida correctamente",
 *         @OA\JsonContent(ref="#/components/schemas/Business")
 *     ),
 *     @OA\Response(
 *         response=403,
 *         description="No autorizado para subir imágenes a este negocio"
 *     ),
 *     @OA\Response(
 *         response=422,
 *         description="Error de validación de los datos enviados"
 *     )
 * )
 */
public function updateCoverImage(Request $request, Business $business)
{
    $this->authorize('update', $business);

    $validator = Validator::make($request->all(), [
        'cover_image' => 'required|image|mimes:jpeg,png,jpg|max:2048',
    ]);

    if ($validator->fails()) {
        return response()->json($validator->errors(), 422);
    }

    try {
        // Eliminar la imagen anterior si existe
        if ($business->cover_image_url) {
            $oldImagePath = public_path($business->cover_image_url);
            if (file_exists($oldImagePath)) {
                unlink($oldImagePath);
            }
        }

        // Verificar si Intervention Image está disponible
        if (!class_exists('Intervention\Image\Facades\Image')) {
            throw new \Exception('Intervention Image no está disponible en este servidor.');
        }

        // Procesar la imagen
        $imageFile = $request->file('cover_image');
        $img = Image::make($imageFile->getRealPath());

        // Redimensionar a 1200x630 (16:9)
        $img->resize(1200, 630, function ($constraint) {
            $constraint->aspectRatio();
            $constraint->upsize();
        });

        // Guardar la imagen
        $filename = uniqid() . '.' . $imageFile->getClientOriginalExtension();
        $img->save(public_path('business_covers/' . $filename), 85);

        // Actualizar el modelo
        $business->cover_image_url = 'business_covers/' . $filename;
        $business->save();

        return response()->json([
            'message' => 'Imagen de portada actualizada correctamente',
            'business' => $business
        ]);

    } catch (\Exception $e) {
        return response()->json([
            'message' => 'Error al procesar la imagen: ' . $e->getMessage()
        ], 500);
    }
}




}
