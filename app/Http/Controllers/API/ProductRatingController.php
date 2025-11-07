<?php

namespace App\Http\Controllers\API;
use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\ProductRating;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class ProductRatingController extends Controller
{
    public function store(Request $request, Product $product)
    {
        $user = Auth::user();

        $validator = Validator::make($request->all(), [
            'quality' => 'required|integer|between:1,5',
            'comment' => 'nullable|string|max:500'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        // Verificar si el usuario ya calificó este producto
        $existingRating = ProductRating::where('product_id', $product->id)
            ->where('user_id', $user->id)
            ->first();

        if ($existingRating) {
            return response()->json([
                'message' => 'Ya has calificado este producto.'
            ], 403);
        }

        $rating = ProductRating::create([
            'product_id' => $product->id,
            'user_id' => $user->id,
            'quality' => $request->quality,
            'comment' => $request->comment
        ]);

        return response()->json([
            'message' => 'Calificación registrada correctamente',
            'rating' => $rating
        ], 201);
    }

    public function index(Product $product)
    {
        $ratings = ProductRating::where('product_id', $product->id)
            ->with(['user'])
            ->orderBy('created_at', 'desc')
            ->get();

        $averageRating = $ratings->avg('quality');

        return response()->json([
            'ratings' => $ratings,
            'average_rating' => round($averageRating, 1),
            'total_ratings' => $ratings->count()
        ]);
    }
}
