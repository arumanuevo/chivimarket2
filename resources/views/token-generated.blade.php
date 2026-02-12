<!DOCTYPE html>
<html>
<head>
    <title>Token Generado</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <div class="container mt-5">
        <div class="card p-4 shadow">
            <h2 class="text-center">Token Generado</h2>
            <p class="text-center">Dispositivo: <strong>{{ $deviceId }}</strong></p>
            <div class="alert alert-info mt-3">
                <p>Token generado:</p>
                <h3 class="text-center">{{ $token }}</h3>
                <p>Este token expirará en 5 minutos.</p>
            </div>
            <div class="alert alert-success mt-3">
                El ESP32 activará el relé automáticamente en breve.
            </div>
        </div>
    </div>
</body>
</html>
