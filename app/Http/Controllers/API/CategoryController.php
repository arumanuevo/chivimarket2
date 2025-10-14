<?php
namespace App\Http\Controllers\API;
use App\Http\Controllers\Controller;
use App\Models\BusinessCategory; // Modelo para categorías de negocios
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CategoryController extends Controller
{
    // Listar categorías (público)
    public function index()
    {
        return response()->json(BusinessCategory::all());
    }

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

