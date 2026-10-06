<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Promotion;
use App\Models\Voucher;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;

class VoucherController extends Controller
{
    // El usuario reclama un voucher para una promoción determinada
    public function claim(Promotion $promotion)
    {
        $user = Auth::user();

        // 1. Check if promotion is active
        if (!$promotion->is_active || ($promotion->expires_at && $promotion->expires_at < now())) {
            return response()->json(['message' => 'Esta promoción se encuentra inactiva o ha expirado.'], 400);
        }

        // 2. Check RPG Level requirements
        if ($user->level < $promotion->required_level) {
            return response()->json([
                'message' => 'Nivel insuficiente para reclamar.',
                'required_level' => $promotion->required_level,
                'user_level' => $user->level
            ], 403);
        }

        // 3. Check individual usage limit
        $claimCount = Voucher::where('promotion_id', $promotion->id)
            ->where('user_id', $user->id)
            ->count();

        if ($claimCount >= $promotion->max_uses_per_user) {
            return response()->json(['message' => 'Has alcanzado el límite personal de reclamos.'], 403);
        }

        // 4. Check global stock limit
        if ($promotion->max_total_claims !== null) {
            $totalClaims = Voucher::where('promotion_id', $promotion->id)->count();
            if ($totalClaims >= $promotion->max_total_claims) {
                return response()->json(['message' => '¡Lo sentimos! El stock global de esta oferta se ha agotado.'], 403);
            }
        }

        // Generate unique code (E.g. CHIVI-4A8F9)
        $code = 'CHIVI-' . strtoupper(Str::random(6));

        $voucher = Voucher::create([
            'promotion_id' => $promotion->id,
            'user_id' => $user->id,
            'code' => $code,
            'status' => 'claimed'
        ]);

        return response()->json([
            'message' => '¡Voucher reclamado con éxito!',
            'voucher' => $voucher->load('promotion.business')
        ], 201);
    }

    // Listar todos los vouchers del usuario activo (la billetera)
    public function myVouchers()
    {
        $user = Auth::user();

        $vouchers = Voucher::with(['promotion.business'])
            ->where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($vouchers);
    }

    // El DUEÑO DEL LOCAL lee y valida el código del comprador
    public function redeem(Request $request)
    {
        $seller = Auth::user();
        $code = $request->input('code');

        if (!$code) {
            return response()->json(['message' => 'El campo código es obligatorio.'], 400);
        }

        $voucher = Voucher::where('code', $code)->with(['promotion.business', 'user'])->first();

        if (!$voucher) {
            return response()->json(['message' => 'El código no existe en nuestra base de datos.'], 404);
        }

        // Check if the authenticated seller practically owns the business of this promo
        if ($voucher->promotion->business->user_id !== $seller->id) {
            return response()->json(['message' => 'Este voucher pertenece a otro negocio.'], 403);
        }

        if ($voucher->status === 'redeemed') {
            return response()->json(['message' => 'Este voucher ya ha sido canjeado anteriormente.'], 400);
        }

        if ($voucher->status === 'expired') {
            return response()->json(['message' => 'El voucher ha expirado.'], 400);
        }

        // ----------------------------------------------------
        // LOGIC: REDEEM VOUCHER & APPLY RPG REWARDS
        // ----------------------------------------------------

        $voucher->update([
            'status' => 'redeemed',
            'redeemed_at' => now()
        ]);

        $buyer = $voucher->user;

        // Sumar Experiencia al "Buyer"
        $xpToGive = 50;
        $buyer->xp_points += $xpToGive;

        // Curva Base de Niveles RPG: (200 XP por Nivel)
        $newLevel = floor($buyer->xp_points / 200) + 1;
        $leveledUp = false;

        if ($newLevel > $buyer->level) {
            $buyer->level = $newLevel;
            $leveledUp = true;
        }

        $buyer->save();

        return response()->json([
            'message' => '¡Voucher validado con éxito!',
            'transaction_details' => [
                'buyer_name' => $buyer->name,
                'promotion' => $voucher->promotion->title,
                'xp_awarded_to_buyer' => $xpToGive,
                'leveled_up' => $leveledUp,
                'new_level' => $buyer->level
            ]
        ]);
    }
}
