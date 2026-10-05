CREATE TABLE IF NOT EXISTS `cb_backpacks` (
    `owner` VARCHAR(100) NOT NULL,
    `item_name` VARCHAR(50) NOT NULL,
    `backpack_id` VARCHAR(120) NOT NULL,
    `component_id` TINYINT UNSIGNED NOT NULL DEFAULT 5,
    `base_drawable` SMALLINT NOT NULL DEFAULT 0,
    `base_texture` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`owner`),
    UNIQUE KEY `cb_backpacks_backpack_id` (`backpack_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;