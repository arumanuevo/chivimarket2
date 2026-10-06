-- ==============================================================================
-- SISTEMA O2O (Online-To-Offline) + RPG GAMIFICATION
-- Este script expande la BD existente añadiendo Promociones, Vouchers y 
-- el sistema de Niveles y Experiencia para los Compradores (Usuarios).
-- ==============================================================================

-- 1. Añadir el motor RPG a los usuarios (Compradores)
ALTER TABLE `users`
ADD COLUMN `xp_points` INT NOT NULL DEFAULT 0 AFTER `email`,
ADD COLUMN `level` INT NOT NULL DEFAULT 1 AFTER `xp_points`;

-- 2. Crear tabla de Promociones (El negocio crea las ofertas)
CREATE TABLE IF NOT EXISTS `promotions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` BIGINT UNSIGNED NOT NULL,
  `title` VARCHAR(255) NOT NULL COMMENT 'Ej: 2x1 en Pintas, 20% OFF',
  `description` TEXT COMMENT 'Detalles de cómo o cuándo usar el beneficio',
  `required_level` INT NOT NULL DEFAULT 1 COMMENT 'Nivel mínimo RPG que necesita el usuario para ver/reclamar esta promo',
  `max_uses_per_user` INT NOT NULL DEFAULT 1 COMMENT 'Cuántas veces puede un mismo usuario canjear esto',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `expires_at` DATETIME NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Crear tabla de Vouchers (El código ABCD-1234 que el comprador lleva al local)
CREATE TABLE IF NOT EXISTS `vouchers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `promotion_id` BIGINT UNSIGNED NOT NULL,
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'El comprador que reclamó el código',
  `code` VARCHAR(20) NOT NULL COMMENT 'Código único a presentar, ej: XF9-LK2A',
  `status` ENUM('claimed', 'redeemed', 'expired') NOT NULL DEFAULT 'claimed' COMMENT 'Estado del voucher',
  `redeemed_at` DATETIME NULL DEFAULT NULL COMMENT 'Fecha y hora en que el negocio le dio "Validar" en la app',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `vouchers_code_unique` (`code`),
  FOREIGN KEY (`promotion_id`) REFERENCES `promotions` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
