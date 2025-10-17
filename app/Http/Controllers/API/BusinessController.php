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

class BusinessController extends Controller
{
    use AuthorizesRequests;
    // Listar negocios del usuario autenticado
    public function index()
    {
        $businesses = Auth::user()->businesses()->with(['categories', 'images'])->get();
        return response()->json($businesses);
    }

    // Mostrar un negocio específico
    public function show(Business $business)
    {
        //$this->authorize('view', $business);
        if (Auth::check() && Auth::user()->id === $business->user_id) {
            return response()->json($business->load(['categories', 'images', 'products']));
        }
        return response()->json($business->load(['categories', 'images']));
        //return response()->json($business->load(['categories', 'images', 'products']));
    }

 

    public function store(Request $request)
{
    $user = Auth::user();
    $subscription = $user->subscription;

    // Validar límite de negocios según suscripción
    $maxBusinesses = $subscription ? $this->getMaxBusinessesForSubscription($subscription->type) : 1;
    if ($user->businesses()->count() >= $maxBusinesses) {
        return response()->json([
            'message' => sprintf(
                'Has alcanzado el límite de %d negocios para tu plan (%s). Actualiza tu suscripción para crear más negocios.',
                $maxBusinesses,
                $subscription ? $subscription->type : 'free'
            )
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
     * Obtener el límite de negocios según el tipo de suscripción.
     */
    protected function getMaxBusinessesForSubscription($subscriptionType)
    {
        $limits = [
            'free' => 1,      // Usuarios free pueden tener 1 negocio
            'basic' => 3,     // Usuarios basic pueden tener 3 negocios
            'premium' => 10,   // Usuarios premium pueden tener 10 negocios
            'enterprise' => 50 // Usuarios enterprise pueden tener 50 negocios
        ];

        return $limits[$subscriptionType] ?? 1; // Default: 1 (si no existe el tipo)
    }


    // Actualizar un negocio
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

    // Eliminar un negocio
    public function destroy(Business $business)
    {
        $this->authorize('update', $business);
        $business->delete();
        return response()->json(['message' => 'Negocio eliminado correctamente']);
    }
   


    /**
     * Eliminar una categoría de un negocio.
     *
     * @param  \App\Models\Business  $business
     * @param  \App\Models\BusinessCategory  $category
     * @return \Illuminate\Http\Response
     */
    public function removeCategory(Business $business, BusinessCategory $category)
    {
        // Verificar que el usuario sea el dueño del negocio
        $this->authorize('update', $business);

        // Verificar que el negocio tenga la categoría asignada
        if (!$business->categories->contains($category)) {
            return response()->json([
                'message' => 'El negocio no tiene asignada esta categoría'
            ], 404);
        }

        // Eliminar la relación entre el negocio y la categoría
        $business->categories()->detach($category->id);

        return response()->json([
            'message' => 'Categoría eliminada del negocio correctamente',
            'business' => $business->load('categories') // Recargar las categorías
        ]);
    }

    /**
     * Actualizar las categorías de un negocio (reemplaza todas las categorías actuales).
     *
     * @param  \App\Models\Business  $business
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
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

        // Sincronizar categorías (elimina las no enviadas y agrega las nuevas)
        $business->categories()->sync($request->categories);

        return response()->json([
            'message' => 'Categorías actualizadas correctamente',
            'business' => $business->fresh()->load('categories')
        ]);
    }

  

    public function search(Request $request)
{
    $query = Business::query()->with(['categories', 'images']);

    // Filtrar por nombre
    if ($request->has('name')) {
        $query->where('name', 'like', '%' . $request->name . '%');
    }

    // Filtrar por categoría
    if ($request->has('category')) {
        $query->whereHas('categories', function($q) use ($request) {
            $q->where('business_category.category_id', $request->category);
        });
    }

    // No incluir el filtro por ubicación por ahora

    $businesses = $query->get();

    return response()->json($businesses);
}


    // Negocios cercanos (simplificado)
    public function nearby(Request $request)
    {
        $request->validate([
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
            'radius' => 'nullable|numeric|min:100|max:50000' // 100m a 50km
        ]);

        $lat = $request->lat;
        $lng = $request->lng;
        $radius = $request->get('radius', 10000); // Default: 10km

        $businesses = Business::selectRaw("*, (6371 * ACOS(COS(RADIANS(?)) * COS(RADIANS(latitude)) * COS(RADIANS(longitude) - RADIANS(?)) + SIN(RADIANS(?)) * SIN(RADIANS(latitude)))) AS distance", [$lat, $lng, $lat])
            ->having('distance', '<=', $radius)
            ->orderBy('distance')
            ->with(['categories', 'images'])
            ->get();

        return response()->json($businesses);
    }

    // Negocios por categoría
    public function byCategory($categoryId)
    {
        $businesses = Business::whereHas('categories', function($q) use ($categoryId) {
            $q->where('business_category.category_id', $categoryId);
        })->with(['categories', 'images'])->get();

        return response()->json($businesses);
    }


        


}
