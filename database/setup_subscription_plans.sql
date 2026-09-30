CREATE TABLE IF NOT EXISTS subscription_plans (
    id INT AUTO_INCREMENT PRIMARY KEY,
    plan_name VARCHAR(50) NOT NULL UNIQUE,
    max_businesses INT NOT NULL DEFAULT 1,
    max_products INT NOT NULL DEFAULT 10,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);

INSERT INTO subscription_plans (plan_name, max_businesses, max_products) VALUES
('free', 1, 10),
('basic', 5, 100),
('premium', 10, 500),
('enterprise', 20, 1000)
ON DUPLICATE KEY UPDATE 
max_businesses = VALUES(max_businesses), max_products = VALUES(max_products);
