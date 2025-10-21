<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class TestSwaggerController extends Controller
{
    /**
     * @OA\Get(
     *     path="/api/test",
     *     summary="Endpoint de prueba Swagger",
     *     description="Retorna un mensaje de prueba",
     *     tags={"Test"},
     *     @OA\Response(
     *         response=200,
     *         description="OK"
     *     )
     * )
     */
    public function index()
    {
        return response()->json(['message' => 'Swagger funciona correctamente ✅']);
    }
}

