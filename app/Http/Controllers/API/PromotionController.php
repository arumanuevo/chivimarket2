<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Promotion;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class PromotionController extends Controller
{
    // Obtener promociones activas de un negocio (API Pública)
    public function index(Business $business)
    {
        $promotions = $business->promotions()
            ->with('product') // Incluir el producto si existe
            ->where('is_active', true)
            ->where(function ($query) {
                $query->whereNull('expires_at')
                    ->orWhere('expires_at', '>', now());
            })
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($promotions);
    }

    // Obtener TODAS las promociones activas (Catálogo público / Feed principal)
    public function getAllActivePromotions()
    {
        $promotions = Promotion::with(['business', 'product'])
            ->where('is_active', true)
            ->where(function ($query) {
                $query->whereNull('expires_at')
                    ->orWhere('expires_at', '>', now());
            })
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($promotions);
    }

    // Obtener promociones activas de un PRODUCTO (API Pública)
    public function productPromotions(\App\Models\Product $product)
    {
        $promotions = $product->promotions()
            ->where('is_active', true)
            ->where(function ($query) {
                $query->whereNull('expires_at')
                    ->orWhere('expires_at', '>', now());
            })
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($promotions);
    }

    // Crear promoción (Protegido - Solo dueño del negocio)
    public function store(Request $request, Business $business)
    {
        if ($business->user_id !== Auth::id()) {
            return response()->json(['message' => 'No autorizado para gestionar ofertas de este negocio.'], 403);
        }

        $validator = Validator::make($request->all(), [
            'product_id' => 'nullable|integer|exists:products,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'required_level' => 'integer|min:1',
            'max_uses_per_user' => 'integer|min:1',
            'is_active' => 'boolean',
            'expires_at' => 'nullable|date|after:today',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $promotion = $business->promotions()->create($request->all());

        return response()->json([
            'message' => 'Promoción creada con éxito.',
            'promotion' => $promotion
        ], 201);
    }

    // Actualizar promoción o desactivarla
    public function update(Request $request, Promotion $promotion)
    {
        $business = $promotion->business;

        if ($business->user_id !== Auth::id()) {
            return response()->json(['message' => 'No autorizado.'], 403);
        }

        $promotion->update($request->all());

        return response()->json([
            'message' => 'Promoción actualizada con éxito.',
            'promotion' => $promotion
        ]);
    }

    public function destroy(Promotion $promotion)
    {
        $business = $promotion->business;

        if ($business->user_id !== Auth::id()) {
            return response()->json(['message' => 'No autorizado.'], 403);
        }

        $promotion->delete();

        return response()->json(['message' => 'Promoción eliminada.']);
    }
}
