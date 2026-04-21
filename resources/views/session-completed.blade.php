<!DOCTYPE html>
<html>
<head>
    <title>Sesión Completada</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body {
            background-color: #f8f9fa;
            font-size: 1.2rem;
        }
        .card {
            border: none;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
            border-radius: 10px;
        }
    </style>
</head>
<body class="bg-light">
    <div class="container py-5">
        <div class="row justify-content-center">
            <div class="col-12 col-md-8 col-lg-6">
                <div class="card p-4 text-center">
                    <h2 class="mb-4">Sesión Completada</h2>
                    <div class="alert alert-success mt-4">
                        <p>La sesión de ducha ha finalizado.</p>
                        <p>¡Gracias por usar nuestro servicio!</p>
                    </div>
                    <div class="alert alert-info mt-4">
                        <p>Si deseas otra sesión de ducha, escanea nuevamente el código QR del dispositivo.</p>
                    </div>
                    <button class="btn btn-danger mt-4" onclick="window.close()">Cerrar esta pestaña</button>
                </div>
            </div>
        </div>
    </div>
    <script>
        // Función para cerrar la pestaña
        function closeTab() {
            window.open('', '_self', '');
            window.close();
        }

        // Asignar la función al botón
        document.querySelector('.btn-danger').addEventListener('click', function() {
            closeTab();
        });
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>