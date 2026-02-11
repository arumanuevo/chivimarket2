<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Token de Acceso</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f8f9fa; }
        .container { max-width: 600px; margin-top: 50px; }
        .card { border: none; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); }
        .qr-code { margin: 20px auto; text-align: center; }
    </style>
</head>
<body>
    <div class="container">
        <div class="card p-4">
            <h2 class="text-center mb-4">Token de Acceso</h2>
            <p class="text-center">Dispositivo: <strong>{{ $deviceId }}</strong></p>

            <div class="alert alert-info">
                Token: <strong>{{ $token }}</strong>
            </div>

            <p class="text-center">Muestra este QR al dispositivo para activar el relé:</p>
            <div class="qr-code">
                {!! QrCode::size(200)->generate("ESP32-ACTIVATE:{$deviceId}|{$token}") !!}
            </div>

            <div class="alert alert-warning">
                Este token expirará en 5 minutos.
            </div>

            <div class="d-grid gap-2">
                <a href="{{ url('/validate-device?device_id=' . $deviceId) }}" class="btn btn-secondary">
                    Volver
                </a>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
