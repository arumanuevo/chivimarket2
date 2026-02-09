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
        /* Estilo para los círculos de colores (más pequeños y alineados) */
        .color-circle {
            width: 20px;
            height: 20px;
            border-radius: 50%;
            display: inline-block;
            margin-right: 8px;
            vertical-align: middle;
            border: 1px solid #dee2e6; /* Borde sutil para mejor visibilidad */
        }
        /* Estilo para los radio buttons personalizados */
        .form-check-input-color {
            margin-right: 10px;
            margin-top: 2px;
        }
        /* Estilo para las etiquetas de los colores */
        .form-check-label-color {
            display: flex;
            align-items: center;
            padding-left: 5px;
        }
        /* Estilo para el campo de color (input) */
        .color-input-group {
            max-width: 150px;
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
                                          placeholder="Ej: ¡Hola ESP32! Muestra este mensaje en la pantalla..." required></textarea>
                                <div class="invalid-feedback">Por favor, ingresa un mensaje.</div>
                            </div>

                            <!-- Selección de color con radio buttons -->
                            <div class="mb-4">
                                <label class="form-label fw-bold fs-5">Color del texto:</label>
                                <div class="row">
                                    <!-- Columna 1 de colores -->
                                    <div class="col-md-6">
                                        <div class="form-check mb-2">
                                            <input class="form-check-input form-check-input-color" type="radio" name="colorRadio" id="colorCyan" value="07FF" checked>
                                            <label class="form-check-label form-check-label-color" for="colorCyan">
                                                <span class="color-circle" style="background-color: #00FFFF;"></span>
                                                Cyan (07FF)
                                            </label>
                                        </div>
                                        <div class="form-check mb-2">
                                            <input class="form-check-input form-check-input-color" type="radio" name="colorRadio" id="colorRed" value="F800">
                                            <label class="form-check-label form-check-label-color" for="colorRed">
                                                <span class="color-circle" style="background-color: #FF0000;"></span>
                                                Rojo (F800)
                                            </label>
                                        </div>
                                        <div class="form-check mb-2">
                                            <input class="form-check-input form-check-input-color" type="radio" name="colorRadio" id="colorYellow" value="FFE0">
                                            <label class="form-check-label form-check-label-color" for="colorYellow">
                                                <span class="color-circle" style="background-color: #FFFF00;"></span>
                                                Amarillo (FFE0)
                                            </label>
                                        </div>
                                    </div>
                                    <!-- Columna 2 de colores -->
                                    <div class="col-md-6">
                                        <div class="form-check mb-2">
                                            <input class="form-check-input form-check-input-color" type="radio" name="colorRadio" id="colorGreen" value="07E0">
                                            <label class="form-check-label form-check-label-color" for="colorGreen">
                                                <span class="color-circle" style="background-color: #00FF00;"></span>
                                                Verde (07E0)
                                            </label>
                                        </div>
                                        <div class="form-check mb-2">
                                            <input class="form-check-input form-check-input-color" type="radio" name="colorRadio" id="colorBlue" value="001F">
                                            <label class="form-check-label form-check-label-color" for="colorBlue">
                                                <span class="color-circle" style="background-color: #0000FF;"></span>
                                                Azul (001F)
                                            </label>
                                        </div>
                                        <div class="form-check mb-2">
                                            <input class="form-check-input form-check-input-color" type="radio" name="colorRadio" id="colorPink" value="F81F">
                                            <label class="form-check-label form-check-label-color" for="colorPink">
                                                <span class="color-circle" style="background-color: #FF00FF;"></span>
                                                Rosa (F81F)
                                            </label>
                                        </div>
                                        <div class="form-check mb-2">
                                            <input class="form-check-input form-check-input-color" type="radio" name="colorRadio" id="colorWhite" value="FFFF">
                                            <label class="form-check-label form-check-label-color" for="colorWhite">
                                                <span class="color-circle" style="background-color: #FFFFFF; border: 1px solid #ccc;"></span>
                                                Blanco (FFFF)
                                            </label>
                                        </div>
                                    </div>
                                </div>

                                <!-- Campo de texto para el color (se actualiza con JS) -->
                                <div class="input-group color-input-group">
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
                            <p>Podes enviar un mensaje con el color que quieras al ESP32.</p>
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

