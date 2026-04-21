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
            margin-top: 20px;
            min-height: 100px;
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
            // Configurar el SDK de Mercado Pago con tu Public Key
            const mp = new MercadoPago('APP_USR-24f06e09-3b17-4c64-bb41-1e1979237495');

            // Crear el botón de pago
            const bricksBuilder = mp.bricks();

            // Función para renderizar el botón de pago
            async function renderWalletBrick(preferenceId) {
                try {
                    await bricksBuilder.create("wallet", "walletBrick_container", {
                        initialization: {
                            preferenceId: preferenceId,
                        },
                        customization: {
                            texts: {
                                action: 'pagar',
                                valueProps: {
                                    splitPayment: {
                                        installmentsLabel: 'cuotas sin interés'
                                    }
                                }
                            }
                        }
                    });
                    console.log("Botón de pago renderizado con éxito");
                } catch (error) {
                    console.error("Error al renderizar el botón de pago:", error);
                }
            }

            // Obtener el token CSRF
            const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

            // Crear la preferencia de pago al cargar la página
            fetch('/create-preference', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': csrfToken,
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: JSON.stringify({
                    device_id: '{{ $deviceId }}',
                    temp_token: '{{ $tempToken }}'
                })
            })
            .then(response => {
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                return response.json();
            })
            .then(data => {
                if (data.preferenceId) {
                    console.log("Preferencia de pago creada con ID:", data.preferenceId);
                    renderWalletBrick(data.preferenceId);
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