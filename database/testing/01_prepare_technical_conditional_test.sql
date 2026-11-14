-- Подготовка отдельной базы для теста чтения справочника.
-- Выполнить один раз через административное соединение.
-- Основная база velvet_inventory не изменяется.

CREATE DATABASE velvet_inventory_test
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE TABLE velvet_inventory_test.technical_condition (
  id BIGINT NOT NULL AUTO_INCREMENT,
  code VARCHAR(20) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  name VARCHAR(255) NOT NULL,
  is_active TINYINT NOT NULL DEFAULT 1,

  PRIMARY KEY (id),
  UNIQUE KEY uq_technical_condition_code (code),
  UNIQUE KEY uq_technical_condition_name (name),

  CONSTRAINT ck_technical_condition_code
    CHECK (CHAR_LENGTH(TRIM(code)) > 0),
  CONSTRAINT ck_technical_condition_name
    CHECK (CHAR_LENGTH(TRIM(name)) > 0),
  CONSTRAINT ck_technical_condition_active
    CHECK (is_active IN (0, 1))
) ENGINE=InnoDB;

INSERT INTO velvet_inventory_test.technical_condition
  (id, code, name, is_active)
VALUES
  (3, 'faulty', 'Неисправно', 1),
  (1, 'unknown', 'Неизвестно', 1),
  (2, 'working', 'Исправно', 1);

GRANT SELECT ON velvet_inventory_test.*
TO 'velvet_app'@'127.0.0.1';