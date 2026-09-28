# 📖 REGLAS DE ORO Y ARQUITECTURA CORE: CHIVIMARKET

Este documento sirve como el **Prompt de Contexto Maestro** para que cualquier Inteligencia Artificial o desarrollador entienda exactamente cuál es la filosofía, abstracción y estructura de negocio de la plataforma ChiviMarket.

## 1. Filosofía Comercial ("Equilibrio Justo")
- **Monetización no invasiva ("No pesetera"):** La plataforma debe generar dinero aportando un valor real. Las búsquedas de comercios son gratuitas y preferentemente sin obligación estricta de Login para clientes finales, atrayendo tráfico masivo.
- **Dinamismo Promocional:** Existe una lógica de `DiscountTokens` para que los Vendedores ofrezcan cupones a clientes. Esto funge como gancho para ambas partes: El comercio vende más, el cliente entra a la app a cazar ofertas.
- **Posicionamiento Premium:** Se puede monetizar escalando posiciones en la búsqueda (Prioridades/Score), pero esto se aplica sin ensuciar fuertemente la UI, premiando a quienes pagan una Suscripción Pro o compran "boosts".

## 2. Abstracción y Modelo de Base de Datos
- **1 Usuario -> Muchos Comercios (1:N):** Un `User` (Dueño/Admin humano) no es un negocio. Después de registrarse, según su `Subscription`, puede dar de alta múltiples `Business` (Ej: Puede ser dueño de una Parrilla y también de un Taller).
- **Tablas/Modelos Clave Ya Existentes:**
  - `Subscription.php` gestiona el poder del usuario (`product_limit`, expiración, etc).
  - `DiscountToken.php` administra códigos promocionales asociados a negocios/usuarios.
  - `TokenUse.php` lleva reporte estadístico de uso de promociones.
- **Flexibilidad de Rubros:** Como ChiviMarket abarca Servicios de Cuidado, Delivery, Ferreterías y Consultas Online, la base de datos debe ser tratada como **Elástica**. Se recomienda empaquetar rasgos particulares (Ej: Turnos online, 24hrs) en campos estilo JSON (`metadata`), acompañando ubicaciones optativas (`modality` físico/online). 

## 3. Limitaciones del Servidor Activo (Wiroos)
- **Prohibido realizar Migraciones de Laravel Automáticas:** Todo "Alter Table" o Creación de Tablas debe ser entregado al creador estrictamente como **Comandos SQL Puros** para que lo ejecute en su PhpMyAdmin.
- **Prohibido usar `symlink()`:** El servidor Wiroos deshabilita esta función. Las rutas de imágenes y archivos deben dirigirse directamente a la carpeta `public` o escribirse físicamente en los directorios externos visibles (Configuración actual de `filesystems.php`).

## 4. Estética de la Aplicación (Flutter)
- El frontend persigue la excelencia visual mediante **Glassmorphism**, tonalidades *"Naranja Sobrio" (Primary: F97316)*, gradientes elegantes y tipografía de interfaz moderna (Inter/Outfit).
- Debe parecer una plataforma Premium, evitando elementos de diseño desactualizados o "planos" genéricos de Bootstrap/Material básico.

---
**🤖 INSTRUCCIÓN PARA LA IA DEL FUTURO:** Lee este archivo completamente antes de proceder a modificar cualquier controlador de creación comercial, edición de negocios o recomendación de pagos.
