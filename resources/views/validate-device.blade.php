<!DOCTYPE html>
<html>
<head>
    <title>Validar Dispositivo</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body {
            background-color: #f8f9fa;
            font-size: 1.2rem; /* Tamaño de fuente base más grande */
        }
        .card {
            border: none;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
            border-radius: 10px;
        }
        .btn {
            padding: 12px;
            font-size: 1.2rem;
            font-weight: 600;
        }
    </style>
</head>
<body class="bg-light">
    <div class="container py-5">
        <div class="row justify-content-center">
            <div class="col-12 col-md-8 col-lg-6">
                <div class="card p-4">
                    <h2 class="text-center mb-4">Validar Dispositivo</h2>
                    <p class="text-center fs-5">Dispositivo: <strong>{{ $deviceId }}</strong></p>
                    <form method="POST" action="/generate-token" class="mt-4">
                        @csrf
                        <input type="hidden" name="device_id" value="{{ $deviceId }}">
                        <button type="submit" class="btn btn-primary w-100 py-3">
                            Generar Token de Acceso
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
