<?php
namespace App\Http\Controllers\API;
use App\Http\Controllers\Controller;
use App\Models\BusinessCategory; // Modelo para categorías de negocios
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CategoryController extends Controller
{
    /**
     * @OA\Get(
     *     path="/api/business-categories",
     *     summary="Listar categorías de negocios",
     *     description="Devuelve todas las categorías disponibles para los negocios.",
     *     tags={"Categorías de Negocios"},
     *     @OA\Response(
     *         response=200,
     *         description="Listado de categorías",
     *         @OA\JsonContent(type="array", @OA\Items(type="object"))
     *     )
     * )
     */

    // Listar categorías (público)
    public function index()
    {
        return response()->json(BusinessCategory::all());
    }

    /**
     * @OA\Get(
     *     path="/api/business-categories/{id}",
     *     summary="Mostrar categoría de negocio",
     *     description="Devuelve los datos de una categoría específica.",
     *     tags={"Categorías de Negocios"},
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
    // Mostrar una categoría (público)
    public function show(BusinessCategory $businessCategory)
    {
        return response()->json($businessCategory);
    }

    // Crear categoría (protegido)
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255|unique:business_categories',
            'description' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $category = BusinessCategory::create($request->all());
        return response()->json($category, 201);
    }
}

