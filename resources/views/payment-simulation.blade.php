<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chivimarket - Simulador de Pagos</title>
    <!-- Tailwind or inline styles for a quick modern mockup -->
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Inter', sans-serif;
            background-color: #f9fafb;
        }

        .brand-orange {
            background-color: #ea580c;
        }

        .brand-orange-hover {
            background-color: #c2410c;
        }
    </style>
</head>

<body class="h-screen flex items-center justify-center">
    <div class="max-w-md w-full bg-white rounded-xl shadow-lg p-8 border border-gray-100">
        <div class="text-center mb-8">
            <h1 class="text-3xl font-bold text-gray-800 mb-2">Simulador de Pago</h1>
            <p class="text-gray-500">Modo Desarrollo (Reemplaza a MercadoPago)</p>
        </div>

        <div class="bg-orange-50 border border-orange-100 rounded-lg p-4 mb-6">
            <div class="flex justify-between mb-2">
                <span class="text-gray-600 font-semibold">Plan Seleccionado:</span>
                <span class="text-gray-800 font-bold" id="planName">Premium</span>
            </div>
            <div class="flex justify-between">
                <span class="text-gray-600 font-semibold">Total a pagar:</span>
                <span class="text-gray-800 font-bold text-lg" id="planPrice">$ 5000.00</span>
            </div>
        </div>

        <form id="simulationForm" action="/api/subscription/simulate-webhook" method="POST" class="space-y-4">
            <!-- Add CSRF token in a real integrated view. Given this might be called without auth, we simulate it via API -->
            <input type="hidden" name="user_id" id="userId" value="1">
            <input type="hidden" name="plan" id="planInput" value="premium">
            <input type="hidden" name="status" value="approved">

            <div class="space-y-3">
                <button type="submit"
                    class="w-full brand-orange hover:brand-orange-hover text-white font-bold py-3 px-4 rounded-lg transition duration-200 shadow-md">
                    💰 Simular Pago Exitoso
                </button>

                <button type="button" onclick="failPayment()"
                    class="w-full bg-gray-200 hover:bg-gray-300 text-gray-700 font-bold py-3 px-4 rounded-lg transition duration-200">
                    ❌ Simular Pago Rechazado
                </button>
            </div>
        </form>
    </div>

    <script>
        // Catch params from URL if passed (e.g. ?user_id=1&plan=premium&price=5000)
        const urlParams = new URLSearchParams(window.location.search);

        if (urlParams.has('plan')) {
            document.getElementById('planName').innerText = urlParams.get('plan').toUpperCase();
            document.getElementById('planInput').value = urlParams.get('plan');
        }
        if (urlParams.has('price')) {
            document.getElementById('planPrice').innerText = "$ " + urlParams.get('price');
        }
        if (urlParams.has('user_id')) {
            document.getElementById('userId').value = urlParams.get('user_id');
        }

        document.getElementById('simulationForm').addEventListener('submit', function (e) {
            e.preventDefault();
            alert('¡Pago simulado exitosamente! El webhook interno actualizaría la suscripción.');
            // In a real scenario, make a fetch call or let form submit.
            // window.location.href = '/payment-success-callback-to-flutter';
        });

        function failPayment() {
            alert('Pago rechazado. Volviendo a la aplicación...');
            // window.location.href = '/payment-failed-callback-to-flutter';
        }
    </script>
</body>

</html>