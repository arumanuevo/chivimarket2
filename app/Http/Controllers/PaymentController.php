<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use MercadoPago\MercadoPagoConfig;
use MercadoPago\Preference;
use MercadoPago\Client\Preference\PreferenceClient;
use MercadoPago\Item;
use Illuminate\Support\Str;
use App\Models\AccessToken;
use MercadoPago\Client\Payment\PaymentClient;

class PaymentController extends Controller
{
    public function __construct()
    {
        // Configurar el ACCESS_TOKEN de Mercado Pago con la nueva sintaxis
        MercadoPagoConfig::setAccessToken('APP_USR-6907958184263683-011320-e0f6ee5c1bffec59e87dfc16a3b29e9-3133104898');
    }

    public function createPayment(Request $request)
    {
        $deviceId = $request->input('device_id');
        $tempToken = $request->input('temp_token');

        // Crear un cliente de preferencias
        $client = new PreferenceClient();

        // Crear la preferencia de pago
        $preference = $client->create([
            "items" => [
                [
                    "title" => "Sesión de Ducha",
                    "quantity" => 1,
                    "unit_price" => 2.00
                ]
            ],
            "back_urls" => [
                "success" => route('payment.success', ['device_id' => $deviceId, 'temp_token' => $tempToken]),
                "failure" => route('payment.failure', ['device_id' => $deviceId, 'temp_token' => $tempToken]),
                "pending" => route('payment.pending', ['device_id' => $deviceId, 'temp_token' => $tempToken])
            ],
            "auto_return" => "approved",
            "external_reference" => $deviceId . '&' . $tempToken
        ]);

        // Redirigir al usuario a Mercado Pago
        return redirect()->away($preference['init_point']);
    }

    public function handleSuccess(Request $request)
    {
        $deviceId = $request->input('device_id');
        $tempToken = $request->input('temp_token');

        // Redirigir a la ruta que genera el token
        return redirect()->route('generate.token.view', ['device_id' => $deviceId, 'temp_token' => $tempToken]);
    }

    public function handleFailure(Request $request)
    {
        $deviceId = $request->input('device_id');
        $tempToken = $request->input('temp_token');

        return view('payment-failure', [
            'deviceId' => $deviceId,
            'tempToken' => $tempToken
        ]);
    }

    public function handlePending(Request $request)
    {
        $deviceId = $request->input('device_id');
        $tempToken = $request->input('temp_token');

        return view('payment-pending', [
            'deviceId' => $deviceId,
            'tempToken' => $tempToken
        ]);
    }

    

    public function handleWebhook(Request $request)
{
    \Log::info("Webhook recibido: ", $request->all());

    $paymentData = $request->all();

    if (isset($paymentData['action']) && $paymentData['action'] == 'payment.created') {
        $paymentId = $paymentData['data']['id'];

        $client = new PaymentClient();
        $payment = $client->get($paymentId);

        if ($payment['status'] == 'approved') {
            $externalReference = $payment['external_reference'];
            $externalData = [];
            parse_str($externalReference, $externalData);

            $deviceId = $externalData['device_id'];
            $tempToken = $externalData['temp_token'];

            $token = Str::random(16);
            AccessToken::create([
                'device_id' => $deviceId,
                'token' => $token,
                'expires_at' => now()->addMinutes(5),
                'used' => false
            ]);

            \Log::info("Token generado para device_id = " . $deviceId . ", token = " . $token);
        }
    }

    return response()->json(['status' => 'ok']);
}
}