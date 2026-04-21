<!DOCTYPE html>
<html>
<head>
    <title>Token Generado</title>
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
        .token-box {
            background-color: #e9ecef;
            padding: 15px;
            border-radius: 8px;
            font-size: 1.3rem;
            word-break: break-all;
        }
    </style>
</head>
<body class="bg-light">
    <div class="container py-5">
        <div class="row justify-content-center">
            <div class="col-12 col-md-8 col-lg-6">
                <div class="card p-4 text-center">
                    <h2 class="mb-4">Token Generado</h2>
                    <p class="fs-5">Dispositivo: <strong>{{ $deviceId }}</strong></p>

                    <div class="alert alert-info mt-4">
                        <p class="mb-2">Token generado:</p>
                        <div class="token-box p-3 mb-3">{{ $token }}</div>
                        <p class="mb-0">Este token expirará en 5 minutos.</p>
                    </div>

                    <div class="alert alert-success mt-4">
                        El ESP32 activará el relé automáticamente en breve.
                    </div>

                    <!-- Cuenta regresiva visual para activación -->
                    <div class="mt-4">
                        <p class="fs-5">Tiempo restante para activación:</p>
                        <div id="activationCountdown" class="fs-3 fw-bold text-primary">05:00</div>
                    </div>

                    <!-- Cuenta regresiva para redirigir -->
                    <div class="mt-4">
                        <p class="fs-5">Serás redirigido automáticamente cuando finalice la sesión:</p>
                        <div id="redirectCountdown" class="fs-3 fw-bold text-primary">20</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Cuenta regresiva de 5 minutos (300 segundos) para activación
        let activationTimeLeft = 300;
        const activationCountdownElement = document.getElementById('activationCountdown');

        const activationTimer = setInterval(() => {
            activationTimeLeft--;
            const minutes = Math.floor(activationTimeLeft / 60);
            const seconds = activationTimeLeft % 60;
            activationCountdownElement.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;

            if (activationTimeLeft <= 0) {
                clearInterval(activationTimer);
                activationCountdownElement.textContent = "00:00";
                activationCountdownElement.classList.remove('text-primary');
                activationCountdownElement.classList.add('text-danger');
            }
        }, 1000);

        // Cuenta regresiva de 20 segundos para redirigir
        let redirectTimeLeft = 20;
        const redirectCountdownElement = document.getElementById('redirectCountdown');

        const redirectTimer = setInterval(() => {
            redirectTimeLeft--;
            redirectCountdownElement.textContent = redirectTimeLeft;

            if (redirectTimeLeft <= 0) {
                clearInterval(redirectTimer);
                window.location.href = "/session-completed";
            }
        }, 1000);

        // Deshabilitar la recarga de la página
        window.onbeforeunload = function(e) {
            e.preventDefault();
            e.returnValue = '';
            return '';
        };

        // Evitar que el usuario recargue la página con F5 o Ctrl+R
        document.onkeydown = function(e) {
            if ((e.ctrlKey && e.key === 'r') || e.key === 'F5') {
                e.preventDefault();
                alert('No puedes recargar esta página.');
            }
        };
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>



