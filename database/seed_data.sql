-- Fake data generation for Chivimarket Businesses and Categories
-- Compatible with SQLite/MySQL

-- 1. Insert Categories
INSERT INTO business_categories (name, description, created_at, updated_at) VALUES 
('Gastronomía', 'Restaurantes, bares, rotiserías', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Indumentaria', 'Ropa, calzado y accesorios', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Servicios', 'Peluquerías, mecánicos, plomeros', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Tecnología', 'Venta de electrónicos y reparaciones', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Salud', 'Farmacias y consultorios', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 2. Insert Users (assuming basic Admin or dummy users, change user_id as needed)
-- INSERT INTO users (name, email, password) VALUES ('Admin', 'admin@chivimarket.com', '...hash...');

-- 3. Insert Fake Businesses (Make sure user_id=1 exists in your DB, replace 1 with your actual user_id)
INSERT INTO businesses (user_id, name, description, address, latitude, longitude, phone, is_active, created_at, updated_at) VALUES
(1, 'La Parrilla de Don Julio', 'La mejor carne asada de Chivilcoy con ambiente familiar.', 'Av. Soarez 150', -34.8950, -60.0167, '2346-555123', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'Tienda de Ropa Urbana', 'Indumentaria moderna para jóvenes de todas las edades.', 'Calle Pellegrini 45', -34.8965, -60.0190, '2346-555456', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'TechFix Soluciones', 'Reparación de celulares y venta de fundas y accesorios.', 'Av. Villarino 300', -34.8942, -60.0155, '2346-555789', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'Farmacia Centro', 'Abierto las 24hs, perfumería y medicamentos.', 'Calle San Martín 102', -34.8970, -60.0180, '2346-555000', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'Peluquería Estilo', 'Cortes de moda y barbería clásica.', 'Av. Ceballos 210', -34.8935, -60.0142, '2346-555222', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 4. Associate Businesses with Categories (business_id to category_id)
INSERT INTO business_category (business_id, category_id) VALUES
(1, 1), -- Parrilla -> Gastronomía
(2, 2), -- Ropa -> Indumentaria
(3, 4), -- TechFix -> Tecnología
(4, 5), -- Farmacia -> Salud
(5, 3); -- Peluquería -> Servicios
