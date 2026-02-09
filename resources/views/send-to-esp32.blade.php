<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Enviar Mensaje al ESP32</title>
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css">
    <style>
        body {
            background-color: #f8f9fa;
        }
        .card {
            border: none;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .rounded-4 {
            border-radius: 1rem !important;
        }
        .badge-custom {
            border-radius: 0.5rem;
            padding: 0.3rem 0.6rem;
            font-weight: 500;
        }
        .color-example {
            width: 30px;
            height: 30px;
            border-radius: 50%;
            display: inline-block;
        }
    </style>
</head>
<body>
    <div class="container py-5">
        <div class="row justify-content-center">
            <div class="col-md-8">
                <!-- Tarjeta principal -->
                <div class="card shadow-lg rounded-4 overflow-hidden">
                    <div class="card-header bg-primary text-white p-4">
                        <h3 class="mb-0 text-center fw-bold">Enviar Mensaje al ESP32</h3>
                    </div>
                    <div class="card-body bg-light p-4">
                        <!-- Formulario para enviar mensajes -->
                        <form method="POST" action="{{ route('send-to-esp32') }}" class="needs-validation" novalidate>
                            @csrf
                            <!-- Campo para el mensaje -->
                            <div class="mb-4">
                                <label for="message" class="form-label fw-bold">Mensaje:</label>
                                <textarea class="form-control border border-primary rounded-3 p-3" id="message" name="message" rows="4"
                                          placeholder="Ej: ¡Hola ESP32! Muestra este mensaje en la pantalla..." required></textarea>
                                <div class="invalid-feedback">
                                    Por favor, ingresa un mensaje.
                                </div>
                            </div>
                            <!-- Campo para el color -->
                            <div class="mb-4">
                                <label for="color" class="form-label fw-bold">Color del Texto (hexadecimal):</label>
                                <div class="input-group">
                                    <span class="input-group-text bg-primary text-white">0x</span>
                                    <input type="text" class="form-control border border-primary rounded-end-3 p-3" id="color" name="color"
                                           value="07FF" placeholder="Ej: 07FF" maxlength="4" required>
                                    <div class="invalid-feedback">
                                        Por favor, ingresa un color válido (ej: 07FF).
                                    </div>
                                </div>
                                <small class="text-muted">Ejemplos: <span class="fw-bold">07FF</span> (Cyan), <span class="fw-bold">F800</span> (Rojo), <span class="fw-bold">FFE0</span> (Amarillo).</small>
                            </div>
                            <!-- Ejemplos de colores -->
                            <div class="mb-4">
                                <h5 class="fw-bold">Ejemplos de Colores:</h5>
                                <div class="d-flex flex-wrap gap-3 mt-2">
                                    <div class="d-flex align-items-center gap-2">
                                        <div class="color-example" style="background-color: #00FFFF;"></div>
                                        <span class="badge-custom bg-light text-dark">07FF (Cyan)</span>
                                    </div>
                                    <div class="d-flex align-items-center gap-2">
                                        <div class="color-example" style="background-color: #FF0000;"></div>
                                        <span class="badge-custom bg-light text-dark">F800 (Rojo)</span>
                                    </div>
                                    <div class="d-flex align-items-center gap-2">
                                        <div class="color-example" style="background-color: #FFFF00;"></div>
                                        <span class="badge-custom bg-light text-dark">FFE0 (Amarillo)</span>
                                    </div>
                                    <div class="d-flex align-items-center gap-2">
                                        <div class="color-example" style="background-color: #FF00FF;"></div>
                                        <span class="badge-custom bg-light text-dark">F81F (Rosa)</span>
                                    </div>
                                </div>
                            </div>
                            <!-- Botón para enviar -->
                            <div class="d-grid gap-2">
                                <button type="submit" class="btn btn-primary btn-lg py-3 fw-bold">Enviar al ESP32</button>
                            </div>
                        </form>

                        <!-- Mensaje de éxito -->
                        @if(session('success'))
                            <div class="alert alert-success mt-4 p-3 d-flex align-items-center">
                                <i class="bi bi-check-circle-fill me-2"></i>
                                <div>{{ session('success') }}</div>
                            </div>
                        @endif

                        <!-- Información adicional -->
                        <div class="mt-4 p-4 bg-white rounded-4 shadow-sm">
                            <h5 class="fw-bold mb-3"><i class="bi bi-info-circle-fill me-2"></i>Información:</h5>
                            <p class="mb-3">Esta página te permite enviar mensajes al dispositivo <strong>ESP32</strong> conectado a la pantalla ST7789. Los mensajes se mostrarán en la pantalla con el color que elijas.</p>
                            <p class="mb-0">El ESP32 consulta periódicamente el servidor para obtener nuevos mensajes.</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Bootstrap 5 JS Bundle with Popper -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <!-- Validación del formulario -->
    <script>
        (function () {
            'use strict';
            var forms = document.querySelectorAll('.needs-validation');
            Array.prototype.slice.call(forms)
                .forEach(function (form) {
                    form.addEventListener('submit', function (event) {
                        if (!form.checkValidity()) {
                            event.preventDefault();
                            event.stopPropagation();
                        }
                        form.classList.add('was-validated');
                    }, false);
                });
        })();
    </script>
</body>
</html>
