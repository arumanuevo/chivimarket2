<?php
namespace App\Http\Controllers\API;
use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Business;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;

class ProductController extends Controller
{
    use AuthorizesRequests;

    /**
     * Listar productos de un negocio específico.
     * Ejemplo: GET /api/businesses/1/products
     */
    public function index(Business $business)
    {
        $this->authorize('view', $business); // Verificar que el usuario pueda ver el negocio

        $products = $business->products()
            ->with(['category', 'images'])
            ->get();

        return response()->json($products);
    }

    /**
     * Crear un nuevo producto para un negocio.
     * Ejemplo: POST /api/businesses/1/products
     */
   // app/Http/Controllers/API/ProductController.php
public function store(Request $request, Business $business)
{
    $user = Auth::user();

    // Verificar si el usuario es dueño del negocio
    if ($user->id !== $business->user_id) {
        $userBusinesses = $user->businesses()->pluck('id', 'name'); // Obtener negocios del usuario

        return response()->json([
            'message' => 'No tienes permiso para crear productos en este negocio.',
            'user_id' => $user->id,
            'business_user_id' => $business->user_id,
            'your_businesses' => $userBusinesses, // Lista de negocios del usuario
        ], 403);
    }

    // Validar límite de productos según suscripción
    $subscription = $user->subscription;

    // Crear suscripción "free" si no existe
    if (!$subscription) {
        $subscription = $user->subscription()->create([
            'type' => 'free',
            'product_limit' => 11,
            'is_active' => true
        ]);
    }

    if ($subscription->type === 'free' && $business->products()->count() >= $subscription->product_limit) {
        return response()->json([
            'message' => 'Has alcanzado el límite de productos para tu plan. Actualiza a premium para publicar más.'
        ], 403);
    }

    $validator = Validator::make($request->all(), [
        'name' => 'required|string|max:255',
        'description' => 'nullable|string',
        'price' => 'required|numeric|min:0',
        'stock' => 'required|integer|min:0',
        'category_id' => 'required|exists:product_categories,id',
        'is_active' => 'boolean'
    ]);

    if ($validator->fails()) {
        return response()->json($validator->errors(), 422);
    }

    // Crear el producto asociado al negocio
    $product = $business->products()->create($request->all());
    return response()->json($product, 201);
}


   /**
 * Buscar productos por nombre, categoría, negocio, etc.
 * Ejemplo: GET /api/products/search?query=pan
 */
public function search(Request $request)
{
    $query = Product::with(['business', 'category', 'images']);

    // Filtrar por nombre
    if ($request->has('name')) {
        $query->where('name', 'like', '%' . $request->name . '%');
    }

    // Filtrar por descripción
    if ($request->has('description')) {
        $query->orWhere('description', 'like', '%' . $request->description . '%');
    }

    // Filtrar por categoría
    if ($request->has('category')) {
        $query->where('category_id', $request->category);
    }

    // Filtrar por negocio
    if ($request->has('business')) {
        $query->where('business_id', $request->business);
    }

    // Filtrar por rango de precios
    if ($request->has('min_price')) {
        $query->where('price', '>=', $request->min_price);
    }
    if ($request->has('max_price')) {
        $query->where('price', '<=', $request->max_price);
    }

    // Búsqueda por término general (ej: "pan")
    if ($request->has('query')) {
        $searchTerm = $request->get('query');  // 👈 Cambio: usar $request->get('query')
        $query->where(function($q) use ($searchTerm) {
            $q->where('name', 'like', '%' . $searchTerm . '%')
              ->orWhere('description', 'like', '%' . $searchTerm . '%')
              ->orWhereHas('category', function($q) use ($searchTerm) {
                  $q->where('name', 'like', '%' . $searchTerm . '%');
              });
        });
    }

    // Ordenar por precio o nombre
    if ($request->has('sort_by')) {
        $sortBy = $request->sort_by;
        $order = $request->get('order', 'asc');
        if (in_array($sortBy, ['price', 'name', 'created_at'])) {
            $query->orderBy($sortBy, $order);
        }
    }

    return response()->json($query->get());
}


    /**
     * Productos por categoría.
     * Ejemplo: GET /api/products/category/5
     */
    public function byCategory($categoryId)
    {
        $products = Product::where('id', $categoryId)
            ->with(['business', 'category', 'images'])
            ->get();

        return response()->json($products);
    }

    /**
     * Productos de un negocio específico.
     * Ejemplo: GET /api/products/business/1
     */
    public function byBusiness($businessId)
    {
        $products = Product::where('business_id', $businessId)
            ->with(['category', 'images'])
            ->get();

        return response()->json($products);
    }

    /**
     * Mostrar un producto específico.
     * Ejemplo: GET /api/products/1
     */
    public function show(Product $product)
    {
        //$this->authorize('view', $product->business); // Verificar que el usuario pueda ver el negocio asociado

        return response()->json($product->load(['business', 'category', 'images']));
    }

    /**
     * Actualizar un producto.
     * Ejemplo: PUT /api/products/1
     */
    public function update(Request $request, Product $product)
    {
        $this->authorize('update', $product->business); // Verificar que el usuario sea dueño del negocio

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'price' => 'sometimes|required|numeric|min:0',
            'stock' => 'sometimes|required|integer|min:0',
            'category_id' => 'sometimes|required|exists:product_categories,id',
            'is_active' => 'boolean'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $product->update($request->all());

        return response()->json($product->fresh()->load(['business', 'category', 'images']));
    }

    /**
     * Eliminar un producto.
     * Ejemplo: DELETE /api/products/1
     */
    public function destroy(Product $product)
    {
        $this->authorize('update', $product->business); // Verificar que el usuario sea dueño del negocio

        $product->delete();

        return response()->json(['message' => 'Producto eliminado correctamente']);
    }
}
