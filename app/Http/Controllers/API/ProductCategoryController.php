<?php
namespace App\Http\Controllers\API;
use App\Http\Controllers\Controller;
use App\Models\ProductCategory;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ProductCategoryController extends Controller
{
    /**
     * @OA\Get(
     *     path="/api/product-categories",
     *     summary="Listar categorías de productos",
     *     description="Devuelve todas las categorías de productos activas, con sus subcategorías.",
     *     tags={"Categorías de Productos"},
     *     @OA\Response(
     *         response=200,
     *         description="Listado de categorías",
     *         @OA\JsonContent(type="array", @OA\Items(type="object"))
     *     )
     * )
     */
   
    public function index()
    {
        $categories = ProductCategory::with('children')->whereNull('parent_id')->get();
        return response()->json($categories);
    }

    /**
     * @OA\Post(
     *     path="/api/product-categories",
     *     summary="Crear categoría de producto",
     *     description="Permite crear una nueva categoría de productos. Requiere autenticación.",
     *     tags={"Categorías de Productos"},
     *     security={{"bearerAuth":{}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"name"},
     *             @OA\Property(property="name", type="string", example="Electrónica"),
     *             @OA\Property(property="description", type="string", example="Dispositivos y accesorios tecnológicos"),
     *             @OA\Property(property="parent_id", type="integer", example=null),
     *             @OA\Property(property="is_active", type="boolean", example=true)
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Categoría creada correctamente"
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Error de validación"
     *     )
     * )
     */
   
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255|unique:product_categories',
            'description' => 'nullable|string',
            'parent_id' => 'nullable|exists:product_categories,id',
            'is_active' => 'boolean'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $category = ProductCategory::create($request->all());
        return response()->json($category, 201);
    }

    /**
     * @OA\Get(
     *     path="/api/product-categories/{id}",
     *     summary="Mostrar categoría de producto",
     *     description="Obtiene una categoría de producto con su jerarquía completa.",
     *     tags={"Categorías de Productos"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="ID de la categoría",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Categoría encontrada",
     *         @OA\JsonContent(type="object")
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Categoría no encontrada"
     *     )
     * )
     */
   
    public function show($id)
    {
        $category = ProductCategory::with(['children', 'parent'])->findOrFail($id);
        return response()->json($category);
    }

    /**
     * @OA\Put(
     *     path="/api/product-categories/{id}",
     *     summary="Actualizar categoría de producto",
     *     description="Modifica los datos de una categoría existente.",
     *     tags={"Categorías de Productos"},
     *     security={{"bearerAuth":{}}},
     *     @OA\RequestBody(
     *         @OA\JsonContent(
     *             @OA\Property(property="name", type="string", example="Electrodomésticos"),
     *             @OA\Property(property="description", type="string", example="Artículos para el hogar"),
     *             @OA\Property(property="is_active", type="boolean", example=true)
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Categoría actualizada correctamente"
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Error de validación"
     *     )
     * )
     */
   
    public function update(Request $request, $id)
    {
        $category = ProductCategory::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:255|unique:product_categories,name,' . $id,
            'description' => 'nullable|string',
            'parent_id' => 'nullable|exists:product_categories,id',
            'is_active' => 'boolean'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $category->update($request->all());
        return response()->json($category);
    }

    /**
     * @OA\Delete(
     *     path="/api/product-categories/{id}",
     *     summary="Eliminar categoría de producto",
     *     description="Elimina una categoría si no tiene productos asociados.",
     *     tags={"Categorías de Productos"},
     *     security={{"bearerAuth":{}}},
     *     @OA\Response(
     *         response=200,
     *         description="Categoría eliminada correctamente"
     *     ),
     *     @OA\Response(
     *         response=409,
     *         description="No se puede eliminar: tiene productos asociados"
     *     )
     * )
     */
    
    public function destroy($id)
    {
        $category = ProductCategory::findOrFail($id);

        // Verificar que no tenga productos asociados (opcional)
        if ($category->products()->exists()) {
            return response()->json([
                'message' => 'No se puede eliminar la categoría porque tiene productos asociados.'
            ], 409);
        }

        $category->delete();
        return response()->json(['message' => 'Categoría eliminada correctamente']);
    }
}
