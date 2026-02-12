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

                    <!-- Cuenta regresiva visual -->
                    <div class="mt-4">
                        <p class="fs-5">Tiempo restante para activación:</p>
                        <div id="countdown" class="fs-3 fw-bold text-primary">05:00</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Cuenta regresiva de 5 minutos (300 segundos)
        let timeLeft = 300;
        const countdownElement = document.getElementById('countdown');

        const timer = setInterval(() => {
            timeLeft--;
            const minutes = Math.floor(timeLeft / 60);
            const seconds = timeLeft % 60;
            countdownElement.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;

            if (timeLeft <= 0) {
                clearInterval(timer);
                countdownElement.textContent = "00:00";
                countdownElement.classList.remove('text-primary');
                countdownElement.classList.add('text-danger');
            }
        }, 1000);
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
