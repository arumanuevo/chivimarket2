<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Validar Dispositivo</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body {
            background-color: #f8f9fa;
        }
        .card {
            border: none;
            border-radius: 10px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }
        .btn-custom {
            padding: 15px;
            font-size: 1.2rem;
            font-weight: 600;
            border-radius: 8px;
        }
    </style>
</head>
<body class="bg-light">
    <div class="container">
        <div class="row justify-content-center">
            <div class="col-12 col-md-8 col-lg-6 mt-5">
                <div class="card p-4">
                    <h2 class="text-center mb-4">Validar Dispositivo</h2>
                    <p class="text-center fs-5">Dispositivo: <strong>{{ $deviceId }}</strong></p>

                    @if(isset($error))
                        <div class="alert alert-danger text-center">
                            {{ $error }}
                        </div>
                    @endif

                    <form method="POST" action="/generate-token" class="mt-4">
                        @csrf
                        <input type="hidden" name="device_id" value="{{ $deviceId }}">
                        <input type="hidden" name="temp_token" value="{{ $tempToken }}">
                        <button type="submit" class="btn btn-primary btn-custom w-100">
                            Generar Token de Acceso
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- Bootstrap JS (opcional, solo si necesitas funcionalidades interactivas) -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
