<?php

// app/Http/Controllers/PaymentController.php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use MercadoPago\SDK;
use MercadoPago\Preference;
use MercadoPago\Item;

class PaymentController extends Controller
{
    public function __construct()
    {
        SDK::setAccessToken('APP_USR-6907958184263683-011320-e0f6ee5c1bffec59e87dfc16a3b29e9-3133104898');
    }

    public function createPayment(Request $request)
{
    $deviceId = $request->input('device_id');
    $tempToken = $request->input('temp_token');

    $preference = new Preference();

    $item = new Item();
    $item->title = 'Sesión de Ducha';
    $item->quantity = 1;
    $item->unit_price = 2.00;

    $preference->items = [$item];

    // Configurar las URLs de retorno con tu dominio de producción
    $preference->back_urls = [
        'success' => 'https://chivimarket.arumasoft.com/payment/success?device_id=' . $deviceId . '&temp_token=' . $tempToken,
        'failure' => 'https://chivimarket.arumasoft.com/payment/failure?device_id=' . $deviceId . '&temp_token=' . $tempToken,
        'pending' => 'https://chivimarket.arumasoft.com/payment/pending?device_id=' . $deviceId . '&temp_token=' . $tempToken
    ];

    $preference->auto_return = 'approved';
    $preference->save();

    return redirect()->away($preference->init_point);
}

    public function handleSuccess(Request $request)
    {
        $deviceId = $request->input('device_id');
        $tempToken = $request->input('temp_token');

        // Aquí podrías validar el pago antes de generar el token
        // Por ahora, generamos el token directamente
        return redirect()->route('generate.token', ['device_id' => $deviceId, 'temp_token' => $tempToken]);
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