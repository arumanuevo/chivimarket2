<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Nueva Transacción</title>
    <script src="https://sdk.mercadopago.com/js/v2"></script>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f8f9fa;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background-color: #fff;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
        h1 {
            text-align: center;
            color: #333;
        }
        #wallet_container {
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Nueva Transacción</h1>
        <p>Haz clic en el botón de abajo para realizar el pago.</p>
        <div id="wallet_container"></div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            fetch('/create-preference', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
                    'Accept': 'application/json'
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.preferenceId) {
                    const mp = new MercadoPago('APP_USR-24f06e09-3b17-4c64-bb41-1e1979237495'); // Reemplaza con tu Public Key
                    const bricksBuilder = mp.bricks();

                    bricksBuilder.create("wallet", "wallet_container", {
                        initialization: {
                            preferenceId: data.preferenceId,
                        },
                    });
                } else {
                    console.error('Error al obtener el preferenceId:', data);
                }
            })
            .catch(error => console.error('Error:', error));
        });
    </script>
</body>
</html>