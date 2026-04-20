<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Prueba de Pago con Mercado Pago</title>
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
                <div class="card p-4 text-center">
                    <h2 class="mb-4">Prueba de Pago</h2>
                    <p class="fs-5">Este es un ejemplo de pago con Mercado Pago.</p>

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
            console.log("DOM cargado");

            // Configurar el SDK de Mercado Pago con tu Public Key
            const mp = new MercadoPago('APP_USR-24f06e09-3b17-4c64-bb41-1e1979237495');
            console.log("SDK de Mercado Pago configurado:", mp);

            // Crear el botón de pago
            const bricksBuilder = mp.bricks();
            console.log("Bricks builder creado:", bricksBuilder);

            // Crear la preferencia de pago
            fetch('/create-test-preference', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                }
            })
            .then(response => {
                console.log("Respuesta del servidor:", response);
                if (!response.ok) {
                    throw new Error(`Network response was not ok: ${response.status}`);
                }
                return response.json();
            })
            .then(data => {
                console.log("Datos recibidos:", data);
                if (data.preferenceId) {
                    console.log("Preferencia ID:", data.preferenceId);
                    renderWalletBrick(data.preferenceId);
                } else if (data.error) {
                    console.error("Error del servidor:", data.error);
                    alert("Error al crear la preferencia: " + data.error);
                } else {
                    console.error("No se recibió un preferenceId válido:", data);
                }
            })
            .catch(error => {
                console.error('Error en la solicitud:', error);
                alert("Error en la solicitud: " + error.message);
            });

            // Función para renderizar el botón de pago
            async function renderWalletBrick(preferenceId) {
                console.log("Renderizando botón con preferenceId:", preferenceId);
                try {
                    await bricksBuilder.create("wallet", "walletBrick_container", {
                        initialization: {
                            preferenceId: preferenceId,
                        },
                    });
                    console.log("Botón renderizado con éxito");
                } catch (error) {
                    console.error("Error al renderizar el botón:", error);
                    alert("Error al renderizar el botón: " + error.message);
                }
            }
        });
    </script>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>