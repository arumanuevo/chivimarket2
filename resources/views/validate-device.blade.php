<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
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
            margin-bottom: 10px;
        }
        #walletBrick_container {
            min-height: 100px;
            margin-top: 20px;
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

                    <!-- Botón original para generar token directamente -->
                    <form method="POST" action="/generate-token" class="mt-4">
                        @csrf
                        <input type="hidden" name="device_id" value="{{ $deviceId }}">
                        <input type="hidden" name="temp_token" value="{{ $tempToken }}">
                        <button type="submit" class="btn btn-primary btn-custom w-100">
                            Generar Token de Acceso (Sin Pago)
                        </button>
                    </form>

                    <!-- Contenedor para el botón de pago de Mercado Pago -->
                    <div id="walletBrick_container"></div>
                </div>
            </div>
        </div>
    </div>

    <!-- SDK de Mercado Pago -->
    <script src="https://sdk.mercadopago.com/js/v2"></script>

    <!-- Script para inicializar el botón de pago -->
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const mp = new MercadoPago('APP_USR-43fbd867-f172-4af8-a28d-baf6d3b30974');
            const bricksBuilder = mp.bricks();

            fetch('/create-simple-preference', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: JSON.stringify({
                    device_id: '{{ $deviceId }}',
                    temp_token: '{{ $tempToken }}'
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.preferenceId) {
                    bricksBuilder.create("wallet", "walletBrick_container", {
                        initialization: {
                            preferenceId: data.preferenceId,
                        },
                    });
                } else {
                    console.error('No se recibió un preferenceId válido:', data);
                }
            })
            .catch(error => console.error('Error:', error));
        });
    </script>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>