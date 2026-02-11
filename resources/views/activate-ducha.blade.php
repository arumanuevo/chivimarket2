<!DOCTYPE html>
<html>
<head>
    <title>Activar Ducha</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <div class="container mt-5">
        <div class="card p-4 shadow">
            <h2 class="text-center">Activar Ducha</h2>
            <p class="text-center">Dispositivo: <strong>{{ $deviceId }}</strong></p>

            <form id="activateForm">
                <input type="hidden" name="device_id" value="{{ $deviceId }}">
                <input type="hidden" name="temp_token" value="{{ $tempToken }}">
                <button type="submit" class="btn btn-success btn-lg w-100">
                    Activar Ducha (10 segundos)
                </button>
            </form>
        </div>
    </div>

    <script>
        document.getElementById('activateForm').addEventListener('submit', function(e) {
            e.preventDefault();
            const deviceId = "{{ $deviceId }}";
            const tempToken = "{{ $tempToken }}";
            const esp32Ip = prompt("Ingresa la IP del ESP32 (ej: 192.168.1.100):", "{{ $esp32Ip }}");

            // Generar un token de pago (simulado)
            const paymentToken = "PAY_" + Math.random().toString(36).substr(2, 9);

            // Enviar el token al ESP32
            fetch(`http://${esp32Ip}/activate?token=${paymentToken}`)
                .then(response => response.text())
                .then(data => {
                    alert(data);
                    window.location.reload();
                })
                .catch(error => alert("Error: " + error));
        });
    </script>
</body>
</html>
