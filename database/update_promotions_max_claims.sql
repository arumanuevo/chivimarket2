ALTER TABLE `promotions`
ADD COLUMN `max_total_claims` INT NULL DEFAULT NULL COMMENT 'Si es nulo, la promo es ilimitada para el negocio' AFTER `max_uses_per_user`;
