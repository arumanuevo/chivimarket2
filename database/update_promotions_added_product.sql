ALTER TABLE `promotions`
ADD COLUMN `product_id` BIGINT UNSIGNED NULL DEFAULT NULL AFTER `business_id`,
ADD CONSTRAINT `promotions_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;
