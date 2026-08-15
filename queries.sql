-- =====================================================================
-- Biobank and Biospecimen Management System
-- File: queries.sql
-- Purpose: Meaningful SQL operations - retrieval, joins, aggregation,
--          subqueries, inserts, updates, deletes.
-- =====================================================================

USE biobank;

-- =====================================================================
-- SECTION A: RETRIEVAL / FILTERING
-- =====================================================================

-- A1. List all active donors, most recently enrolled first.
SELECT Donor_ID, First_Name, Last_Name, Enrollment_Date
FROM DONOR
WHERE Status = 'Active'
ORDER BY Enrollment_Date DESC;

-- A2. List all aliquots currently stored in Freezer-A that still have
-- more than 2 ml remaining.
SELECT a.Sample_ID, a.Aliquot_Seq, a.Volume_ml, sl.Rack, sl.Shelf, sl.Box_Position
FROM ALIQUOT a
JOIN STORAGE_LOCATION sl ON a.Location_ID = sl.Location_ID
WHERE sl.Freezer_Name = 'Freezer-A'
  AND a.Volume_ml > 2
ORDER BY a.Sample_ID;

-- =====================================================================
-- SECTION B: JOINS
-- =====================================================================

-- B1. Inner join: every sample with its donor name and sample type.
SELECT s.Sample_ID, CONCAT(d.First_Name, ' ', d.Last_Name) AS Donor_Name,
       st.Type_Name, s.Volume_ml, s.Quality_Status
FROM SAMPLE s
INNER JOIN COLLECTION_EVENT ce ON s.Collection_ID = ce.Collection_ID
INNER JOIN DONOR d              ON ce.Donor_ID = d.Donor_ID
INNER JOIN SAMPLE_TYPE st       ON s.Sample_Type_ID = st.Sample_Type_ID
ORDER BY s.Sample_ID;

-- B2. Left join: every project with its test requests, including
-- projects that have not yet received any requests.
SELECT p.Project_Title, tr.Request_ID, tr.Test_Description, tr.Status
FROM PROJECT p
LEFT JOIN TEST_REQUEST tr ON p.Project_ID = tr.Project_ID
ORDER BY p.Project_Title;

-- B3. Multi-table join: full traceability chain from donor to test
-- request result (donor -> sample -> aliquot -> usage -> request).
SELECT
    CONCAT(d.First_Name, ' ', d.Last_Name) AS Donor_Name,
    s.Sample_ID, a.Aliquot_Seq,
    su.Volume_Used_ml, su.Result_Summary,
    p.Project_Title
FROM SAMPLE_USAGE su
JOIN ALIQUOT a         ON su.Sample_ID = a.Sample_ID AND su.Aliquot_Seq = a.Aliquot_Seq
JOIN SAMPLE s           ON a.Sample_ID = s.Sample_ID
JOIN COLLECTION_EVENT ce ON s.Collection_ID = ce.Collection_ID
JOIN DONOR d              ON ce.Donor_ID = d.Donor_ID
JOIN TEST_REQUEST tr      ON su.Request_ID = tr.Request_ID
JOIN PROJECT p             ON tr.Project_ID = p.Project_ID
ORDER BY d.Last_Name;

-- =====================================================================
-- SECTION C: AGGREGATION
-- =====================================================================

-- C1. Number of samples collected per sample type.
SELECT st.Type_Name, COUNT(s.Sample_ID) AS Num_Samples
FROM SAMPLE_TYPE st
LEFT JOIN SAMPLE s ON st.Sample_Type_ID = s.Sample_Type_ID
GROUP BY st.Type_Name
ORDER BY Num_Samples DESC;

-- C2. Total and average sample volume collected per donor.
SELECT d.Donor_ID, CONCAT(d.First_Name, ' ', d.Last_Name) AS Donor_Name,
       SUM(s.Volume_ml) AS Total_Volume_ml,
       ROUND(AVG(s.Volume_ml), 2) AS Avg_Volume_ml
FROM DONOR d
JOIN COLLECTION_EVENT ce ON d.Donor_ID = ce.Donor_ID
JOIN SAMPLE s             ON ce.Collection_ID = s.Collection_ID
GROUP BY d.Donor_ID, d.First_Name, d.Last_Name
HAVING SUM(s.Volume_ml) > 5
ORDER BY Total_Volume_ml DESC;

-- C3. Number of test requests per project, only projects with 2 or more.
SELECT p.Project_Title, COUNT(tr.Request_ID) AS Num_Requests
FROM PROJECT p
JOIN TEST_REQUEST tr ON p.Project_ID = tr.Project_ID
GROUP BY p.Project_Title
HAVING COUNT(tr.Request_ID) >= 2
ORDER BY Num_Requests DESC;

-- =====================================================================
-- SECTION D: SUBQUERIES / NESTED QUERIES
-- =====================================================================

-- D1. Not-correlated subquery: donors who have provided a sample of
-- type 'DNA'.
SELECT First_Name, Last_Name
FROM DONOR
WHERE Donor_ID IN (
    SELECT ce.Donor_ID
    FROM COLLECTION_EVENT ce
    JOIN SAMPLE s ON ce.Collection_ID = s.Collection_ID
    JOIN SAMPLE_TYPE st ON s.Sample_Type_ID = st.Sample_Type_ID
    WHERE st.Type_Name = 'DNA'
);

-- D2. Correlated subquery: aliquots whose volume is below the average
-- volume of all aliquots belonging to the same sample.
SELECT a1.Sample_ID, a1.Aliquot_Seq, a1.Volume_ml
FROM ALIQUOT a1
WHERE a1.Volume_ml < (
    SELECT AVG(a2.Volume_ml)
    FROM ALIQUOT a2
    WHERE a2.Sample_ID = a1.Sample_ID
);

-- D3. Researchers who have never led a project (correlated NOT EXISTS).
SELECT r.First_Name, r.Last_Name
FROM RESEARCHER r
WHERE NOT EXISTS (
    SELECT * FROM PROJECT p WHERE p.Lead_Researcher_ID = r.Researcher_ID
);

-- D4. Projects whose total sample usage volume exceeds the overall
-- average usage volume per project (subquery in HAVING).
SELECT p.Project_Title, SUM(su.Volume_Used_ml) AS Total_Used
FROM PROJECT p
JOIN TEST_REQUEST tr ON p.Project_ID = tr.Project_ID
JOIN SAMPLE_USAGE su ON tr.Request_ID = su.Request_ID
GROUP BY p.Project_Title
HAVING SUM(su.Volume_Used_ml) > (
    SELECT AVG(project_total)
    FROM (
        SELECT SUM(su2.Volume_Used_ml) AS project_total
        FROM PROJECT p2
        JOIN TEST_REQUEST tr2 ON p2.Project_ID = tr2.Project_ID
        JOIN SAMPLE_USAGE su2 ON tr2.Request_ID = su2.Request_ID
        GROUP BY p2.Project_ID
    ) AS project_totals
);

-- =====================================================================
-- SECTION E: DATA MODIFICATION (INSERT / UPDATE / DELETE)
-- =====================================================================

-- E1. INSERT: enroll a new donor.
INSERT INTO DONOR (First_Name, Last_Name, Date_Of_Birth, Sex, Email, Phone, Enrollment_Date, Status)
VALUES ('Nadia', 'Elshamy', '1992-04-09', 'F', 'nadia.elshamy@mail.com', '01098765432', CURRENT_DATE, 'Active');

-- E2. INSERT: record consent for the new donor.
INSERT INTO CONSENT (Donor_ID, Consent_Seq, Consent_Type, Date_Signed, Consent_Form_Ref)
VALUES (LAST_INSERT_ID(), 1, 'Research Use', CURRENT_DATE, 'CF-1015');

-- E3. UPDATE: mark a donor as withdrawn and cascade a business
-- decision to close their open consent.
UPDATE DONOR SET Status = 'Withdrawn' WHERE Donor_ID = 6;

UPDATE CONSENT
SET Date_Withdrawn = CURRENT_DATE
WHERE Donor_ID = 6 AND Date_Withdrawn IS NULL;

-- E4. UPDATE: correct a freezer's logged current temperature after
-- maintenance.
UPDATE STORAGE_LOCATION
SET Current_Temp = -80.0
WHERE Freezer_Name = 'Freezer-A' AND Rack = 'R1' AND Shelf = 'S1' AND Box_Position = 'B1';

-- E5. DELETE: cancel a pending test request entered in error. The
-- ON DELETE CASCADE on SAMPLE_USAGE.Request_ID automatically removes
-- any preliminary usage record logged against it.
DELETE FROM TEST_REQUEST
WHERE Status = 'Pending'
  AND Request_ID = (
      SELECT Request_ID FROM (
          SELECT Request_ID FROM TEST_REQUEST
          WHERE Test_Description LIKE '%Multiplex cytokine%'
      ) AS t
  );

-- E6. DELETE: discard an aliquot that has been fully depleted and is
-- older than a defined cutoff (example uses a fixed illustrative date).
DELETE FROM ALIQUOT
WHERE Status = 'Depleted';
