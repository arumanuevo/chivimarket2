@extends('layouts.app')

@section('content')
<div class="container py-5">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <!-- Tarjeta principal -->
            <div class="card shadow-lg border-0 rounded-4">
                <div class="card-header bg-primary text-white rounded-top-4">
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
                                       value="07FF" placeholder="Ej: 07FF (Cyan)" maxlength="4" required>
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
                                    <div style="width: 30px; height: 30px; background-color: #00FFFF; border-radius: 50%;"></div>
                                    <span class="badge bg-light text-dark p-2">07FF (Cyan)</span>
                                </div>
                                <div class="d-flex align-items-center gap-2">
                                    <div style="width: 30px; height: 30px; background-color: #FF0000; border-radius: 50%;"></div>
                                    <span class="badge bg-light text-dark p-2">F800 (Rojo)</span>
                                </div>
                                <div class="d-flex align-items-center gap-2">
                                    <div style="width: 30px; height: 30px; background-color: #FFFF00; border-radius: 50%;"></div>
                                    <span class="badge bg-light text-dark p-2">FFE0 (Amarillo)</span>
                                </div>
                                <div class="d-flex align-items-center gap-2">
                                    <div style="width: 30px; height: 30px; background-color: #FF00FF; border-radius: 50%;"></div>
                                    <span class="badge bg-light text-dark p-2">F81F (Rosa)</span>
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
                        <div class="alert alert-success mt-4 p-3">
                            <i class="bi bi-check-circle-fill me-2"></i> {{ session('success') }}
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

<!-- Script para validación del formulario -->
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
@endsection
