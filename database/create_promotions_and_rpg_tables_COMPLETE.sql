-- 1. Asegurar que users tenga xp_points y level. Usamos ALTER IGNORE o simplemente lo ponemos
-- Si ya corriste esta parte, puedes omitir estas 2 líneas:
-- ALTER TABLE `users` ADD COLUMN `xp_points` INT NOT NULL DEFAULT 0 AFTER `email`;
-- ALTER TABLE `users` ADD COLUMN `level` INT NOT NULL DEFAULT 1 AFTER `xp_points`;

-- 2. Eliminar tablas si existen para crearlas limpias con la nueva estructura
DROP TABLE IF EXISTS `vouchers`;
DROP TABLE IF EXISTS `promotions`;

-- 3. Crear tabla de Promociones (con product_id y max_total_claims incluidos desde cero)
CREATE TABLE `promotions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` BIGINT UNSIGNED NOT NULL,
  `product_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT NULL DEFAULT NULL,
  `required_level` INT NOT NULL DEFAULT 1,
  `max_uses_per_user` INT NOT NULL DEFAULT 1,
  `max_total_claims` INT NULL DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `expires_at` DATETIME NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_promo_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_promo_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- 4. Crear tabla de Vouchers
CREATE TABLE `vouchers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `promotion_id` BIGINT UNSIGNED NOT NULL,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `code` VARCHAR(20) NOT NULL,
  `status` VARCHAR(50) NOT NULL DEFAULT 'claimed',
  `redeemed_at` DATETIME NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `vouchers_code_unique` (`code`),
  CONSTRAINT `fk_voucher_promo` FOREIGN KEY (`promotion_id`) REFERENCES `promotions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_voucher_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
