-- SCRIPT SEEDER DINÁMICO v3
-- Adaptado EXACTAMENTE a las columnas disponibles verificadas en tu modelo (sin calls a "status" o "starts_at")
-- =================================================

-- TIENDA 1: TECH
INSERT INTO `users` (`name`, `email`, `password`, `created_at`, `updated_at`) VALUES 
('Alex (Tech Store)', 'tech_v3@premium.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NOW(), NOW());
SET @user1 = LAST_INSERT_ID();

INSERT INTO `subscriptions` (`user_id`, `type`, `product_limit`, `is_active`, `created_at`, `updated_at`) VALUES 
(@user1, 'premium', 1000, 1, NOW(), NOW());

INSERT INTO `businesses` (`user_id`, `name`, `description`, `phone`, `email`, `is_active`, `created_at`, `updated_at`) VALUES 
(@user1, 'ChiviTech Pro', 'Venta de gadgets y accesorios de última generación', '123456001', 'ventas_v3@chivitech.com', 1, NOW(), NOW());
SET @biz1 = LAST_INSERT_ID();

INSERT INTO `products` (`business_id`, `name`, `description`, `price`, `stock`, `category_id`, `is_active`, `created_at`, `updated_at`) VALUES 
(@biz1, 'Auriculares Inalámbricos X2', 'Auriculares con reducción de ruido activa y 24h de batería.', 59.99, 10, 1, 1, NOW(), NOW()),
(@biz1, 'Smartwatch Pro Fit', 'Reloj inteligente con monitor de ritmo cardíaco.', 129.99, 5, 1, 1, NOW(), NOW());

-- TIENDA 2: MODA 
INSERT INTO `users` (`name`, `email`, `password`, `created_at`, `updated_at`) VALUES 
('Carla (Moda Urbana)', 'moda_v3@premium.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NOW(), NOW());
SET @user2 = LAST_INSERT_ID();

INSERT INTO `subscriptions` (`user_id`, `type`, `product_limit`, `is_active`, `created_at`, `updated_at`) VALUES 
(@user2, 'premium', 1000, 1, NOW(), NOW());

INSERT INTO `businesses` (`user_id`, `name`, `description`, `phone`, `email`, `is_active`, `created_at`, `updated_at`) VALUES 
(@user2, 'Boutique Urbana', 'Ropa y moda urbana para el público joven.', '123456002', 'hola_v3@boutique.com', 1, NOW(), NOW());
SET @biz2 = LAST_INSERT_ID();

INSERT INTO `products` (`business_id`, `name`, `description`, `price`, `stock`, `category_id`, `is_active`, `created_at`, `updated_at`) VALUES 
(@biz2, 'Chaqueta de Cuero Vintage', 'Chaqueta estilo clásico para hombre.', 89.50, 4, 1, 1, NOW(), NOW()),
(@biz2, 'Zapatillas Running Pro', 'Zapatillas de alto rendimiento.', 65.00, 15, 1, 1, NOW(), NOW());

-- TIENDA 3: COMIDA
INSERT INTO `users` (`name`, `email`, `password`, `created_at`, `updated_at`) VALUES 
('Mario (Gourmet)', 'comida_v3@premium.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NOW(), NOW());
SET @user3 = LAST_INSERT_ID();

INSERT INTO `subscriptions` (`user_id`, `type`, `product_limit`, `is_active`, `created_at`, `updated_at`) VALUES 
(@user3, 'premium', 1000, 1, NOW(), NOW());

INSERT INTO `businesses` (`user_id`, `name`, `description`, `phone`, `email`, `is_active`, `created_at`, `updated_at`) VALUES 
(@user3, 'Restaurante El Valle', 'Platillos excepcionales con recetas únicas.', '123456003', 'reservas_v3@elvalle.com', 1, NOW(), NOW());
SET @biz3 = LAST_INSERT_ID();

INSERT INTO `products` (`business_id`, `name`, `description`, `price`, `stock`, `category_id`, `is_active`, `created_at`, `updated_at`) VALUES 
(@biz3, 'Hamburguesa Doble Cheddar', 'Hamburguesa con doble carne.', 12.50, 50, 1, 1, NOW(), NOW()),
(@biz3, 'Pizzeta Margarita', 'Masa madre horneada a la piedra.', 18.00, 20, 1, 1, NOW(), NOW());

-- TIENDA 4: SERVICIOS
INSERT INTO `users` (`name`, `email`, `password`, `created_at`, `updated_at`) VALUES 
('Luis (Servicios)', 'servicios_v3@premium.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NOW(), NOW());
SET @user4 = LAST_INSERT_ID();

INSERT INTO `subscriptions` (`user_id`, `type`, `product_limit`, `is_active`, `created_at`, `updated_at`) VALUES 
(@user4, 'premium', 1000, 1, NOW(), NOW());

INSERT INTO `businesses` (`user_id`, `name`, `description`, `phone`, `email`, `is_active`, `created_at`, `updated_at`) VALUES 
(@user4, 'Reparaciones Express', 'Plomería, electricidad y limpieza.', '123456004', 'urgencias_v3@reparaciones.com', 1, NOW(), NOW());
SET @biz4 = LAST_INSERT_ID();

INSERT INTO `products` (`business_id`, `name`, `description`, `price`, `stock`, `category_id`, `is_active`, `created_at`, `updated_at`) VALUES 
(@biz4, 'Visita Eléctrica Básica', 'Revisión y solución de problemas.', 25.00, 100, 1, 1, NOW(), NOW()),
(@biz4, 'Emergencia Plomería', 'Atención nocturna o de urgencias.', 40.00, 100, 1, 1, NOW(), NOW());
