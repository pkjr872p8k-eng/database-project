-- =====================================================================
-- Biobank and Biospecimen Management System
-- File: triggers_procedures.sql
-- Purpose: Advanced database objects - trigger(s), stored procedure(s).
-- =====================================================================

USE biobank;

-- ---------------------------------------------------------------------
-- TRIGGER 1: trg_aliquot_volume_check (BEFORE INSERT)
-- Business rule: an aliquot's volume can never exceed the remaining
-- volume of its parent sample (sum of that sample's existing aliquots
-- plus the new one must not exceed the sample's original volume).
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_aliquot_volume_check;

DELIMITER $$
CREATE TRIGGER trg_aliquot_volume_check
BEFORE INSERT ON ALIQUOT
FOR EACH ROW
BEGIN
    DECLARE sample_volume DECIMAL(6,2);
    DECLARE used_volume   DECIMAL(6,2);

    SELECT Volume_ml INTO sample_volume
    FROM SAMPLE
    WHERE Sample_ID = NEW.Sample_ID;

    SELECT COALESCE(SUM(Volume_ml), 0) INTO used_volume
    FROM ALIQUOT
    WHERE Sample_ID = NEW.Sample_ID;

    IF (used_volume + NEW.Volume_ml) > sample_volume THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Aliquot volume exceeds remaining sample volume.';
    END IF;
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- TRIGGER 2: trg_usage_depletes_aliquot (AFTER INSERT)
-- Business rule: whenever an aliquot is consumed through SAMPLE_USAGE,
-- automatically deduct the used volume from the aliquot and mark it
-- 'Depleted' once its remaining volume reaches zero. This keeps
-- inventory accurate without relying on manual updates.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_usage_depletes_aliquot;

DELIMITER $$
CREATE TRIGGER trg_usage_depletes_aliquot
AFTER INSERT ON SAMPLE_USAGE
FOR EACH ROW
BEGIN
    UPDATE ALIQUOT
    SET Volume_ml = Volume_ml - NEW.Volume_Used_ml
    WHERE Sample_ID = NEW.Sample_ID AND Aliquot_Seq = NEW.Aliquot_Seq;

    UPDATE ALIQUOT
    SET Status = 'Depleted'
    WHERE Sample_ID = NEW.Sample_ID
      AND Aliquot_Seq = NEW.Aliquot_Seq
      AND Volume_ml <= 0;
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- STORED PROCEDURE 1: sp_register_test_request
-- Purpose: registers a new test request and immediately links it to a
-- chosen aliquot in one transactional call, avoiding partial inserts.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_register_test_request;

DELIMITER $$
CREATE PROCEDURE sp_register_test_request (
    IN  p_Project_ID     INT,
    IN  p_Researcher_ID  INT,
    IN  p_Description    VARCHAR(200),
    IN  p_Sample_ID      INT,
    IN  p_Aliquot_Seq    INT,
    IN  p_Volume_Used    DECIMAL(6,2),
    OUT p_Request_ID     INT
)
BEGIN
    DECLARE avail_volume DECIMAL(6,2);

    SELECT Volume_ml INTO avail_volume
    FROM ALIQUOT
    WHERE Sample_ID = p_Sample_ID AND Aliquot_Seq = p_Aliquot_Seq
      AND Status = 'In Storage';

    IF avail_volume IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Aliquot not found or not available for use.';
    ELSEIF avail_volume < p_Volume_Used THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Requested volume exceeds available aliquot volume.';
    ELSE
        START TRANSACTION;

        INSERT INTO TEST_REQUEST (Project_ID, Researcher_ID, Test_Description, Status)
        VALUES (p_Project_ID, p_Researcher_ID, p_Description, 'Approved');

        SET p_Request_ID = LAST_INSERT_ID();

        INSERT INTO SAMPLE_USAGE (Sample_ID, Aliquot_Seq, Request_ID, Volume_Used_ml)
        VALUES (p_Sample_ID, p_Aliquot_Seq, p_Request_ID, p_Volume_Used);

        COMMIT;
    END IF;
END$$
DELIMITER ;

-- Example call:
-- CALL sp_register_test_request(1, 1, 'Repeat HbA1c assay', 1, 1, 1.0, @new_id);
-- SELECT @new_id;

-- ---------------------------------------------------------------------
-- FUNCTION 1: fn_donor_active_consent
-- Purpose: returns 1 if a donor currently has at least one active
-- (non-withdrawn) research-use consent on file, 0 otherwise. Used to
-- gate whether a donor's samples may be released for new research use.
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_donor_active_consent;

DELIMITER $$
CREATE FUNCTION fn_donor_active_consent (p_Donor_ID INT)
RETURNS TINYINT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*) INTO v_count
    FROM CONSENT
    WHERE Donor_ID = p_Donor_ID
      AND Consent_Type = 'Research Use'
      AND Date_Withdrawn IS NULL;

    IF v_count > 0 THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END$$
DELIMITER ;

-- Example call:
-- SELECT Donor_ID, fn_donor_active_consent(Donor_ID) AS Has_Active_Consent FROM DONOR;
