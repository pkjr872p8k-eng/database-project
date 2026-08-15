-- =====================================================================
-- Biobank and Biospecimen Management System
-- File: create_tables.sql
-- Purpose: DDL - creates database, tables, primary/foreign keys,
--          constraints, and indexes.
-- DBMS: MySQL 8.0
-- =====================================================================

DROP DATABASE IF EXISTS biobank;
CREATE DATABASE biobank;
USE biobank;

-- ---------------------------------------------------------------------
-- 1. DONOR  (strong entity)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS DONOR (
    Donor_ID        INT AUTO_INCREMENT,
    First_Name      VARCHAR(40)  NOT NULL,
    Last_Name       VARCHAR(40)  NOT NULL,
    Date_Of_Birth   DATE         NOT NULL,
    Sex             ENUM('M','F','Other') NOT NULL,
    Email           VARCHAR(100) UNIQUE,
    Phone           VARCHAR(20),
    Enrollment_Date DATE         NOT NULL DEFAULT (CURRENT_DATE),
    Status          ENUM('Active','Withdrawn','Deceased') NOT NULL DEFAULT 'Active',
    PRIMARY KEY (Donor_ID)
);

-- ---------------------------------------------------------------------
-- 2. CONSENT  (weak entity - owned by DONOR; history tracking of consent
--    versions over time)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS CONSENT (
    Donor_ID        INT          NOT NULL,
    Consent_Seq     INT          NOT NULL,       -- partial key (1,2,3... per donor)
    Consent_Type    ENUM('Research Use','Commercial Use','Future Contact','Genetic Testing') NOT NULL,
    Date_Signed     DATE         NOT NULL,
    Date_Withdrawn  DATE         DEFAULT NULL,
    Consent_Form_Ref VARCHAR(60),
    PRIMARY KEY (Donor_ID, Consent_Seq),
    FOREIGN KEY (Donor_ID) REFERENCES DONOR(Donor_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_consent_dates CHECK (Date_Withdrawn IS NULL OR Date_Withdrawn >= Date_Signed)
);

-- ---------------------------------------------------------------------
-- 3. COLLECTION_EVENT  (owned by DONOR; each visit/collection episode)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS COLLECTION_EVENT (
    Collection_ID   INT AUTO_INCREMENT,
    Donor_ID        INT          NOT NULL,
    Collection_Date DATE         NOT NULL,
    Site            VARCHAR(60)  NOT NULL,
    Collected_By    VARCHAR(60)  NOT NULL,       -- staff/nurse name
    Notes           VARCHAR(255),
    PRIMARY KEY (Collection_ID),
    FOREIGN KEY (Donor_ID) REFERENCES DONOR(Donor_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- 4. SAMPLE_TYPE  (lookup table)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SAMPLE_TYPE (
    Sample_Type_ID   INT AUTO_INCREMENT,
    Type_Name         VARCHAR(40) NOT NULL UNIQUE,   -- Blood, Saliva, Tissue, Plasma, DNA...
    Default_Storage_Temp DECIMAL(5,1) NOT NULL,       -- Celsius, e.g. -80.0
    PRIMARY KEY (Sample_Type_ID)
);

-- ---------------------------------------------------------------------
-- 5. SAMPLE  (strong entity - a specimen drawn during a collection event)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SAMPLE (
    Sample_ID        INT AUTO_INCREMENT,
    Collection_ID     INT NOT NULL,
    Sample_Type_ID    INT NOT NULL,
    Volume_ml         DECIMAL(6,2),
    Collection_Time    TIME,
    Quality_Status     ENUM('Acceptable','Compromised','Pending Review') NOT NULL DEFAULT 'Pending Review',
    PRIMARY KEY (Sample_ID),
    FOREIGN KEY (Collection_ID) REFERENCES COLLECTION_EVENT(Collection_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (Sample_Type_ID) REFERENCES SAMPLE_TYPE(Sample_Type_ID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_volume CHECK (Volume_ml IS NULL OR Volume_ml > 0)
);

-- ---------------------------------------------------------------------
-- 6. STORAGE_LOCATION  (freezer / rack / shelf / position)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS STORAGE_LOCATION (
    Location_ID     INT AUTO_INCREMENT,
    Freezer_Name    VARCHAR(30) NOT NULL,
    Rack            VARCHAR(10) NOT NULL,
    Shelf           VARCHAR(10) NOT NULL,
    Box_Position    VARCHAR(10) NOT NULL,
    Current_Temp    DECIMAL(5,1) NOT NULL,
    Capacity        INT NOT NULL DEFAULT 100,
    PRIMARY KEY (Location_ID),
    CONSTRAINT uq_location UNIQUE (Freezer_Name, Rack, Shelf, Box_Position)
);

-- ---------------------------------------------------------------------
-- 7. ALIQUOT  (weak entity of SAMPLE - a sample is split into aliquots
--    that are individually stored/tracked)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ALIQUOT (
    Sample_ID        INT NOT NULL,
    Aliquot_Seq      INT NOT NULL,          -- partial key (1,2,3... per sample)
    Location_ID      INT NOT NULL,
    Volume_ml        DECIMAL(6,2) NOT NULL,
    Freeze_Thaw_Cycles INT NOT NULL DEFAULT 0,
    Status           ENUM('In Storage','In Use','Depleted','Discarded') NOT NULL DEFAULT 'In Storage',
    PRIMARY KEY (Sample_ID, Aliquot_Seq),
    FOREIGN KEY (Sample_ID) REFERENCES SAMPLE(Sample_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (Location_ID) REFERENCES STORAGE_LOCATION(Location_ID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_aliquot_volume CHECK (Volume_ml > 0)
);

-- ---------------------------------------------------------------------
-- 8. RESEARCHER  (strong entity)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS RESEARCHER (
    Researcher_ID   INT AUTO_INCREMENT,
    First_Name      VARCHAR(40) NOT NULL,
    Last_Name       VARCHAR(40) NOT NULL,
    Email           VARCHAR(100) NOT NULL UNIQUE,
    Department      VARCHAR(60),
    Institution     VARCHAR(100) NOT NULL,
    PRIMARY KEY (Researcher_ID)
);

-- ---------------------------------------------------------------------
-- 9. PROJECT  (research project requesting samples)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS PROJECT (
    Project_ID       INT AUTO_INCREMENT,
    Project_Title    VARCHAR(120) NOT NULL,
    IRB_Approval_No  VARCHAR(40)  NOT NULL UNIQUE,   -- ethics approval reference
    Start_Date       DATE NOT NULL,
    End_Date         DATE,
    Lead_Researcher_ID INT NOT NULL,
    PRIMARY KEY (Project_ID),
    FOREIGN KEY (Lead_Researcher_ID) REFERENCES RESEARCHER(Researcher_ID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_project_dates CHECK (End_Date IS NULL OR End_Date >= Start_Date)
);

-- ---------------------------------------------------------------------
-- 10. PROJECT_RESEARCHER  (associative table resolving M:N between
--     PROJECT and RESEARCHER - a project can have many team members,
--     a researcher can work on many projects)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS PROJECT_RESEARCHER (
    Project_ID      INT NOT NULL,
    Researcher_ID   INT NOT NULL,
    Role_On_Project VARCHAR(40) NOT NULL DEFAULT 'Collaborator',
    Date_Joined     DATE NOT NULL DEFAULT (CURRENT_DATE),
    PRIMARY KEY (Project_ID, Researcher_ID),
    FOREIGN KEY (Project_ID) REFERENCES PROJECT(Project_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (Researcher_ID) REFERENCES RESEARCHER(Researcher_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- 11. TEST_REQUEST  (a researcher/project requests use of specimens)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS TEST_REQUEST (
    Request_ID       INT AUTO_INCREMENT,
    Project_ID        INT NOT NULL,
    Researcher_ID      INT NOT NULL,          -- requester
    Request_Date       DATE NOT NULL DEFAULT (CURRENT_DATE),
    Test_Description   VARCHAR(200) NOT NULL,
    Status             ENUM('Pending','Approved','Rejected','Completed') NOT NULL DEFAULT 'Pending',
    PRIMARY KEY (Request_ID),
    FOREIGN KEY (Project_ID) REFERENCES PROJECT(Project_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (Researcher_ID) REFERENCES RESEARCHER(Researcher_ID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- 12. SAMPLE_USAGE  (associative table resolving M:N between ALIQUOT
--     and TEST_REQUEST - an aliquot can be used by several requests
--     over time [partial use]; a request can consume many aliquots)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SAMPLE_USAGE (
    Usage_ID          INT AUTO_INCREMENT,
    Sample_ID          INT NOT NULL,
    Aliquot_Seq        INT NOT NULL,
    Request_ID         INT NOT NULL,
    Volume_Used_ml     DECIMAL(6,2) NOT NULL,
    Usage_Date         DATE NOT NULL DEFAULT (CURRENT_DATE),
    Result_Summary     VARCHAR(255),
    PRIMARY KEY (Usage_ID),
    FOREIGN KEY (Sample_ID, Aliquot_Seq) REFERENCES ALIQUOT(Sample_ID, Aliquot_Seq)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (Request_ID) REFERENCES TEST_REQUEST(Request_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_usage_volume CHECK (Volume_Used_ml > 0)
);

-- ---------------------------------------------------------------------
-- 13. STORAGE_TEMP_LOG  (history tracking of freezer temperature checks)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS STORAGE_TEMP_LOG (
    Log_ID          INT AUTO_INCREMENT,
    Location_ID     INT NOT NULL,
    Reading_Time    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Temp_Reading    DECIMAL(5,1) NOT NULL,
    In_Range        TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (Log_ID),
    FOREIGN KEY (Location_ID) REFERENCES STORAGE_LOCATION(Location_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- Indexes to support frequent lookups / joins
-- ---------------------------------------------------------------------
CREATE INDEX idx_sample_collection ON SAMPLE(Collection_ID);
CREATE INDEX idx_collection_donor  ON COLLECTION_EVENT(Donor_ID);
CREATE INDEX idx_aliquot_location  ON ALIQUOT(Location_ID);
CREATE INDEX idx_usage_request     ON SAMPLE_USAGE(Request_ID);
CREATE INDEX idx_request_project   ON TEST_REQUEST(Project_ID);
CREATE INDEX idx_donor_status      ON DONOR(Status);
