<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Administración de Duchas</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body {
            background-color: #f8f9fa;
            font-size: 1rem;
        }
        .card {
            border: none;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
            border-radius: 10px;
        }
        .table-container {
            max-height: 400px;
            overflow-y: auto;
        }
    </style>
</head>
<body class="bg-light">
    <div class="container py-5">
        <div class="row justify-content-center">
            <div class="col-12">
                <div class="card p-4">
                    <h2 class="mb-4 text-center">Administración de Duchas</h2>

                    <!-- Configuración del Precio -->
                    <div class="mb-5">
                        <h4 class="mb-3">Configuración del Precio</h4>
                        <div class="row">
                            <div class="col-md-6">
                                <div class="input-group mb-3">
                                    <span class="input-group-text">Precio Actual (ARS)</span>
                                    <input type="number" id="currentPrice" class="form-control" readonly>
                                    <button class="btn btn-outline-secondary" type="button" id="refreshPrice">🔄</button>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="input-group mb-3">
                                    <span class="input-group-text">Nuevo Precio (ARS)</span>
                                    <input type="number" id="newPrice" class="form-control" step="0.01" min="0.01">
                                    <button class="btn btn-primary" type="button" id="updatePrice">Actualizar</button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Historial de Uso -->
                    <div>
                        <h4 class="mb-3">Historial de Uso</h4>
                        <div class="table-container mb-3">
                            <table class="table table-striped table-hover">
                                <thead class="table-dark">
                                    <tr>
                                        <th>ID</th>
                                        <th>Dispositivo</th>
                                        <th>Token</th>
                                        <th>Fecha de Uso</th>
                                    </tr>
                                </thead>
                                <tbody id="usageHistory">
                                    <!-- Se llenará con datos de la API -->
                                </tbody>
                            </table>
                        </div>
                        <button class="btn btn-secondary" type="button" id="refreshUsage">Refrescar Historial</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal para mensajes -->
    <div class="modal fade" id="messageModal" tabindex="-1" aria-labelledby="messageModalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="messageModalLabel">Mensaje</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body" id="messageModalBody">
                    <!-- Mensaje dinámico -->
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const token = localStorage.getItem('showerAdminToken');
            const messageModal = new bootstrap.Modal(document.getElementById('messageModal'));

            if (!token) {
                window.location.href = '/shower-admin/login';
                return;
            }

            // Función para mostrar mensajes
            function showMessage(message, isError = false) {
                const modalBody = document.getElementById('messageModalBody');
                modalBody.innerHTML = message;
                if (isError) {
                    modalBody.className = 'modal-body text-danger';
                } else {
                    modalBody.className = 'modal-body text-success';
                }
                messageModal.show();
            }

            // Función para obtener el precio actual
            function getCurrentPrice() {
                axios.get('/api/shower-admin/price', {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                })
                .then(response => {
                    document.getElementById('currentPrice').value = response.data.price;
                })
                .catch(error => {
                    if (error.response && error.response.status === 401) {
                        localStorage.removeItem('showerAdminToken');
                        window.location.href = '/shower-admin/login';
                    } else {
                        showMessage('Error al obtener el precio actual: ' + (error.response?.data?.message || error.message), true);
                    }
                });
            }

            // Función para actualizar el precio
            document.getElementById('updatePrice').addEventListener('click', function() {
                const newPrice = document.getElementById('newPrice').value;

                if (!newPrice || newPrice <= 0) {
                    showMessage('Por favor, ingresa un precio válido.', true);
                    return;
                }

                axios.post('/api/shower-admin/price', { price: newPrice }, {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                })
                .then(response => {
                    showMessage(response.data.message);
                    getCurrentPrice();
                    document.getElementById('newPrice').value = '';
                })
                .catch(error => {
                    if (error.response && error.response.status === 401) {
                        localStorage.removeItem('showerAdminToken');
                        window.location.href = '/shower-admin/login';
                    } else {
                        showMessage('Error al actualizar el precio: ' + (error.response?.data?.message || error.message), true);
                    }
                });
            });

            // Función para obtener el historial de uso
            function getUsageHistory() {
                axios.get('/api/shower-admin/usage', {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                })
                .then(response => {
                    const usageHistory = document.getElementById('usageHistory');
                    usageHistory.innerHTML = '';

                    response.data.forEach(usage => {
                        const row = document.createElement('tr');
                        row.innerHTML = `
                            <td>${usage.id}</td>
                            <td>${usage.device_id}</td>
                            <td>${usage.token}</td>
                            <td>${new Date(usage.used_at).toLocaleString()}</td>
                        `;
                        usageHistory.appendChild(row);
                    });
                })
                .catch(error => {
                    if (error.response && error.response.status === 401) {
                        localStorage.removeItem('showerAdminToken');
                        window.location.href = '/shower-admin/login';
                    } else {
                        showMessage('Error al obtener el historial de uso: ' + (error.response?.data?.message || error.message), true);
                    }
                });
            }

            // Botón para refrescar el precio
            document.getElementById('refreshPrice').addEventListener('click', getCurrentPrice);

            // Botón para refrescar el historial de uso
            document.getElementById('refreshUsage').addEventListener('click', getUsageHistory);

            // Cargar datos al inicio
            getCurrentPrice();
            getUsageHistory();
        });
    </script>
</body>
</html>