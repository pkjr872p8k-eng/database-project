-- =====================================================================
-- Biobank and Biospecimen Management System
-- File: views.sql
-- Purpose: Database views (>= 2 required).
-- =====================================================================

USE biobank;

-- ---------------------------------------------------------------------
-- View 1: vw_available_aliquots
-- Purpose: Gives lab staff a single place to see every aliquot that is
-- still physically in storage and usable for a new test request,
-- together with donor, sample type, and exact freezer location.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vw_available_aliquots;
CREATE VIEW vw_available_aliquots AS
SELECT
    a.Sample_ID,
    a.Aliquot_Seq,
    st.Type_Name           AS Sample_Type,
    a.Volume_ml,
    a.Freeze_Thaw_Cycles,
    d.Donor_ID,
    CONCAT(d.First_Name, ' ', d.Last_Name) AS Donor_Name,
    sl.Freezer_Name,
    sl.Rack,
    sl.Shelf,
    sl.Box_Position
FROM ALIQUOT a
JOIN SAMPLE s            ON a.Sample_ID = s.Sample_ID
JOIN SAMPLE_TYPE st       ON s.Sample_Type_ID = st.Sample_Type_ID
JOIN COLLECTION_EVENT ce  ON s.Collection_ID = ce.Collection_ID
JOIN DONOR d               ON ce.Donor_ID = d.Donor_ID
JOIN STORAGE_LOCATION sl  ON a.Location_ID = sl.Location_ID
WHERE a.Status = 'In Storage';

-- ---------------------------------------------------------------------
-- View 2: vw_project_usage_summary
-- Purpose: Gives a project-level summary of how many test requests and
-- how much sample volume each research project has consumed, useful
-- for reporting to the biobank oversight committee.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vw_project_usage_summary;
CREATE VIEW vw_project_usage_summary AS
SELECT
    p.Project_ID,
    p.Project_Title,
    CONCAT(r.First_Name, ' ', r.Last_Name) AS Lead_Researcher,
    COUNT(DISTINCT tr.Request_ID)          AS Num_Requests,
    COUNT(su.Usage_ID)                     AS Num_Sample_Usages,
    COALESCE(SUM(su.Volume_Used_ml), 0)    AS Total_Volume_Used_ml
FROM PROJECT p
JOIN RESEARCHER r        ON p.Lead_Researcher_ID = r.Researcher_ID
LEFT JOIN TEST_REQUEST tr ON p.Project_ID = tr.Project_ID
LEFT JOIN SAMPLE_USAGE su ON tr.Request_ID = su.Request_ID
GROUP BY p.Project_ID, p.Project_Title, r.First_Name, r.Last_Name;

-- ---------------------------------------------------------------------
-- View 3 (bonus): vw_donor_sample_counts
-- Purpose: Quick roster of each active donor with how many samples and
-- aliquots have been collected from them - useful for donor management.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vw_donor_sample_counts;
CREATE VIEW vw_donor_sample_counts AS
SELECT
    d.Donor_ID,
    CONCAT(d.First_Name, ' ', d.Last_Name) AS Donor_Name,
    d.Status,
    COUNT(DISTINCT ce.Collection_ID) AS Num_Collections,
    COUNT(DISTINCT s.Sample_ID)      AS Num_Samples,
    COUNT(a.Sample_ID)               AS Num_Aliquots
FROM DONOR d
LEFT JOIN COLLECTION_EVENT ce ON d.Donor_ID = ce.Donor_ID
LEFT JOIN SAMPLE s             ON ce.Collection_ID = s.Collection_ID
LEFT JOIN ALIQUOT a            ON s.Sample_ID = a.Sample_ID
GROUP BY d.Donor_ID, d.First_Name, d.Last_Name, d.Status;
