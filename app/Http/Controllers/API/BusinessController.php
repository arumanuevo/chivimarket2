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
     *     description="Devuelve la información detallada de un negocio por su ID. Si el usuario autenticado es el dueño, también incluye los productos del negocio.",
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
     *         @OA\JsonContent(ref="#/components/schemas/Business")
     *     )
     * )
     */
    public function show(Business $business)
    {
        if (Auth::check() && Auth::user()->id === $business->user_id) {
            return response()->json($business->load(['categories', 'images', 'products']));
        }
        return response()->json($business->load(['categories', 'images']));
    }

    /**
     * @OA\Post(
     *     path="/api/businesses",
     *     summary="Crear un nuevo negocio",
     *     description="Crea un nuevo negocio asociado al usuario autenticado. Valida el límite de negocios según la suscripción del usuario.",
     *     tags={"Negocios"},
     *     security={{"bearerAuth": {}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="name", type="string", example="Panadería San Jorge"),
     *             @OA\Property(property="description", type="string", example="Panadería artesanal con más de 20 años de experiencia"),
     *             @OA\Property(property="address", type="string", example="Calle Falsa 123"),
     *             @OA\Property(property="latitude", type="number", format="float", nullable=true, example=-34.6037),
     *             @OA\Property(property="longitude", type="number", format="float", nullable=true, example=-58.3816),
     *             @OA\Property(property="categories", type="array", @OA\Items(type="integer", example=1))
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
            'categories.*' => 'exists:business_categories,id'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        // Crear el negocio
        $businessData = $request->except('categories');
        $businessData['user_id'] = $user->id;
        $business = Business::create($businessData);

        // Asignar categorías si existen
        if ($request->has('categories')) {
            $business->categories()->attach($request->categories);
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
}
