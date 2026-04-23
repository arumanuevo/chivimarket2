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
                    <div class="d-flex justify-content-between align-items-center mb-4">
                        <h2 class="mb-0 text-center flex-grow-1">Administración de Duchas</h2>
                        <button id="logoutButton" class="btn btn-danger">Cerrar Sesión</button>
                    </div>
                    <div id="errorMessage" class="alert alert-danger" style="display: none;"></div>

                    <!-- Configuración del Precio -->
                    <div id="adminContent" class="mb-5">
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
                    <div id="usageContent">
                        <h4 class="mb-3">Historial de Uso</h4>
                        <div class="table-container mb-3">
                            <table class="table table-striped table-hover">
                                <thead class="table-dark">
                                    <tr>
                                        <th>ID</th>
                                        <th>Dispositivo</th>
                                        <th>Monto (ARS)</th>
                                        <th>Consumo de Agua (L)</th>
                                        <th>Fecha de Uso</th>
                                    </tr>
                                </thead>
                                <tbody id="usageHistory">
                                    <!-- Se llenará con datos de la API -->
                                </tbody>
                            </table>
                        </div>
                        <div class="d-flex justify-content-between">
                            <button class="btn btn-secondary me-2" type="button" id="refreshUsage">Refrescar Historial</button>
                            <button class="btn btn-primary" type="button" id="sumByDevice">Sumar por Dispositivo</button>
                        </div>
                        <div id="sumResult" class="mt-3"></div>
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

            // Función para mostrar mensaje de error
            function showErrorMessage(message) {
                const errorMessage = document.getElementById('errorMessage');
                errorMessage.textContent = message;
                errorMessage.style.display = 'block';
            }

            // Verificar si el usuario está autenticado
            if (!token) {
                showErrorMessage('No estás autenticado. Por favor, inicia sesión.');
                document.getElementById('adminContent').style.display = 'none';
                document.getElementById('usageContent').style.display = 'none';
                return;
            }

            // Función para manejar el logout
            document.getElementById('logoutButton').addEventListener('click', function() {
                localStorage.removeItem('showerAdminToken');
                window.location.href = '/shower-admin/login';
            });

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
                        showErrorMessage('Tu sesión ha expirado. Por favor, inicia sesión nuevamente.');
                        document.getElementById('adminContent').style.display = 'none';
                        document.getElementById('usageContent').style.display = 'none';
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
                        showErrorMessage('Tu sesión ha expirado. Por favor, inicia sesión nuevamente.');
                        document.getElementById('adminContent').style.display = 'none';
                        document.getElementById('usageContent').style.display = 'none';
                    } else {
                        showMessage('Error al actualizar el precio: ' + (error.response?.data?.message || error.message), true);
                    }
                });
            });

            // Función para obtener el historial de uso
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
            const amount = usage.amount ? parseFloat(usage.amount) : 0;
            const waterConsumption = usage.water_consumption ? parseFloat(usage.water_consumption) : 0;
            row.innerHTML = `
                <td>${usage.id}</td>
                <td>${usage.device_id}</td>
                <td>${amount.toFixed(2)}</td>
                <td>${waterConsumption.toFixed(2)}</td>
                <td>${new Date(usage.used_at).toLocaleString('es-AR')}</td>
            `;
            usageHistory.appendChild(row);
        });
    })
    .catch(error => {
        if (error.response && error.response.status === 401) {
            localStorage.removeItem('showerAdminToken');
            showErrorMessage('Tu sesión ha expirado. Por favor, inicia sesión nuevamente.');
            document.getElementById('adminContent').style.display = 'none';
            document.getElementById('usageContent').style.display = 'none';
        } else {
            showMessage('Error al obtener el historial de uso: ' + (error.response?.data?.message || error.message), true);
        }
    });
}

            // Función para sumar por dispositivo
            // Función para sumar por dispositivo
document.getElementById('sumByDevice').addEventListener('click', function() {
    axios.get('/api/shower-admin/usage', {
        headers: {
            'Authorization': `Bearer ${token}`
        }
    })
    .then(response => {
        const sumResult = document.getElementById('sumResult');
        sumResult.innerHTML = '<h5>Totales por Dispositivo</h5>';

        // Agrupar por dispositivo
        const devices = {};
        response.data.forEach(usage => {
            if (!devices[usage.device_id]) {
                devices[usage.device_id] = {
                    totalAmount: 0,
                    totalWaterConsumption: 0,
                    count: 0
                };
            }
            const amount = usage.amount ? parseFloat(usage.amount) : 0;
            const waterConsumption = usage.water_consumption ? parseFloat(usage.water_consumption) : 0;
            devices[usage.device_id].totalAmount += amount;
            devices[usage.device_id].totalWaterConsumption += waterConsumption;
            devices[usage.device_id].count++;
        });

        // Crear tabla con los resultados
        let tableHTML = '<table class="table table-bordered"><thead class="table-dark"><tr><th>Dispositivo</th><th>Total (ARS)</th><th>Total Agua (Litros)</th><th>Número de Usos</th></tr></thead><tbody>';

        for (const deviceId in devices) {
            const device = devices[deviceId];
            tableHTML += `
                <tr>
                    <td>${deviceId}</td>
                    <td>${device.totalAmount.toFixed(2)}</td>
                    <td>${device.totalWaterConsumption.toFixed(2)}</td>
                    <td>${device.count}</td>
                </tr>
            `;
        }

        tableHTML += '</tbody></table>';
        sumResult.innerHTML += tableHTML;
    })
    .catch(error => {
        if (error.response && error.response.status === 401) {
            localStorage.removeItem('showerAdminToken');
            showErrorMessage('Tu sesión ha expirado. Por favor, inicia sesión nuevamente.');
            document.getElementById('adminContent').style.display = 'none';
            document.getElementById('usageContent').style.display = 'none';
        } else {
            showMessage('Error al obtener el historial de uso: ' + (error.response?.data?.message || error.message), true);
        }
    });
});

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