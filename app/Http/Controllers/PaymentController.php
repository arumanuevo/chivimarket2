<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use MercadoPago\MercadoPagoConfig;
use MercadoPago\Preference;
use MercadoPago\Item;
use Illuminate\Support\Str;
use App\Models\AccessToken;

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

        // Crear una preferencia de pago
        $preference = new Preference();

        // Configurar el ítem a pagar
        $item = new Item();
        $item->title = 'Sesión de Ducha';
        $item->quantity = 1;
        $item->unit_price = 2.00;

        $preference->items = [$item];

        // Configurar las URLs de retorno
        $preference->back_urls = [
            'success' => route('payment.success', ['device_id' => $deviceId, 'temp_token' => $tempToken]),
            'failure' => route('payment.failure', ['device_id' => $deviceId, 'temp_token' => $tempToken]),
            'pending' => route('payment.pending', ['device_id' => $deviceId, 'temp_token' => $tempToken])
        ];

        $preference->auto_return = 'approved';

        // Guardar la preferencia
        $preference->save();

        // Redirigir al usuario a Mercado Pago
        return redirect()->away($preference->init_point);
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

    $payment = $request->all();

    if (isset($payment['action']) && $payment['action'] == 'payment.created') {
        $paymentId = $payment['data']['id'];

        SDK::setAccessToken('APP_USR-6907958184263683-011320-e0f6ee5c1bffec59e87dfc16a3b29e9-3133104898');

        $paymentInfo = MercadoPago\Payment::find_by_id($paymentId);

        if ($paymentInfo->status == 'approved') {
            $externalReference = explode('&', $paymentInfo->external_reference);
            parse_str($paymentInfo->external_reference, $externalData);

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