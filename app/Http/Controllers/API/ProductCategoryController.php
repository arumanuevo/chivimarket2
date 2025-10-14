<?php
namespace App\Http\Controllers\API;
use App\Http\Controllers\Controller;
use App\Models\ProductCategory;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ProductCategoryController extends Controller
{
    /**
     * Listar todas las categorías de productos.
     */
    public function index()
    {
        $categories = ProductCategory::with('children')->whereNull('parent_id')->get();
        return response()->json($categories);
    }

    /**
     * Crear una nueva categoría de producto.
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
     * Mostrar una categoría específica.
     */
    public function show($id)
    {
        $category = ProductCategory::with(['children', 'parent'])->findOrFail($id);
        return response()->json($category);
    }

    /**
     * Actualizar una categoría.
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
     * Eliminar una categoría.
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
