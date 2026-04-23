<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - Administración de Duchas</title>
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
    </style>
</head>
<body class="bg-light">
    <div class="container py-5">
        <div class="row justify-content-center">
            <div class="col-12 col-md-6 col-lg-4">
                <div class="card p-4">
                    <h2 class="mb-4 text-center">Login - Administración de Duchas</h2>
                    <form id="loginForm">
                        <div class="mb-3">
                            <label for="email" class="form-label">Email</label>
                            <input type="email" class="form-control" id="email" required>
                        </div>
                        <div class="mb-3">
                            <label for="password" class="form-label">Contraseña</label>
                            <input type="password" class="form-control" id="password" required>
                        </div>
                        <button type="submit" class="btn btn-primary w-100">Iniciar Sesión</button>
                    </form>
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

            // Manejar el login
            document.getElementById('loginForm').addEventListener('submit', function(e) {
                e.preventDefault();

                const email = document.getElementById('email').value;
                const password = document.getElementById('password').value;

                axios.post('/api/shower-admin/login', {
                    email: email,
                    password: password
                })
                .then(response => {
                    localStorage.setItem('showerAdminToken', response.data.token);
                    window.location.href = '/shower-admin';
                })
                .catch(error => {
                    let message = 'Error al iniciar sesión: ';
                    if (error.response && error.response.data && error.response.data.message) {
                        message += error.response.data.message;
                    } else {
                        message += error.message;
                    }
                    showMessage(message, true);
                });
            });
        });
    </script>
</body>
</html>