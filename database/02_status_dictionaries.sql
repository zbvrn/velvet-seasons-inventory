-- EIMS migration 002. MariaDB 10.6+. Run once after 01_create_schema.sql.
-- Does not recreate the database or delete equipment/history.
-- Take a database backup first. DDL is not a single rollbackable transaction.
SET NAMES utf8mb4;
SET SESSION time_zone = '+00:00';
USE velvet_inventory;

CREATE TABLE technical_condition (
  id BIGINT NOT NULL AUTO_INCREMENT,
  code VARCHAR(20) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  name VARCHAR(255) NOT NULL,
  is_active TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_technical_condition_code (code),
  UNIQUE KEY uq_technical_condition_name (name),
  CONSTRAINT ck_technical_condition_code CHECK (CHAR_LENGTH(TRIM(code)) > 0),
  CONSTRAINT ck_technical_condition_name CHECK (CHAR_LENGTH(TRIM(name)) > 0),
  CONSTRAINT ck_technical_condition_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE usage_status (
  id BIGINT NOT NULL AUTO_INCREMENT,
  code VARCHAR(20) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  name VARCHAR(255) NOT NULL,
  is_active TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_usage_status_code (code),
  UNIQUE KEY uq_usage_status_name (name),
  CONSTRAINT ck_usage_status_code CHECK (CHAR_LENGTH(TRIM(code)) > 0),
  CONSTRAINT ck_usage_status_name CHECK (CHAR_LENGTH(TRIM(name)) > 0),
  CONSTRAINT ck_usage_status_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO technical_condition (id, code, name) VALUES
  (1, 'unknown', 'Неизвестно'),
  (2, 'working', 'Исправно'),
  (3, 'faulty', 'Неисправно');

INSERT INTO usage_status (id, code, name) VALUES
  (1, 'in_use', 'Используется'),
  (2, 'reserve', 'В резерве'),
  (3, 'repair', 'В ремонте'),
  (4, 'retired', 'Выведено из эксплуатации');

ALTER TABLE equipment
  ADD COLUMN technical_condition_id BIGINT NULL AFTER technical_condition,
  ADD COLUMN usage_status_id BIGINT NULL AFTER usage_status;

UPDATE equipment e
JOIN technical_condition tc ON tc.code = e.technical_condition
LEFT JOIN usage_status us ON us.code = e.usage_status
SET e.technical_condition_id = tc.id, e.usage_status_id = us.id;

-- Stop before dropping old columns if an existing value could not be mapped.
DELIMITER //
CREATE PROCEDURE eims_assert_status_mapping_002()
BEGIN
  IF EXISTS (
    SELECT 1 FROM equipment e
    LEFT JOIN technical_condition tc ON tc.id = e.technical_condition_id
    LEFT JOIN usage_status us ON us.id = e.usage_status_id
    WHERE tc.id IS NULL
       OR BINARY tc.code <> BINARY e.technical_condition
       OR (e.usage_status IS NOT NULL AND (us.id IS NULL OR BINARY us.code <> BINARY e.usage_status))
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Status mapping failed. Old columns retained; inspect equipment before continuing.';
  END IF;
END//
DELIMITER ;
CALL eims_assert_status_mapping_002();
DROP PROCEDURE eims_assert_status_mapping_002;

ALTER TABLE equipment
  DROP CONSTRAINT ck_equipment_technical_condition,
  DROP CONSTRAINT ck_equipment_usage_status,
  DROP COLUMN technical_condition,
  DROP COLUMN usage_status,
  MODIFY COLUMN technical_condition_id BIGINT NOT NULL DEFAULT 1,
  ADD KEY ix_equipment_technical_condition (technical_condition_id),
  ADD KEY ix_equipment_usage_status (usage_status_id),
  ADD CONSTRAINT fk_equipment_technical_condition FOREIGN KEY (technical_condition_id)
    REFERENCES technical_condition (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  ADD CONSTRAINT fk_equipment_usage_status FOREIGN KEY (usage_status_id)
    REFERENCES usage_status (id) ON UPDATE RESTRICT ON DELETE RESTRICT;

-- Historical JSON snapshots keep their original schema and values.
SELECT 'Migration 002 applied: 14 tables; equipment status dictionaries linked' AS result;
SELECT * FROM technical_condition ORDER BY id;
SELECT * FROM usage_status ORDER BY id;
SELECT COUNT(*) AS equipment_count FROM equipment;
