<!-- resources/views/token.blade.php -->
<!DOCTYPE html>
<html>
<head>
    <title>Token de Acceso</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <div class="container mt-5">
        <div class="card p-4 shadow">
            <h2 class="text-center">Token de Acceso</h2>
            <p class="text-center">Dispositivo: <strong>{{ $deviceId }}</strong></p>

            <div class="alert alert-info mt-3">
                <p>Token generado:</p>
                <h3 class="text-center">{{ $token }}</h3>
                <p>Este token expirará en 5 minutos.</p>
            </div>

            <form id="activateForm" class="mt-4">
                <div class="mb-3">
                    <label class="form-label">IP del ESP32 (ej: 192.168.1.100):</label>
                    <input type="text" class="form-control" id="esp32Ip" value="{{ $esp32Ip ?? '' }}" required>
                </div>
                <button type="submit" class="btn btn-success w-100">Activar Ducha</button>
            </form>
        </div>
    </div>

    <script>
        document.getElementById('activateForm').addEventListener('submit', function(e) {
            e.preventDefault();
            const esp32Ip = document.getElementById('esp32Ip').value;
            const token = "{{ $token }}";

            fetch(`http://${esp32Ip}/activate?token=${token}`)
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
