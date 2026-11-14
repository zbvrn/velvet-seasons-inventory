-- EIMS: initial schema for MariaDB 10.6+ (tested version recorded in README).
-- Run ONCE against a NEW database. No DROP, no demo data, no passwords.
-- Table names intentionally fail on re-run instead of silently masking drift.
SET NAMES utf8mb4;
SET SESSION time_zone = '+00:00';
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ZERO_DATE,NO_ZERO_IN_DATE,NO_ENGINE_SUBSTITUTION';

CREATE DATABASE IF NOT EXISTS velvet_inventory
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE velvet_inventory;

CREATE TABLE department (
  id BIGINT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  is_active TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_department_name (name),
  CONSTRAINT ck_department_name CHECK (CHAR_LENGTH(TRIM(name)) > 0),
  CONSTRAINT ck_department_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE job_position (
  id BIGINT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  is_active TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_job_position_name (name),
  CONSTRAINT ck_job_position_name CHECK (CHAR_LENGTH(TRIM(name)) > 0),
  CONSTRAINT ck_job_position_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE employee (
  id BIGINT NOT NULL AUTO_INCREMENT,
  full_name VARCHAR(255) NOT NULL,
  staff_number VARCHAR(100) NULL,
  is_active TINYINT NOT NULL DEFAULT 1,
  department_id BIGINT NULL,
  job_position_id BIGINT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_employee_staff_number (staff_number),
  KEY ix_employee_department (department_id),
  KEY ix_employee_job_position (job_position_id),
  CONSTRAINT fk_employee_department FOREIGN KEY (department_id)
    REFERENCES department (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_employee_job_position FOREIGN KEY (job_position_id)
    REFERENCES job_position (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT ck_employee_name CHECK (CHAR_LENGTH(TRIM(full_name)) > 0),
  CONSTRAINT ck_employee_staff_number CHECK (staff_number IS NULL OR CHAR_LENGTH(TRIM(staff_number)) > 0),
  CONSTRAINT ck_employee_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE manufacturer (
  id BIGINT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  is_active TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_manufacturer_name (name),
  CONSTRAINT ck_manufacturer_name CHECK (CHAR_LENGTH(TRIM(name)) > 0),
  CONSTRAINT ck_manufacturer_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE equipment_type (
  id BIGINT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  description TEXT NULL,
  is_active TINYINT NOT NULL DEFAULT 1,
  parent_id BIGINT NULL,
  PRIMARY KEY (id),
  KEY ix_equipment_type_parent (parent_id),
  CONSTRAINT fk_equipment_type_parent FOREIGN KEY (parent_id)
    REFERENCES equipment_type (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT ck_equipment_type_name CHECK (CHAR_LENGTH(TRIM(name)) > 0),
  CONSTRAINT ck_equipment_type_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE equipment_model (
  id BIGINT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  is_active TINYINT NOT NULL DEFAULT 1,
  equipment_type_id BIGINT NOT NULL,
  manufacturer_id BIGINT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_equipment_model_id_type (id, equipment_type_id),
  KEY ix_equipment_model_type (equipment_type_id),
  KEY ix_equipment_model_manufacturer (manufacturer_id),
  CONSTRAINT fk_equipment_model_type FOREIGN KEY (equipment_type_id)
    REFERENCES equipment_type (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_equipment_model_manufacturer FOREIGN KEY (manufacturer_id)
    REFERENCES manufacturer (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT ck_equipment_model_name CHECK (CHAR_LENGTH(TRIM(name)) > 0),
  CONSTRAINT ck_equipment_model_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE location_type (
  id BIGINT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  is_active TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_location_type_name (name),
  CONSTRAINT ck_location_type_name CHECK (CHAR_LENGTH(TRIM(name)) > 0),
  CONSTRAINT ck_location_type_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE location (
  id BIGINT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  is_active TINYINT NOT NULL DEFAULT 1,
  location_type_id BIGINT NOT NULL,
  parent_id BIGINT NULL,
  PRIMARY KEY (id),
  KEY ix_location_type (location_type_id),
  KEY ix_location_parent (parent_id),
  CONSTRAINT fk_location_type FOREIGN KEY (location_type_id)
    REFERENCES location_type (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_location_parent FOREIGN KEY (parent_id)
    REFERENCES location (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT ck_location_name CHECK (CHAR_LENGTH(TRIM(name)) > 0),
  CONSTRAINT ck_location_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE equipment (
  id BIGINT NOT NULL AUTO_INCREMENT,
  inventory_number VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  actual_name VARCHAR(255) NOT NULL,
  accounting_name TEXT NULL,
  serial_number VARCHAR(255) NULL,
  technical_condition VARCHAR(20) NOT NULL DEFAULT 'unknown',
  usage_status VARCHAR(20) NULL,
  defect_description TEXT NULL,
  notes TEXT NULL,
  equipment_type_id BIGINT NOT NULL,
  model_id BIGINT NULL,
  manufacturer_id BIGINT NULL,
  location_id BIGINT NULL,
  assigned_employee_id BIGINT NULL,
  assigned_location_id BIGINT NULL,
  mol_employee_id BIGINT NULL,
  source_actualized_on DATE NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  row_version BIGINT NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_equipment_inventory_number (inventory_number),
  KEY ix_equipment_type (equipment_type_id),
  KEY ix_equipment_model_type (model_id, equipment_type_id),
  KEY ix_equipment_manufacturer (manufacturer_id),
  KEY ix_equipment_location (location_id),
  KEY ix_equipment_assigned_employee (assigned_employee_id),
  KEY ix_equipment_assigned_location (assigned_location_id),
  KEY ix_equipment_mol_employee (mol_employee_id),
  CONSTRAINT fk_equipment_type FOREIGN KEY (equipment_type_id)
    REFERENCES equipment_type (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  -- Composite FK also guarantees that the model belongs to the asset's type.
  CONSTRAINT fk_equipment_model FOREIGN KEY (model_id, equipment_type_id)
    REFERENCES equipment_model (id, equipment_type_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_equipment_manufacturer FOREIGN KEY (manufacturer_id)
    REFERENCES manufacturer (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_equipment_location FOREIGN KEY (location_id)
    REFERENCES location (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_equipment_assigned_employee FOREIGN KEY (assigned_employee_id)
    REFERENCES employee (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_equipment_assigned_location FOREIGN KEY (assigned_location_id)
    REFERENCES location (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_equipment_mol_employee FOREIGN KEY (mol_employee_id)
    REFERENCES employee (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT ck_equipment_inventory_number CHECK (CHAR_LENGTH(TRIM(inventory_number)) > 0
    AND OCTET_LENGTH(inventory_number) = OCTET_LENGTH(TRIM(inventory_number))),
  CONSTRAINT ck_equipment_actual_name CHECK (CHAR_LENGTH(TRIM(actual_name)) > 0),
  CONSTRAINT ck_equipment_technical_condition CHECK (technical_condition IN ('unknown', 'working', 'faulty')),
  CONSTRAINT ck_equipment_usage_status CHECK (usage_status IS NULL OR usage_status IN ('in_use', 'reserve', 'repair', 'retired')),
  CONSTRAINT ck_equipment_assigned_user CHECK (assigned_employee_id IS NULL OR assigned_location_id IS NULL),
  CONSTRAINT ck_equipment_row_version CHECK (row_version > 0)
) ENGINE=InnoDB;

CREATE TABLE component_installation (
  id BIGINT NOT NULL AUTO_INCREMENT,
  installed_on DATE NULL,
  removed_on DATE NULL,
  is_current TINYINT NOT NULL DEFAULT 1,
  recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  component_role VARCHAR(255) NULL,
  notes TEXT NULL,
  parent_equipment_id BIGINT NOT NULL,
  component_equipment_id BIGINT NOT NULL,
  -- MariaDB equivalent of a partial unique index: NULL for closed records.
  -- Technical extra column compared with the hand-drawn diagram; never fill it manually.
  active_component_id BIGINT GENERATED ALWAYS AS
    (CASE WHEN is_current = 1 THEN component_equipment_id ELSE NULL END) PERSISTENT,
  PRIMARY KEY (id),
  KEY ix_component_installation_parent (parent_equipment_id),
  KEY ix_component_installation_component (component_equipment_id),
  UNIQUE KEY uq_component_installation_active (active_component_id),
  CONSTRAINT fk_component_installation_parent FOREIGN KEY (parent_equipment_id)
    REFERENCES equipment (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_component_installation_component FOREIGN KEY (component_equipment_id)
    REFERENCES equipment (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT ck_component_installation_distinct CHECK (parent_equipment_id <> component_equipment_id),
  CONSTRAINT ck_component_installation_current CHECK (is_current IN (0, 1)),
  CONSTRAINT ck_component_installation_removed CHECK (is_current = 0 OR removed_on IS NULL),
  CONSTRAINT ck_component_installation_dates CHECK (installed_on IS NULL OR removed_on IS NULL OR removed_on >= installed_on)
) ENGINE=InnoDB;

CREATE TABLE user_account (
  id BIGINT NOT NULL AUTO_INCREMENT,
  login VARCHAR(100) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role_code VARCHAR(20) NOT NULL,
  is_active TINYINT NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  employee_id BIGINT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_user_account_login (login),
  UNIQUE KEY uq_user_account_employee (employee_id),
  CONSTRAINT fk_user_account_employee FOREIGN KEY (employee_id)
    REFERENCES employee (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT ck_user_account_login CHECK (CHAR_LENGTH(TRIM(login)) > 0),
  CONSTRAINT ck_user_account_password_hash CHECK (CHAR_LENGTH(TRIM(password_hash)) > 0),
  CONSTRAINT ck_user_account_role CHECK (role_code IN ('it_staff', 'management')),
  CONSTRAINT ck_user_account_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE equipment_event (
  id BIGINT NOT NULL AUTO_INCREMENT,
  event_type VARCHAR(30) NOT NULL,
  source_kind VARCHAR(20) NOT NULL,
  occurred_at DATETIME NULL,
  occurred_on DATE NULL,
  recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reason TEXT NULL,
  equipment_id BIGINT NOT NULL,
  actor_account_id BIGINT NULL,
  before_data LONGTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT '{}',
  after_data LONGTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT '{}',
  operation_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NULL,
  PRIMARY KEY (id),
  KEY ix_equipment_event_equipment_time (equipment_id, recorded_at, id),
  KEY ix_equipment_event_actor (actor_account_id),
  KEY ix_equipment_event_operation (operation_id),
  CONSTRAINT fk_equipment_event_equipment FOREIGN KEY (equipment_id)
    REFERENCES equipment (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_equipment_event_actor FOREIGN KEY (actor_account_id)
    REFERENCES user_account (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT ck_equipment_event_type CHECK (event_type IN
    ('create', 'update', 'move', 'assign_user', 'change_mol', 'state_change', 'install', 'remove', 'import', 'retire')),
  CONSTRAINT ck_equipment_event_source CHECK (source_kind IN ('manual', 'import', 'system')),
  CONSTRAINT ck_equipment_event_actor CHECK (source_kind <> 'manual' OR actor_account_id IS NOT NULL),
  CONSTRAINT ck_equipment_event_dates CHECK (occurred_at IS NULL OR occurred_on IS NULL),
  CONSTRAINT ck_equipment_event_before CHECK (JSON_VALID(before_data) AND JSON_TYPE(before_data) = 'OBJECT'),
  CONSTRAINT ck_equipment_event_after CHECK (JSON_VALID(after_data) AND JSON_TYPE(after_data) = 'OBJECT')
) ENGINE=InnoDB;

SELECT 'EIMS schema created: 12 tables' AS result;
SHOW TABLES;
