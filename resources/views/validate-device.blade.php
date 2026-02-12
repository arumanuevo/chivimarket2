<!-- resources/views/validate-device.blade.php -->
<!DOCTYPE html>
<html>
<head>
    <title>Validar Dispositivo</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <div class="container mt-5">
        <div class="card p-4 shadow">
            <h2 class="text-center">Validar Dispositivo</h2>
            <p class="text-center">Dispositivo: <strong>{{ $deviceId }}</strong></p>

            @if(isset($error))
                <div class="alert alert-danger">
                    {{ $error }}
                </div>
            @endif

            <form method="POST" action="/generate-token">
                @csrf
                <input type="hidden" name="device_id" value="{{ $deviceId }}">
                <input type="hidden" name="temp_token" value="{{ $tempToken }}">
                <button type="submit" class="btn btn-primary w-100">
                    Generar Token de Acceso
                </button>
            </form>
        </div>
    </div>
</body>
</html>

