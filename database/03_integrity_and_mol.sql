-- EIMS migration 003. Run ONCE after 002; MariaDB 10.6+.
-- No database recreation. Keep a backup before DDL.
-- Structural changes use the three procedures below for concurrency-safe cycle checks.
SET NAMES utf8mb4;
SET SESSION time_zone = '+00:00';
USE velvet_inventory;

INSERT INTO usage_status(id,code,name,is_active) VALUES(5,'unknown','Неизвестно',1);
UPDATE equipment SET usage_status_id=5 WHERE usage_status_id IS NULL;
ALTER TABLE equipment MODIFY usage_status_id BIGINT NOT NULL DEFAULT 5;
ALTER TABLE employee ADD is_mol TINYINT NOT NULL DEFAULT 0 AFTER is_active,
 ADD CONSTRAINT ck_employee_mol CHECK(is_mol IN(0,1)),
 ADD CONSTRAINT ck_employee_mol_active CHECK(is_mol=0 OR is_active=1);

-- Scope 0 is reserved for a missing parent/manufacturer, never a real FK.
ALTER TABLE equipment_type
 ADD parent_scope_id BIGINT GENERATED ALWAYS AS(COALESCE(parent_id,0)) PERSISTENT,
 ADD CONSTRAINT ck_equipment_type_parent_positive CHECK(parent_id IS NULL OR parent_id>0),
 ADD UNIQUE KEY uq_equipment_type_sibling(parent_scope_id,name);
ALTER TABLE location
 ADD parent_scope_id BIGINT GENERATED ALWAYS AS(COALESCE(parent_id,0)) PERSISTENT,
 ADD CONSTRAINT ck_location_parent_positive CHECK(parent_id IS NULL OR parent_id>0),
 ADD UNIQUE KEY uq_location_sibling(parent_scope_id,name);
ALTER TABLE equipment_model
 ADD manufacturer_scope_id BIGINT GENERATED ALWAYS AS(COALESCE(manufacturer_id,0)) PERSISTENT,
 ADD CONSTRAINT ck_equipment_model_manufacturer_positive CHECK(manufacturer_id IS NULL OR manufacturer_id>0),
 ADD UNIQUE KEY uq_equipment_model_identity(equipment_type_id,manufacturer_scope_id,name);

DELIMITER //

CREATE TRIGGER tr_equipment_type_bi BEFORE INSERT ON equipment_type FOR EACH ROW
BEGIN
DECLARE v_cursor BIGINT; DECLARE v_next BIGINT;
 SET NEW.name=TRIM(NEW.name);
 IF NEW.parent_id IS NOT NULL THEN
 IF COALESCE(IS_USED_LOCK(CONCAT(DATABASE(),'.structure')),0)<>CONNECTION_ID() THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Use set_equipment_type_parent, set_location_parent or install_component procedure'; END IF;
 IF NEW.id=NEW.parent_id THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='A node cannot be its own parent'; END IF;
 SET v_cursor=NEW.parent_id;
 WHILE v_cursor IS NOT NULL DO
  IF v_cursor=NEW.id THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Hierarchy cycle is forbidden'; END IF;
  SET v_next=NULL;
  SELECT parent_id INTO v_next FROM equipment_type WHERE id=v_cursor;
  SET v_cursor=v_next;
 END WHILE;
 END IF;
END//

CREATE TRIGGER tr_equipment_type_bu BEFORE UPDATE ON equipment_type FOR EACH ROW
BEGIN
DECLARE v_cursor BIGINT; DECLARE v_next BIGINT;
IF NEW.id<>OLD.id THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Identifiers are immutable'; END IF;
 SET NEW.name=TRIM(NEW.name);
 IF NOT(NEW.parent_id <=> OLD.parent_id) AND NEW.parent_id IS NOT NULL THEN
 IF COALESCE(IS_USED_LOCK(CONCAT(DATABASE(),'.structure')),0)<>CONNECTION_ID() THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Use set_equipment_type_parent, set_location_parent or install_component procedure'; END IF;
 IF NEW.id=NEW.parent_id THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='A node cannot be its own parent'; END IF;
 SET v_cursor=NEW.parent_id;
 WHILE v_cursor IS NOT NULL DO
  IF v_cursor=NEW.id THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Hierarchy cycle is forbidden'; END IF;
  SET v_next=NULL;
  SELECT parent_id INTO v_next FROM equipment_type WHERE id=v_cursor;
  SET v_cursor=v_next;
 END WHILE;
 END IF;
END//

CREATE PROCEDURE set_equipment_type_parent(IN p_id BIGINT, IN p_parent_id BIGINT)
SQL SECURITY DEFINER
BEGIN
 DECLARE v_lock INT DEFAULT 0;
 DECLARE v_exists INT;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  IF v_lock=1 THEN ROLLBACK; DO RELEASE_LOCK(CONCAT(DATABASE(),'.structure')); END IF;
  RESIGNAL;
 END;
 IF @@in_transaction=1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Call structural procedure outside an existing transaction'; END IF;
 SELECT GET_LOCK(CONCAT(DATABASE(),'.structure'),10) INTO v_lock;
 IF COALESCE(v_lock,0)<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Structure is busy; retry'; END IF;
 START TRANSACTION;
 SELECT COUNT(*) INTO v_exists FROM equipment_type WHERE id=p_id;
 IF v_exists<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Node does not exist'; END IF;
 UPDATE equipment_type SET parent_id=p_parent_id WHERE id=p_id;
 COMMIT;
 DO RELEASE_LOCK(CONCAT(DATABASE(),'.structure')); SET v_lock=0;
END//

CREATE TRIGGER tr_location_bi BEFORE INSERT ON location FOR EACH ROW
BEGIN
DECLARE v_cursor BIGINT; DECLARE v_next BIGINT;
 SET NEW.name=TRIM(NEW.name);
 IF NEW.parent_id IS NOT NULL THEN
 IF COALESCE(IS_USED_LOCK(CONCAT(DATABASE(),'.structure')),0)<>CONNECTION_ID() THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Use set_equipment_type_parent, set_location_parent or install_component procedure'; END IF;
 IF NEW.id=NEW.parent_id THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='A node cannot be its own parent'; END IF;
 SET v_cursor=NEW.parent_id;
 WHILE v_cursor IS NOT NULL DO
  IF v_cursor=NEW.id THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Hierarchy cycle is forbidden'; END IF;
  SET v_next=NULL;
  SELECT parent_id INTO v_next FROM location WHERE id=v_cursor;
  SET v_cursor=v_next;
 END WHILE;
 END IF;
END//

CREATE TRIGGER tr_location_bu BEFORE UPDATE ON location FOR EACH ROW
BEGIN
DECLARE v_cursor BIGINT; DECLARE v_next BIGINT;
IF NEW.id<>OLD.id THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Identifiers are immutable'; END IF;
 SET NEW.name=TRIM(NEW.name);
 IF NOT(NEW.parent_id <=> OLD.parent_id) AND NEW.parent_id IS NOT NULL THEN
 IF COALESCE(IS_USED_LOCK(CONCAT(DATABASE(),'.structure')),0)<>CONNECTION_ID() THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Use set_equipment_type_parent, set_location_parent or install_component procedure'; END IF;
 IF NEW.id=NEW.parent_id THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='A node cannot be its own parent'; END IF;
 SET v_cursor=NEW.parent_id;
 WHILE v_cursor IS NOT NULL DO
  IF v_cursor=NEW.id THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Hierarchy cycle is forbidden'; END IF;
  SET v_next=NULL;
  SELECT parent_id INTO v_next FROM location WHERE id=v_cursor;
  SET v_cursor=v_next;
 END WHILE;
 END IF;
END//

CREATE PROCEDURE set_location_parent(IN p_id BIGINT, IN p_parent_id BIGINT)
SQL SECURITY DEFINER
BEGIN
 DECLARE v_lock INT DEFAULT 0;
 DECLARE v_exists INT;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  IF v_lock=1 THEN ROLLBACK; DO RELEASE_LOCK(CONCAT(DATABASE(),'.structure')); END IF;
  RESIGNAL;
 END;
 IF @@in_transaction=1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Call structural procedure outside an existing transaction'; END IF;
 SELECT GET_LOCK(CONCAT(DATABASE(),'.structure'),10) INTO v_lock;
 IF COALESCE(v_lock,0)<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Structure is busy; retry'; END IF;
 START TRANSACTION;
 SELECT COUNT(*) INTO v_exists FROM location WHERE id=p_id;
 IF v_exists<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Node does not exist'; END IF;
 UPDATE location SET parent_id=p_parent_id WHERE id=p_id;
 COMMIT;
 DO RELEASE_LOCK(CONCAT(DATABASE(),'.structure')); SET v_lock=0;
END//

CREATE TRIGGER tr_employee_bi BEFORE INSERT ON employee FOR EACH ROW
BEGIN
DECLARE v_refs BIGINT DEFAULT 0; DECLARE v_account BIGINT;
IF NEW.is_mol=1 THEN SET v_account=NULL; SELECT id INTO v_account FROM user_account WHERE employee_id=NEW.id AND role_code='it_staff' AND is_active=1 FOR UPDATE; IF v_account IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='MOL requires an active IT staff account; create employee and account first'; END IF; END IF;
END//

CREATE TRIGGER tr_employee_bu BEFORE UPDATE ON employee FOR EACH ROW
BEGIN
DECLARE v_refs BIGINT DEFAULT 0; DECLARE v_account BIGINT;
IF NEW.id<>OLD.id THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Identifiers are immutable'; END IF;
IF NEW.is_mol=0 OR NEW.is_active=0 THEN SELECT COUNT(*) INTO v_refs FROM equipment WHERE mol_employee_id=OLD.id FOR UPDATE; IF v_refs>0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Reassign equipment before removing MOL eligibility'; END IF; END IF;
IF NEW.is_mol=1 THEN SET v_account=NULL; SELECT id INTO v_account FROM user_account WHERE employee_id=NEW.id AND role_code='it_staff' AND is_active=1 FOR UPDATE; IF v_account IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='MOL requires an active IT staff account; create employee and account first'; END IF; END IF;
END//

CREATE TRIGGER tr_user_account_bu BEFORE UPDATE ON user_account FOR EACH ROW
BEGIN
DECLARE v_mol TINYINT DEFAULT 0;
IF NEW.employee_id<>OLD.employee_id OR NEW.role_code<>'it_staff' OR NEW.is_active=0 THEN SET v_mol=0; SELECT is_mol INTO v_mol FROM employee WHERE id=OLD.employee_id FOR UPDATE; IF v_mol=1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Remove MOL eligibility and assignments before disabling or replacing IT account'; END IF; END IF;
END//

CREATE TRIGGER tr_user_account_bd BEFORE DELETE ON user_account FOR EACH ROW
BEGIN
DECLARE v_mol TINYINT DEFAULT 0;
IF TRUE THEN SET v_mol=0; SELECT is_mol INTO v_mol FROM employee WHERE id=OLD.employee_id FOR UPDATE; IF v_mol=1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Remove MOL eligibility and assignments before disabling or replacing IT account'; END IF; END IF;
END//

CREATE TRIGGER tr_equipment_bi BEFORE INSERT ON equipment FOR EACH ROW
BEGIN
DECLARE v_mol TINYINT; DECLARE v_active TINYINT; DECLARE v_manufacturer BIGINT;
IF NEW.mol_employee_id IS NOT NULL THEN
 SELECT is_mol,is_active INTO v_mol,v_active FROM employee WHERE id=NEW.mol_employee_id FOR UPDATE;
 IF COALESCE(v_mol,0)<>1 OR COALESCE(v_active,0)<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Assigned MOL must be an active approved MOL'; END IF;
 END IF;
 IF NEW.model_id IS NOT NULL THEN
 SET v_manufacturer=NULL;
 SELECT manufacturer_id INTO v_manufacturer FROM equipment_model WHERE id=NEW.model_id FOR UPDATE;
 IF v_manufacturer IS NOT NULL THEN
  IF NEW.manufacturer_id IS NULL THEN SET NEW.manufacturer_id=v_manufacturer;
  ELSEIF NEW.manufacturer_id<>v_manufacturer THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Equipment manufacturer differs from model manufacturer'; END IF;
 END IF;
 END IF;
END//

CREATE TRIGGER tr_equipment_bu BEFORE UPDATE ON equipment FOR EACH ROW
BEGIN
DECLARE v_mol TINYINT; DECLARE v_active TINYINT; DECLARE v_manufacturer BIGINT;
IF NEW.mol_employee_id IS NOT NULL THEN
 SELECT is_mol,is_active INTO v_mol,v_active FROM employee WHERE id=NEW.mol_employee_id FOR UPDATE;
 IF COALESCE(v_mol,0)<>1 OR COALESCE(v_active,0)<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Assigned MOL must be an active approved MOL'; END IF;
 END IF;
 IF NEW.model_id IS NOT NULL THEN
 SET v_manufacturer=NULL;
 SELECT manufacturer_id INTO v_manufacturer FROM equipment_model WHERE id=NEW.model_id FOR UPDATE;
 IF v_manufacturer IS NOT NULL THEN
  IF NEW.manufacturer_id IS NULL THEN SET NEW.manufacturer_id=v_manufacturer;
  ELSEIF NEW.manufacturer_id<>v_manufacturer THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Equipment manufacturer differs from model manufacturer'; END IF;
 END IF;
 END IF;
END//

CREATE TRIGGER tr_equipment_model_bi BEFORE INSERT ON equipment_model FOR EACH ROW
BEGIN
DECLARE v_conflicts BIGINT DEFAULT 0;
SET NEW.name=TRIM(NEW.name);

END//

CREATE TRIGGER tr_equipment_model_bu BEFORE UPDATE ON equipment_model FOR EACH ROW
BEGIN
DECLARE v_conflicts BIGINT DEFAULT 0;
SET NEW.name=TRIM(NEW.name);
IF NEW.id<>OLD.id THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Identifiers are immutable'; END IF;
IF NOT(NEW.manufacturer_id <=> OLD.manufacturer_id) AND NEW.manufacturer_id IS NOT NULL THEN SELECT COUNT(*) INTO v_conflicts FROM equipment WHERE model_id=OLD.id AND (manufacturer_id IS NULL OR manufacturer_id<>NEW.manufacturer_id) FOR UPDATE; IF v_conflicts>0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Model manufacturer conflicts with existing equipment; correct cards first'; END IF; END IF;
END//

CREATE TRIGGER tr_component_installation_bi BEFORE INSERT ON component_installation FOR EACH ROW
BEGIN
DECLARE v_cursor BIGINT; DECLARE v_next BIGINT;
IF NEW.is_current=1 THEN
 IF COALESCE(IS_USED_LOCK(CONCAT(DATABASE(),'.structure')),0)<>CONNECTION_ID() THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Use set_equipment_type_parent, set_location_parent or install_component procedure'; END IF;
 IF NEW.parent_equipment_id=NEW.component_equipment_id THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Equipment cannot contain itself'; END IF;
 SET v_cursor=NEW.parent_equipment_id;
 WHILE v_cursor IS NOT NULL DO
  IF v_cursor=NEW.component_equipment_id THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Component cycle is forbidden'; END IF;
  SET v_next=NULL;
  SELECT parent_equipment_id INTO v_next FROM component_installation
    WHERE component_equipment_id=v_cursor AND is_current=1;
  SET v_cursor=v_next;
 END WHILE;
 END IF;
END//

CREATE TRIGGER tr_component_installation_bu BEFORE UPDATE ON component_installation FOR EACH ROW
BEGIN
DECLARE v_cursor BIGINT; DECLARE v_next BIGINT;
IF NEW.is_current=1 AND (OLD.is_current=0 OR NEW.parent_equipment_id<>OLD.parent_equipment_id OR NEW.component_equipment_id<>OLD.component_equipment_id) THEN
 IF COALESCE(IS_USED_LOCK(CONCAT(DATABASE(),'.structure')),0)<>CONNECTION_ID() THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Use set_equipment_type_parent, set_location_parent or install_component procedure'; END IF;
 IF NEW.parent_equipment_id=NEW.component_equipment_id THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Equipment cannot contain itself'; END IF;
 SET v_cursor=NEW.parent_equipment_id;
 WHILE v_cursor IS NOT NULL DO
  IF v_cursor=NEW.component_equipment_id THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Component cycle is forbidden'; END IF;
  SET v_next=NULL;
  SELECT parent_equipment_id INTO v_next FROM component_installation
    WHERE component_equipment_id=v_cursor AND is_current=1;
  SET v_cursor=v_next;
 END WHILE;
 END IF;
END//

CREATE PROCEDURE install_component(IN p_parent BIGINT,IN p_component BIGINT,IN p_installed_on DATE,IN p_role VARCHAR(255),IN p_notes TEXT)
SQL SECURITY DEFINER
BEGIN
 DECLARE v_lock INT DEFAULT 0;
 DECLARE v_id BIGINT;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  IF v_lock=1 THEN ROLLBACK; DO RELEASE_LOCK(CONCAT(DATABASE(),'.structure')); END IF;
  RESIGNAL;
 END;
 IF @@in_transaction=1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Call structural procedure outside an existing transaction'; END IF;
 SELECT GET_LOCK(CONCAT(DATABASE(),'.structure'),10) INTO v_lock;
 IF COALESCE(v_lock,0)<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Structure is busy; retry'; END IF;
 START TRANSACTION;
 INSERT INTO component_installation(parent_equipment_id,component_equipment_id,installed_on,component_role,notes)
 VALUES(p_parent,p_component,p_installed_on,p_role,p_notes);
 SET v_id=LAST_INSERT_ID();
 COMMIT;
 DO RELEASE_LOCK(CONCAT(DATABASE(),'.structure')); SET v_lock=0;
 SELECT v_id AS installation_id;
END//
DELIMITER ;

SELECT 'Migration 003 applied: 14 domain tables; MOL flag, unknown usage and integrity checks' AS result;
