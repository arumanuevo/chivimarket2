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

    // Listar negocios del usuario autenticado
    public function index()
    {
        $businesses = Auth::user()->businesses()->with(['categories', 'images'])->get();
        return response()->json($businesses);
    }

    // Mostrar un negocio específico
    public function show(Business $business)
    {
        if (Auth::check() && Auth::user()->id === $business->user_id) {
            return response()->json($business->load(['categories', 'images', 'products']));
        }
        return response()->json($business->load(['categories', 'images']));
    }

    // Crear un nuevo negocio
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
     * Actualizar las categorías de un negocio.
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
     * Buscar negocios por nombre, categoría o ubicación.
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
     * Negocios cercanos.
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
     * Negocios por categoría.
     */
    public function byCategory($categoryId)
    {
        $businesses = Business::whereHas('categories', function($q) use ($categoryId) {
            $q->where('business_category.category_id', $categoryId);
        })->with(['categories', 'images'])->get();

        return response()->json($businesses);
    }
}
