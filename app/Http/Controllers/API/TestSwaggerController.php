<?php

namespace App\Http\Controllers\API;


use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class TestSwaggerController extends Controller
{

    public function index()
    {
        return response()->json(['message' => 'Swagger funciona correctamente ✅']);
    }
}

