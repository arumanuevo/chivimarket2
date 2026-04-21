<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use MercadoPago\MercadoPagoConfig;
use MercadoPago\Preference;
use MercadoPago\Client\Preference\PreferenceClient;
use MercadoPago\Exceptions\MPApiException;
use MercadoPago\Item;
use Illuminate\Support\Str;
use App\Models\AccessToken;
use MercadoPago\Client\Payment\PaymentClient;
use Illuminate\Support\Facades\Log;


class PaymentController extends Controller
{
    public function __construct()
    {
        // Configurar el ACCESS_TOKEN de Mercado Pago con la nueva sintaxis
        MercadoPagoConfig::setAccessToken('APP_USR-6907958184263683-011320-e0f6eee5c1bffec59e87dfc16a3b29e9-3133104898');
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

    

/*public function handleWebhook(Request $request)
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
}*/

public function createPreference(Request $request)
{
    try {
        $deviceId = $request->input('device_id');
        $tempToken = $request->input('temp_token');

        Log::info("Creando preferencia para device_id: $deviceId, temp_token: $tempToken");

        MercadoPagoConfig::setAccessToken('APP_USR-6907958184263683-011320-e0f6ee5c1bffec59e87dfc16a3b29e9-3133104898');

        $client = new PreferenceClient();

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

        Log::info("Preferencia creada con éxito. ID: " . $preference['id']);

        return response()->json(['preferenceId' => $preference['id']]);

    } catch (\Exception $e) {
        Log::error("Error al crear la preferencia: " . $e->getMessage());
        return response()->json(['error' => $e->getMessage()], 500);
    }
}
/* testing mercado <pago>*/


public function showTestPayment()
{
    return view('test-payment');
}

public function createTestPreference(Request $request)
{
    try {
        MercadoPagoConfig::setAccessToken('APP_USR-6907958184263683-011320-e0f6eee5c1bffec59e87dfc16a3b29e9-3133104898');
        MercadoPagoConfig::enableDebugMode();

        $client = new PreferenceClient();

        $body = [
            "items" => [
                [
                    "title" => "Prueba de Pago",
                    "quantity" => 1,
                    "unit_price" => (float)10.00,
                    "currency_id" => "ARS"
                ]
            ],
            "back_urls" => [
                "success" => url("/test-payment-success"),
                "failure" => url("/test-payment-failure"),
                "pending" => url("/test-payment-pending")
            ],
            "auto_return" => "approved"
        ];

        \Log::info("Cuerpo de la preferencia:", $body);

        $preference = $client->create($body);

        \Log::info("Preferencia creada:", $preference);

        return response()->json(['preferenceId' => $preference['id']]);

    } catch (\Exception $e) {
        \Log::error("Error detallado al crear la preferencia de prueba: " . $e->getMessage() . "\n" . $e->getTraceAsString());
        return response()->json(['error' => $e->getMessage()], 500);
    }
}
public function handleTestPaymentSuccess(Request $request)
{
    return view('test-payment-success');
}

public function handleTestPaymentFailure(Request $request)
{
    return view('test-payment-failure');
}

public function handleTestPaymentPending(Request $request)
{
    return view('test-payment-pending');
}

public function testConnection(Request $request)
{
    try {
        MercadoPagoConfig::setAccessToken('APP_USR-6907958184263683-011320-e0f6eee5c1bffec59e87dfc16a3b29e9-3133104898');
        //MercadoPagoConfig::enableDebugMode();

        $client = new PreferenceClient();

        $body = [
            "items" => [
                [
                    "title" => "Test Product",
                    "quantity" => 1,
                    "unit_price" => (float)10.00,
                    "currency_id" => "ARS"
                ]
            ]
        ];

        $preference = $client->create($body);

        return response()->json(['preferenceId' => $preference['id']]);

    } catch (\Exception $e) {
        \Log::error("Error detallado al probar la conexión: " . $e->getMessage() . "\n" . $e->getTraceAsString());
        return response()->json(['error' => $e->getMessage()], 500);
    }
}

public function testSDK()
{
    try {
        MercadoPagoConfig::setAccessToken('APP_USR-6907958184263683-011320-e0f6eee5c1bffec59e87dfc16a3b29e9-3133104898');
        return response()->json(['message' => 'SDK configurado correctamente']);
    } catch (\Exception $e) {
        return response()->json(['error' => $e->getMessage()], 500);
    }
}

public function showSimplePayment()
{
    return view('simple-payment');
}

public function createSimplePreference(Request $request)
{
    try {
        MercadoPagoConfig::setAccessToken('APP_USR-6907958184263683-011320-e0f6eee5c1bffec59e87dfc16a3b29e9-3133104898');

        $client = new PreferenceClient();

        $preference = $client->create([
            "items" => [
                [
                    "title" => "Pago Simple",
                    "quantity" => 1,
                    "unit_price" => (float)10.00,
                    "currency_id" => "ARS"
                ]
            ],
            "back_urls" => [
                "success" => "https://chivimarket.arumasoft.com/simple-payment-success",
                "failure" => "https://chivimarket.arumasoft.com/simple-payment-failure",
                "pending" => "https://chivimarket.arumasoft.com/simple-payment-pending"
            ],
            "auto_return" => "approved"
        ]);

        return response()->json(['preferenceId' => $preference->id]);

    } catch (\Exception $e) {
        \Log::error("Error detallado al crear la preferencia simple: " . $e->getMessage());
        return response()->json(['error' => $e->getMessage()], 500);
    }
}
//APP_USR-6907958184263683-011320-e0f6eee5c1bffec59e87dfc16a3b29e9-3133104898
public function handleWebhook(Request $request)
{
   
   /* try {
        $data = $request->all();

        if (isset($data['action']) && $data['action'] == 'payment.updated') {
            $paymentId = $data['data']['id'];

            MercadoPagoConfig::setAccessToken('APP_USR-6907958184263683-011320-e0f6eee5c1bffec59e87dfc16a3b29e9-3133104898');
            $client = new PaymentClient();
            $payment = $client->get($paymentId);

            Log::info("Detalles del pago:", ['payment' => $payment]);

            if ($payment['status'] == 'approved') {
                Log::info("Pago aprobado con ID: " . $paymentId);
                return response()->json(['status' => 'success']);
            }
        }

        return response()->json(['status' => 'received']);

    } catch (\Exception $e) {
        Log::error("Error en el webhook: " . $e->getMessage(), ['exception' => $e]);
        return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
    }*/
    Log::info("Webhook recibido:", $request->all());

    try {
        $data = $request->all();

        // Verificar que sea una notificación de pago actualizado
        if (!isset($data['action']) || $data['action'] != 'payment.updated') {
            Log::info("Notificación no es de pago actualizado. Acción: " . ($data['action'] ?? 'No especificada'));
            return response()->json(['status' => 'ignored']);
        }

        // Obtener el ID del pago
        if (!isset($data['data']['id'])) {
            Log::error("ID de pago no encontrado en la notificación.");
            return response()->json(['status' => 'error', 'message' => 'ID de pago no encontrado'], 400);
        }

        $paymentId = $data['data']['id'];
        Log::info("llego hasta aca");
        // Configurar el SDK de Mercado Pago
        MercadoPagoConfig::setAccessToken('APP_USR-6907958184263683-011320-e0f6eee5c1bffec59e87dfc16a3b29e9-3133104898');

        // Obtener detalles del pago
        $client = new PaymentClient();
        $payment = $client->get($paymentId);

        // Verificar el estado del pago
        if ($payment->status === 'approved') {
            Log::info("Pago aprobado con ID: " . $paymentId, ['payment' => $payment]);
            // Aquí puedes agregar la lógica para manejar el pago aprobado
            return response()->json(['status' => 'success']);
        } else {
            Log::info("Pago no aprobado. Estado: " . $payment->status, ['payment' => $payment]);
            return response()->json(['status' => 'received']);
        }

    } catch (MPApiException $e) {
        Log::error("Error en la API de Mercado Pago: " . $e->getMessage(), ['exception' => $e]);
        return response()->json(['status' => 'error', 'message' => 'Error en la API de Mercado Pago'], 500);
    } catch (\Exception $e) {
        Log::error("Error en el webhook: " . $e->getMessage(), ['exception' => $e]);
        return response()->json(['status' => 'error', 'message' => 'Error interno del servidor'], 500);
    }
}
public function handleSimplePaymentSuccess(Request $request)
{
    return view('simple-payment-success');
}

public function handleSimplePaymentFailure(Request $request)
{
    return view('simple-payment-failure');
}

public function handleSimplePaymentPending(Request $request)
{
    return view('simple-payment-pending');
}

}