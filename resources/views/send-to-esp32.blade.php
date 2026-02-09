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
        .color-example {
            width: 30px;
            height: 30px;
            border-radius: 50%;
            display: inline-block;
            margin-right: 8px;
        }
        .form-check-input-color {
            width: 1.5em;
            height: 1.5em;
            margin-top: 0.2em;
            border: 2px solid #dee2e6;
        }
        .form-check-input-color:checked {
            border-color: #0d6efd;
            box-shadow: 0 0 0 0.25rem rgba(13, 110, 253, 0.25);
        }
    </style>
</head>
<body>
    <div class="container py-5">
        <div class="row justify-content-center">
            <div class="col-md-8">
                <div class="card shadow-lg rounded-4 overflow-hidden">
                    <div class="card-header bg-primary text-white p-4">
                        <h3 class="mb-0 text-center fw-bold">Enviar Mensaje al ESP32</h3>
                    </div>
                    <div class="card-body bg-light p-4">
                        <form method="POST" action="{{ route('send-to-esp32') }}" class="needs-validation" novalidate>
                            @csrf
                            <!-- Campo para el mensaje -->
                            <div class="mb-4">
                                <label for="message" class="form-label fw-bold fs-5">Mensaje:</label>
                                <textarea class="form-control border border-primary rounded-3 p-3 fs-5" id="message" name="message" rows="5"
                                          placeholder="Ej: ¡Hola ESP32! Muestra este mensaje..." required></textarea>
                                <div class="invalid-feedback">Por favor, ingresa un mensaje.</div>
                            </div>

                            <!-- Selección de color con radio buttons -->
                            <div class="mb-4">
                                <label class="form-label fw-bold fs-5">Color del texto:</label>
                                <div class="row mb-3">
                                    <div class="col-md-6">
                                        <div class="form-check mb-2">
                                            <input class="form-check-input form-check-input-color" type="radio" name="colorRadio" id="colorCyan" value="07FF" checked>
                                            <label class="form-check-label" for="colorCyan">
                                                <div class="color-example" style="background-color: #00FFFF; display: inline-block;"></div>
                                                Cyan (07FF)
                                            </label>
                                        </div>
                                        <div class="form-check mb-2">
                                            <input class="form-check-input form-check-input-color" type="radio" name="colorRadio" id="colorRed" value="F800">
                                            <label class="form-check-label" for="colorRed">
                                                <div class="color-example" style="background-color: #FF0000; display: inline-block;"></div>
                                                Rojo (F800)
                                            </label>
                                        </div>
                                        <div class="form-check mb-2">
                                            <input class="form-check-input form-check-input-color" type="radio" name="colorRadio" id="colorYellow" value="FFE0">
                                            <label class="form-check-label" for="colorYellow">
                                                <div class="color-example" style="background-color: #FFFF00; display: inline-block;"></div>
                                                Amarillo (FFE0)
                                            </label>
                                        </div>
                                        <div class="form-check">
                                            <input class="form-check-input form-check-input-color" type="radio" name="colorRadio" id="colorPink" value="F81F">
                                            <label class="form-check-label" for="colorPink">
                                                <div class="color-example" style="background-color: #FF00FF; display: inline-block;"></div>
                                                Rosa (F81F)
                                            </label>
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-check mb-2">
                                            <input class="form-check-input form-check-input-color" type="radio" name="colorRadio" id="colorGreen" value="07E0">
                                            <label class="form-check-label" for="colorGreen">
                                                <div class="color-example" style="background-color: #00FF00; display: inline-block;"></div>
                                                Verde (07E0)
                                            </label>
                                        </div>
                                        <div class="form-check mb-2">
                                            <input class="form-check-input form-check-input-color" type="radio" name="colorRadio" id="colorBlue" value="001F">
                                            <label class="form-check-label" for="colorBlue">
                                                <div class="color-example" style="background-color: #0000FF; display: inline-block;"></div>
                                                Azul (001F)
                                            </label>
                                        </div>
                                        <div class="form-check mb-2">
                                            <input class="form-check-input form-check-input-color" type="radio" name="colorRadio" id="colorWhite" value="FFFF">
                                            <label class="form-check-label" for="colorWhite">
                                                <div class="color-example" style="background-color: #FFFFFF; display: inline-block; border: 1px solid #ccc;"></div>
                                                Blanco (FFFF)
                                            </label>
                                        </div>
                                    </div>
                                </div>

                                <!-- Campo oculto para el color (se actualiza con JS) -->
                                <div class="input-group mb-3">
                                    <span class="input-group-text bg-primary text-white fs-5">0x</span>
                                    <input type="text" class="form-control border border-primary rounded-end-3 p-3 fs-5" id="color" name="color"
                                           value="07FF" maxlength="4" required readonly>
                                    <div class="invalid-feedback">Color requerido.</div>
                                </div>
                            </div>

                            <!-- Botón para enviar -->
                            <div class="d-grid gap-2">
                                <button type="submit" class="btn btn-primary btn-lg py-3 fs-5 fw-bold">Enviar al ESP32</button>
                            </div>
                        </form>

                        @if(session('success'))
                            <div class="alert alert-success mt-4 p-3 d-flex align-items-center fs-5">
                                <i class="bi bi-check-circle-fill me-2"></i>
                                {{ session('success') }}
                            </div>
                        @endif

                        <div class="mt-4 p-4 bg-white rounded-4 shadow-sm fs-5">
                            <h5 class="fw-bold mb-3"><i class="bi bi-info-circle-fill me-2"></i>Información:</h5>
                            <p>Selecciona un color y escribe tu mensaje. El ESP32 lo mostrará en la pantalla con el estilo elegido.</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Bootstrap 5 JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <!-- Script para actualizar el campo de color -->
    <script>
        // Actualizar el campo de texto cuando se selecciona un color
        document.querySelectorAll('input[name="colorRadio"]').forEach(radio => {
            radio.addEventListener('change', function() {
                document.getElementById('color').value = this.value;
            });
        });

        // Validación del formulario
        (function () {
            'use strict';
            var forms = document.querySelectorAll('.needs-validation');
            Array.prototype.slice.call(forms).forEach(function (form) {
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
