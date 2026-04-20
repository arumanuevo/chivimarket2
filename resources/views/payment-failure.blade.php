<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pago Fallido</title>
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
    </style>
</head>
<body class="bg-light">
    <div class="container">
        <div class="row justify-content-center">
            <div class="col-12 col-md-8 col-lg-6 mt-5">
                <div class="card p-4 text-center">
                    <h2 class="text-danger mb-4">Pago Fallido</h2>
                    <p class="fs-5">No se pudo procesar el pago. Por favor, inténtalo nuevamente.</p>
                    <form method="GET" action="/create-payment" class="mt-4">
                        <input type="hidden" name="device_id" value="{{ $deviceId }}">
                        <input type="hidden" name="temp_token" value="{{ $tempToken }}">
                        <button type="submit" class="btn btn-primary w-100">
                            Volver a Intentar
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>
</body>
</html>