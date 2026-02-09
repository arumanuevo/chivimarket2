@extends('layouts.app')

@section('content')
<div class="container mt-5">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <!-- Tarjeta principal -->
            <div class="card shadow-lg border-0 rounded-lg">
                <div class="card-header bg-primary text-white">
                    <h3 class="mb-0 text-center">Enviar Mensaje al ESP32</h3>
                </div>
                <div class="card-body bg-light">
                    <!-- Formulario para enviar mensajes -->
                    <form method="POST" action="{{ route('send-to-esp32') }}">
                        @csrf
                        <!-- Campo para el mensaje -->
                        <div class="form-group mb-3">
                            <label for="message" class="form-label fw-bold">Mensaje:</label>
                            <textarea class="form-control border border-primary" id="message" name="message" rows="3" placeholder="Escribe el mensaje que deseas enviar al ESP32..." required></textarea>
                        </div>
                        <!-- Campo para el color -->
                        <div class="form-group mb-3">
                            <label for="color" class="form-label fw-bold">Color del Texto (hexadecimal):</label>
                            <div class="input-group">
                                <span class="input-group-text">0x</span>
                                <input type="text" class="form-control border border-primary" id="color" name="color" value="07FF" placeholder="Ej: 07FF (Cyan)" maxlength="4">
                            </div>
                            <small class="text-muted">Ejemplos: 07FF (Cyan), F800 (Rojo), FFE0 (Amarillo), F81F (Rosa).</small>
                        </div>
                        <!-- Botón para enviar -->
                        <div class="d-grid gap-2">
                            <button type="submit" class="btn btn-primary btn-lg">Enviar al ESP32</button>
                        </div>
                    </form>

                    <!-- Mensaje de éxito -->
                    @if(session('success'))
                        <div class="alert alert-success mt-3">
                            {{ session('success') }}
                        </div>
                    @endif

                    <!-- Ejemplo de colores -->
                    <div class="mt-4">
                        <h5 class="fw-bold">Ejemplos de Colores:</h5>
                        <div class="d-flex flex-wrap gap-2 mt-2">
                            <div class="d-flex align-items-center gap-2">
                                <div style="width: 30px; height: 30px; background-color: #00FFFF;" class="rounded"></div>
                                <span>07FF (Cyan)</span>
                            </div>
                            <div class="d-flex align-items-center gap-2">
                                <div style="width: 30px; height: 30px; background-color: #FF0000;" class="rounded"></div>
                                <span>F800 (Rojo)</span>
                            </div>
                            <div class="d-flex align-items-center gap-2">
                                <div style="width: 30px; height: 30px; background-color: #FFFF00;" class="rounded"></div>
                                <span>FFE0 (Amarillo)</span>
                            </div>
                            <div class="d-flex align-items-center gap-2">
                                <div style="width: 30px; height: 30px; background-color: #FF00FF;" class="rounded"></div>
                                <span>F81F (Rosa)</span>
                            </div>
                        </div>
                    </div>

                    <!-- Información adicional -->
                    <div class="mt-4 p-3 bg-white rounded shadow-sm">
                        <h5 class="fw-bold">Información:</h5>
                        <p>Esta página te permite enviar mensajes al dispositivo ESP32 conectado a la pantalla. Los mensajes se mostrarán en la pantalla ST7789 con el color que elijas.</p>
                        <p>El ESP32 consulta periódicamente el servidor para obtener nuevos mensajes.</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
