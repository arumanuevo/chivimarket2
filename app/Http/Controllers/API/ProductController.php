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

    public function explore()
    {
        $products = \App\Models\Product::with([
            'business',
            'images'
        ])
            ->where('is_active', true)
            ->inRandomOrder()
            ->take(50)
            ->get()
            ->map(function ($product) {
                // Random mock sponsor flag for UI testing
                $product->is_sponsored = (rand(1, 100) <= 20);
                return $product;
            });

        // Order the collection so sponsored products appear first, then randomly
        $products = $products->sortByDesc('is_sponsored')->values();

        return response()->json($products);
    }

    /**
     * @OA\Get(
     *     path="/api/businesses/{business}/products",
     *     summary="Listar productos de un negocio",
     *     description="Devuelve todos los productos asociados a un negocio específico.",
     *     tags={"Productos"},
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
     *         description="Lista de productos del negocio",
     *         @OA\JsonContent(type="array", @OA\Items(ref="#/components/schemas/Product"))
     *     ),
     *     @OA\Response(response=403, description="No autorizado para ver este negocio")
     * )
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
     * @OA\Post(
     *     path="/api/businesses/{business}/products",
     *     summary="Crear un nuevo producto",
     *     description="Crea un nuevo producto asociado a un negocio. Solo el dueño del negocio puede crear productos.",
     *     tags={"Productos"},
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
     *             @OA\Property(property="name", type="string", example="Pan integral artesanal"),
     *             @OA\Property(property="description", type="string", example="Pan casero con semillas de lino"),
     *             @OA\Property(property="price", type="number", format="float", example=320.50),
     *             @OA\Property(property="stock", type="integer", example=40),
     *             @OA\Property(property="category_id", type="integer", example=5),
     *             @OA\Property(property="is_active", type="boolean, example=true")
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Producto creado correctamente",
     *         @OA\JsonContent(ref="#/components/schemas/Product")
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado para crear productos en este negocio o límite de productos alcanzado"
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Error de validación de los datos enviados"
     *     )
     * )
     */
    public function store(Request $request, Business $business)
    {
        $user = Auth::user();

        // Verificar si el usuario es dueño del negocio
        if ((int) $user->id !== (int) $business->user_id) {
            $userBusinesses = $user->businesses()->pluck('name', 'id'); // Cambié el orden para mejor legibilidad

            return response()->json([
                'message' => 'No tienes permiso para crear productos en este negocio.',
                'user_id' => $user->id,
                'business_user_id' => $business->user_id,
                'your_businesses' => $userBusinesses,
            ], 403);
        }

        //$this->authorize('update', $business);
        // Validar límite de productos dinámicamente usando nuestro SubscriptionService
        $subscription = $user->subscription ?? \App\Services\SubscriptionService::createDefaultSubscription($user);
        $maxProducts = \App\Services\SubscriptionService::getMaxProductsForSubscription($subscription->type);

        // Acá revisamos la cantidad de todos los productos en ESTE negocio limitados. 
        // NOTA: Para un marketplace real se suman todos los productos del USUARIO, pero por negocio está bien.
        if ($business->products()->count() >= $maxProducts) {
            return response()->json([
                'message' => 'Has alcanzado el límite global de ' . $maxProducts . ' productos para el plan (' . strtoupper($subscription->type) . '). Actualiza desde el Súper Admin para añadir más stock.'
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
     * @OA\Get(
     *     path="/api/products/search",
     *     summary="Buscar productos",
     *     description="Busca productos por nombre, descripción, categoría, negocio o rango de precios.",
     *     tags={"Productos"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(name="query", in="query", required=false, description="Término general de búsqueda", @OA\Schema(type="string")),
     *     @OA\Parameter(name="name", in="query", required=false, description="Nombre del producto", @OA\Schema(type="string")),
     *     @OA\Parameter(name="description", in="query", required=false, description="Descripción del producto", @OA\Schema(type="string")),
     *     @OA\Parameter(name="category", in="query", required=false, description="ID de la categoría", @OA\Schema(type="integer")),
     *     @OA\Parameter(name="business", in="query", required=false, description="ID del negocio", @OA\Schema(type="integer")),
     *     @OA\Parameter(name="min_price", in="query", required=false, description="Precio mínimo", @OA\Schema(type="number", format="float")),
     *     @OA\Parameter(name="max_price", in="query", required=false, description="Precio máximo", @OA\Schema(type="number", format="float")),
     *     @OA\Parameter(name="sort_by", in="query", required=false, description="Campo para ordenar (price, name, created_at)", @OA\Schema(type="string")),
     *     @OA\Parameter(name="order", in="query", required=false, description="Orden (asc o desc)", @OA\Schema(type="string")),
     *     @OA\Response(
     *         response=200,
     *         description="Lista de productos encontrada",
     *         @OA\JsonContent(type="array", @OA\Items(ref="#/components/schemas/Product"))
     *     )
     * )
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
            $query->where(function ($q) use ($searchTerm) {
                $q->where('name', 'like', '%' . $searchTerm . '%')
                    ->orWhere('description', 'like', '%' . $searchTerm . '%')
                    ->orWhereHas('category', function ($q) use ($searchTerm) {
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
     * @OA\Get(
     *     path="/api/products/category/{category}",
     *     summary="Listar productos por categoría",
     *     description="Devuelve todos los productos pertenecientes a una categoría específica.",
     *     tags={"Productos"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="category",
     *         in="path",
     *         required=true,
     *         description="ID de la categoría",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Lista de productos en la categoría",
     *         @OA\JsonContent(type="array", @OA\Items(ref="#/components/schemas/Product"))
     *     ),
     *     @OA\Response(response=404, description="Categoría no encontrada")
     * )
     */

    public function byCategory($categoryId)
    {
        $products = Product::where('id', $categoryId)
            ->with(['business', 'category', 'images'])
            ->get();

        return response()->json($products);
    }

    /**
     * @OA\Get(
     *     path="/api/products/business/{business}",
     *     summary="Listar productos por negocio",
     *     description="Obtiene los productos asociados a un negocio específico.",
     *     tags={"Productos"},
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
     *         description="Lista de productos del negocio",
     *         @OA\JsonContent(type="array", @OA\Items(ref="#/components/schemas/Product"))
     *     ),
     *     @OA\Response(response=404, description="Negocio no encontrado")
     * )
     */

    public function byBusiness($businessId)
    {
        $products = Product::where('business_id', $businessId)
            ->with(['category', 'images'])
            ->get();

        return response()->json($products);
    }

    /**
     * @OA\Get(
     *     path="/api/products/{product}",
     *     summary="Mostrar un producto específico",
     *     description="Devuelve la información detallada de un producto por su ID.",
     *     tags={"Productos"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="product",
     *         in="path",
     *         required=true,
     *         description="ID del producto",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Detalle del producto",
     *         @OA\JsonContent(ref="#/components/schemas/Product")
     *     ),
     *     @OA\Response(response=404, description="Producto no encontrado")
     * )
     */

    public function show(Product $product)
    {
        //$this->authorize('view', $product->business); // Verificar que el usuario pueda ver el negocio asociado

        return response()->json($product->load(['business', 'category', 'images']));
    }

    /**
     * @OA\Put(
     *     path="/api/products/{product}",
     *     summary="Actualizar un producto existente",
     *     description="Permite modificar los datos de un producto. Solo el propietario del negocio puede actualizarlo.",
     *     tags={"Productos"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="product",
     *         in="path",
     *         required=true,
     *         description="ID del producto a actualizar",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="name", type="string", example="Pan integral artesanal"),
     *             @OA\Property(property="description", type="string", example="Pan casero con semillas de lino"),
     *             @OA\Property(property="price", type="number", format="float", example=320.50),
     *             @OA\Property(property="stock", type="integer", example=40),
     *             @OA\Property(property="category_id", type="integer", example=5),
     *             @OA\Property(property="is_active", type="boolean", example=true)
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Producto actualizado correctamente",
     *         @OA\JsonContent(ref="#/components/schemas/Product")
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado para actualizar este producto"
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Error de validación de los datos enviados"
     *     )
     * )
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
     * @OA\Delete(
     *     path="/api/products/{product}",
     *     summary="Eliminar un producto",
     *     description="Elimina un producto existente. Solo el propietario del negocio puede realizar esta acción.",
     *     tags={"Productos"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="product",
     *         in="path",
     *         required=true,
     *         description="ID del producto a eliminar",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Producto eliminado correctamente",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="message", type="string", example="Producto eliminado correctamente")
     *         )
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado para eliminar este producto"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Producto no encontrado"
     *     )
     * )
     */

    public function destroy(Product $product)
    {
        $this->authorize('update', $product->business); // Verificar que el usuario sea dueño del negocio

        $product->delete();

        return response()->json(['message' => 'Producto eliminado correctamente']);
    }
}
