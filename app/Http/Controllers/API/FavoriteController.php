<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Business;
use App\Models\Product;
use Illuminate\Support\Facades\Auth;

class FavoriteController extends Controller
{
    public function toggleBusiness(Business $business)
    {
        $user = Auth::user();

        if ($user->favoriteBusinesses()->where('business_id', $business->id)->exists()) {
            $user->favoriteBusinesses()->detach($business->id);
            return response()->json(['status' => 'removed', 'message' => 'Negocio removido de favoritos']);
        } else {
            $user->favoriteBusinesses()->attach($business->id);
            return response()->json(['status' => 'added', 'message' => 'Negocio añadido a favoritos']);
        }
    }

    public function toggleProduct(Product $product)
    {
        $user = Auth::user();

        if ($user->favoriteProducts()->where('product_id', $product->id)->exists()) {
            $user->favoriteProducts()->detach($product->id);
            return response()->json(['status' => 'removed', 'message' => 'Producto removido de favoritos']);
        } else {
            $user->favoriteProducts()->attach($product->id);
            return response()->json(['status' => 'added', 'message' => 'Producto añadido a favoritos']);
        }
    }

    public function myFavorites()
    {
        $user = Auth::user();
        $businesses = $user->favoriteBusinesses()->with(['categories', 'images'])->get();
        // Cargar también al negocio titular del producto favorito para poder ir a su perfil
        $products = $user->favoriteProducts()->with([
            'business' => function ($q) {
                $q->select('id', 'name', 'latitude', 'longitude');
            },
            'images'
        ])->get();

        return response()->json([
            'businesses' => $businesses,
            'products' => $products
        ]);
    }
}
