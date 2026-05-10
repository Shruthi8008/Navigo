CREATE TABLE IF NOT EXISTS place_safety_ratings (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    place_name VARCHAR(255) NOT NULL,
    address VARCHAR(500) NOT NULL,
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    rating_value TINYINT UNSIGNED NOT NULL,
    comment TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_place_safety_ratings_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE,
    INDEX idx_place_safety_location (latitude, longitude),
    INDEX idx_place_safety_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS road_segment_ratings (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    segment_key VARCHAR(120) NOT NULL,
    start_latitude DECIMAL(10, 7) NOT NULL,
    start_longitude DECIMAL(10, 7) NOT NULL,
    end_latitude DECIMAL(10, 7) NOT NULL,
    end_longitude DECIMAL(10, 7) NOT NULL,
    rating_value TINYINT UNSIGNED NOT NULL,
    comment TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_road_segment_ratings_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE,
    INDEX idx_road_segment_key (segment_key),
    INDEX idx_road_segment_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS road_segment_safety_scores (
    segment_key VARCHAR(120) NOT NULL PRIMARY KEY,
    start_latitude DECIMAL(10, 7) NOT NULL,
    start_longitude DECIMAL(10, 7) NOT NULL,
    end_latitude DECIMAL(10, 7) NOT NULL,
    end_longitude DECIMAL(10, 7) NOT NULL,
    normalized_score DECIMAL(5, 4) NOT NULL,
    rating_count INT UNSIGNED NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS favorite_places (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    place_name VARCHAR(255) NOT NULL,
    address VARCHAR(500) NOT NULL,
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_favorite_places_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE,
    UNIQUE KEY uq_favorite_place_user_location (user_id, latitude, longitude),
    INDEX idx_favorite_places_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS safety_comments (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    target_type VARCHAR(20) NOT NULL,
    target_key VARCHAR(191) NOT NULL,
    place_name VARCHAR(255) NULL,
    address VARCHAR(500) NULL,
    latitude DECIMAL(10, 7) NULL,
    longitude DECIMAL(10, 7) NULL,
    comment TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_safety_comments_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE,
    INDEX idx_safety_comments_target (target_type, target_key),
    INDEX idx_safety_comments_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
