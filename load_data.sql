-- =====================================================================
-- Biobank and Biospecimen Management System
-- File: load_data.sql
-- Purpose: DML - loads meaningful test data (>=10 records per main
--          table; lookup tables have fewer records where justified).
-- Run create_tables.sql first.
-- =====================================================================

USE biobank;

-- ---------------------------------------------------------------------
-- SAMPLE_TYPE  (lookup table)
-- ---------------------------------------------------------------------
INSERT INTO SAMPLE_TYPE (Type_Name, Default_Storage_Temp) VALUES
('Whole Blood', -80.0),
('Plasma',      -80.0),
('Serum',       -80.0),
('Saliva',      -20.0),
('Tissue',      -196.0),
('DNA',         -20.0),
('Urine',       -20.0);

-- ---------------------------------------------------------------------
-- DONOR
-- ---------------------------------------------------------------------
INSERT INTO DONOR (First_Name, Last_Name, Date_Of_Birth, Sex, Email, Phone, Enrollment_Date, Status) VALUES
('Amina',   'Hassan',   '1988-03-14', 'F', 'amina.hassan@mail.com',   '01011122233', '2023-01-10', 'Active'),
('Omar',    'Farouk',   '1975-07-22', 'M', 'omar.farouk@mail.com',    '01022233344', '2023-01-15', 'Active'),
('Laila',   'Mostafa',  '1990-11-02', 'F', 'laila.mostafa@mail.com',  '01033344455', '2023-02-01', 'Active'),
('Youssef', 'Ibrahim',  '1982-05-30', 'M', 'youssef.ibrahim@mail.com','01044455566', '2023-02-10', 'Withdrawn'),
('Nour',    'Adel',     '1995-09-18', 'F', 'nour.adel@mail.com',      '01055566677', '2023-03-05', 'Active'),
('Karim',   'Said',     '1970-01-25', 'M', 'karim.said@mail.com',     '01066677788', '2023-03-20', 'Active'),
('Mona',    'Zaki',     '1993-12-08', 'F', 'mona.zaki@mail.com',      '01077788899', '2023-04-02', 'Active'),
('Tarek',   'Naguib',   '1965-04-11', 'M', 'tarek.naguib@mail.com',   '01088899900', '2023-04-15', 'Deceased'),
('Heba',    'Younis',   '1998-06-27', 'F', 'heba.younis@mail.com',    '01099900011', '2023-05-01', 'Active'),
('Sherif',  'Kamal',    '1987-08-19', 'M', 'sherif.kamal@mail.com',   '01012312312', '2023-05-18', 'Active'),
('Dina',    'Fathy',    '1991-02-14', 'F', 'dina.fathy@mail.com',     '01023423423', '2023-06-01', 'Active'),
('Ahmed',   'Rashad',   '1980-10-05', 'M', 'ahmed.rashad@mail.com',   '01034534534', '2023-06-20', 'Active');

-- ---------------------------------------------------------------------
-- CONSENT  (weak entity of DONOR - some donors have >1 consent record,
-- demonstrating history tracking)
-- ---------------------------------------------------------------------
INSERT INTO CONSENT (Donor_ID, Consent_Seq, Consent_Type, Date_Signed, Date_Withdrawn, Consent_Form_Ref) VALUES
(1, 1, 'Research Use',      '2023-01-10', NULL,         'CF-1001'),
(1, 2, 'Genetic Testing',   '2023-06-01', NULL,         'CF-1002'),
(2, 1, 'Research Use',      '2023-01-15', NULL,         'CF-1003'),
(3, 1, 'Research Use',      '2023-02-01', NULL,         'CF-1004'),
(3, 2, 'Future Contact',    '2023-02-01', NULL,         'CF-1005'),
(4, 1, 'Research Use',      '2023-02-10', '2023-09-01', 'CF-1006'),
(5, 1, 'Commercial Use',    '2023-03-05', NULL,         'CF-1007'),
(6, 1, 'Research Use',      '2023-03-20', NULL,         'CF-1008'),
(7, 1, 'Research Use',      '2023-04-02', NULL,         'CF-1009'),
(8, 1, 'Research Use',      '2023-04-15', NULL,         'CF-1010'),
(9, 1, 'Genetic Testing',   '2023-05-01', NULL,         'CF-1011'),
(10,1, 'Research Use',      '2023-05-18', NULL,         'CF-1012'),
(11,1, 'Future Contact',    '2023-06-01', NULL,         'CF-1013'),
(12,1, 'Research Use',      '2023-06-20', NULL,         'CF-1014');

-- ---------------------------------------------------------------------
-- COLLECTION_EVENT
-- ---------------------------------------------------------------------
INSERT INTO COLLECTION_EVENT (Donor_ID, Collection_Date, Site, Collected_By, Notes) VALUES
(1,  '2023-01-12', 'Main Clinic - Cairo',   'Nurse Yara',   'Routine baseline visit'),
(2,  '2023-01-16', 'Main Clinic - Cairo',   'Nurse Yara',   NULL),
(3,  '2023-02-03', 'Giza Satellite Site',   'Nurse Salma',  'Fasting sample'),
(4,  '2023-02-11', 'Main Clinic - Cairo',   'Nurse Yara',   NULL),
(5,  '2023-03-06', 'Alex Regional Site',    'Nurse Mervat', 'Follow-up visit'),
(6,  '2023-03-21', 'Main Clinic - Cairo',   'Nurse Yara',   NULL),
(7,  '2023-04-03', 'Giza Satellite Site',   'Nurse Salma',  'First-time donor'),
(8,  '2023-04-16', 'Main Clinic - Cairo',   'Nurse Yara',   'Family history noted'),
(9,  '2023-05-02', 'Alex Regional Site',    'Nurse Mervat', NULL),
(10, '2023-05-19', 'Main Clinic - Cairo',   'Nurse Yara',   NULL),
(11, '2023-06-02', 'Giza Satellite Site',   'Nurse Salma',  'Repeat donor'),
(12, '2023-06-21', 'Main Clinic - Cairo',   'Nurse Yara',   NULL),
(1,  '2023-09-15', 'Main Clinic - Cairo',   'Nurse Yara',   'Six-month follow-up');

-- ---------------------------------------------------------------------
-- SAMPLE
-- ---------------------------------------------------------------------
INSERT INTO SAMPLE (Collection_ID, Sample_Type_ID, Volume_ml, Collection_Time, Quality_Status) VALUES
(1,  1, 10.0, '09:15:00', 'Acceptable'),
(1,  2, 5.0,  '09:16:00', 'Acceptable'),
(2,  1, 8.5,  '10:02:00', 'Acceptable'),
(3,  4, 3.0,  '08:40:00', 'Acceptable'),
(4,  1, 10.0, '11:20:00', 'Compromised'),
(5,  3, 6.0,  '09:50:00', 'Acceptable'),
(6,  1, 9.0,  '10:15:00', 'Acceptable'),
(7,  5, 1.5,  '13:05:00', 'Acceptable'),
(8,  6, 0.5,  '14:00:00', 'Acceptable'),
(9,  1, 10.0, '09:30:00', 'Pending Review'),
(10, 2, 5.5,  '10:45:00', 'Acceptable'),
(11, 7, 20.0, '08:55:00', 'Acceptable'),
(12, 1, 9.5,  '09:05:00', 'Acceptable'),
(13, 1, 10.0, '09:10:00', 'Acceptable');

-- ---------------------------------------------------------------------
-- STORAGE_LOCATION
-- ---------------------------------------------------------------------
INSERT INTO STORAGE_LOCATION (Freezer_Name, Rack, Shelf, Box_Position, Current_Temp, Capacity) VALUES
('Freezer-A', 'R1', 'S1', 'B1', -80.0, 100),
('Freezer-A', 'R1', 'S1', 'B2', -80.0, 100),
('Freezer-A', 'R1', 'S2', 'B1', -80.0, 100),
('Freezer-B', 'R1', 'S1', 'B1', -20.0, 80),
('Freezer-B', 'R2', 'S1', 'B1', -20.0, 80),
('Freezer-C', 'R1', 'S1', 'B1', -196.0, 50),
('Freezer-A', 'R2', 'S1', 'B1', -80.0, 100),
('Freezer-B', 'R1', 'S2', 'B1', -20.0, 80),
('Freezer-A', 'R2', 'S2', 'B1', -80.0, 100),
('Freezer-C', 'R1', 'S2', 'B1', -196.0, 50);

-- ---------------------------------------------------------------------
-- ALIQUOT  (weak entity of SAMPLE; several samples split into multiple
-- aliquots, demonstrating the weak-entity partial key pattern)
-- ---------------------------------------------------------------------
INSERT INTO ALIQUOT (Sample_ID, Aliquot_Seq, Location_ID, Volume_ml, Freeze_Thaw_Cycles, Status) VALUES
(1, 1, 1, 5.0, 0, 'In Storage'),
(1, 2, 1, 5.0, 0, 'In Storage'),
(2, 1, 2, 5.0, 0, 'In Storage'),
(3, 1, 1, 4.25,0, 'In Storage'),
(3, 2, 2, 4.25,0, 'In Use'),
(4, 1, 4, 3.0, 0, 'In Storage'),
(5, 1, 1, 10.0,1, 'In Storage'),
(6, 1, 2, 6.0, 0, 'In Storage'),
(7, 1, 3, 9.0, 0, 'In Storage'),
(8, 1, 6, 1.5, 0, 'In Storage'),
(9, 1, 4, 0.5, 0, 'Depleted'),
(10,1, 3, 10.0,0, 'In Storage'),
(11,1, 2, 5.5, 0, 'In Storage'),
(12,1, 5, 20.0,0, 'In Storage'),
(13,1, 1, 9.5, 0, 'In Storage'),
(14,1, 1, 10.0,0, 'In Storage');

-- ---------------------------------------------------------------------
-- RESEARCHER
-- ---------------------------------------------------------------------
INSERT INTO RESEARCHER (First_Name, Last_Name, Email, Department, Institution) VALUES
('Salma',  'Nabil',   'salma.nabil@univ.edu',   'Molecular Biology', 'Cairo University'),
('Hossam', 'Gaber',   'hossam.gaber@univ.edu',  'Genomics',          'Cairo University'),
('Rania',  'Wahba',   'rania.wahba@univ.edu',   'Immunology',        'Alexandria University'),
('Fady',   'Boutros', 'fady.boutros@univ.edu',  'Oncology',          'Ain Shams University'),
('Yasmin', 'Sabry',   'yasmin.sabry@univ.edu',  'Genomics',          'Cairo University'),
('Adel',   'Fahmy',   'adel.fahmy@univ.edu',    'Bioinformatics',    'Nile University'),
('Reem',   'Aziz',    'reem.aziz@univ.edu',     'Immunology',        'Alexandria University'),
('Kareem', 'Sultan',  'kareem.sultan@univ.edu', 'Molecular Biology', 'Cairo University'),
('Farida', 'Hamdy',   'farida.hamdy@univ.edu',  'Oncology',          'Ain Shams University'),
('Wael',   'Shawky',  'wael.shawky@univ.edu',   'Bioinformatics',    'Nile University');

-- ---------------------------------------------------------------------
-- PROJECT
-- ---------------------------------------------------------------------
INSERT INTO PROJECT (Project_Title, IRB_Approval_No, Start_Date, End_Date, Lead_Researcher_ID) VALUES
('Type 2 Diabetes Biomarker Discovery',       'IRB-2023-001', '2023-02-01', NULL,         1),
('Breast Cancer Genomic Profiling',            'IRB-2023-002', '2023-03-01', NULL,         4),
('Population Genetic Diversity Study',         'IRB-2023-003', '2023-01-20', '2024-01-20', 2),
('Autoimmune Disease Antibody Panel',          'IRB-2023-004', '2023-04-01', NULL,         3),
('Saliva Microbiome Baseline Study',           'IRB-2023-005', '2023-05-01', NULL,         6),
('DNA Repair Pathway Variant Study',           'IRB-2023-006', '2023-03-15', NULL,         5),
('Cytokine Profiling in Healthy Donors',       'IRB-2023-007', '2023-06-01', NULL,         7),
('Long-term Frozen Plasma Stability Study',    'IRB-2023-008', '2023-02-15', '2024-06-15', 1);

-- ---------------------------------------------------------------------
-- PROJECT_RESEARCHER  (associative M:N table)
-- ---------------------------------------------------------------------
INSERT INTO PROJECT_RESEARCHER (Project_ID, Researcher_ID, Role_On_Project, Date_Joined) VALUES
(1, 1, 'Principal Investigator', '2023-02-01'),
(1, 8, 'Lab Analyst',            '2023-02-05'),
(2, 4, 'Principal Investigator', '2023-03-01'),
(2, 9, 'Co-Investigator',        '2023-03-01'),
(3, 2, 'Principal Investigator', '2023-01-20'),
(3, 5, 'Collaborator',           '2023-01-25'),
(4, 3, 'Principal Investigator', '2023-04-01'),
(4, 7, 'Co-Investigator',        '2023-04-01'),
(5, 6, 'Principal Investigator', '2023-05-01'),
(6, 5, 'Principal Investigator', '2023-03-15'),
(6, 10,'Bioinformatics Support', '2023-03-20'),
(7, 7, 'Principal Investigator', '2023-06-01'),
(8, 1, 'Principal Investigator', '2023-02-15'),
(8, 8, 'Lab Analyst',            '2023-02-20');

-- ---------------------------------------------------------------------
-- TEST_REQUEST
-- ---------------------------------------------------------------------
INSERT INTO TEST_REQUEST (Project_ID, Researcher_ID, Request_Date, Test_Description, Status) VALUES
(1, 1, '2023-03-01', 'Fasting glucose and HbA1c panel on plasma samples',        'Completed'),
(1, 8, '2023-03-10', 'Insulin resistance biomarker screen',                     'Approved'),
(2, 4, '2023-04-01', 'Whole exome sequencing on tissue specimens',               'Completed'),
(2, 9, '2023-04-15', 'HER2 expression assay',                                   'Approved'),
(3, 2, '2023-02-01', 'STR genotyping on whole blood',                           'Completed'),
(4, 3, '2023-05-01', 'Autoantibody ELISA panel on serum',                       'Pending'),
(5, 6, '2023-05-20', '16S rRNA sequencing of saliva microbiome',                'Approved'),
(6, 5, '2023-04-01', 'Targeted sequencing of BRCA1/BRCA2 on DNA extracts',      'Completed'),
(7, 7, '2023-06-10', 'Multiplex cytokine bead assay on plasma',                 'Pending'),
(8, 1, '2023-03-01', 'Plasma protein stability assessment across freeze cycles','Approved'),
(1, 1, '2023-07-01', 'Follow-up HbA1c re-test on six-month samples',            'Pending');

-- ---------------------------------------------------------------------
-- SAMPLE_USAGE  (associative M:N table resolving ALIQUOT <-> TEST_REQUEST)
-- ---------------------------------------------------------------------
INSERT INTO SAMPLE_USAGE (Sample_ID, Aliquot_Seq, Request_ID, Volume_Used_ml, Usage_Date, Result_Summary) VALUES
(1,  1, 1,  2.0, '2023-03-05', 'HbA1c = 5.8%, within normal range'),
(1,  2, 2,  2.0, '2023-03-12', 'Insulin resistance score calculated'),
(3,  2, 2,  1.5, '2023-03-14', 'Pending further analysis'),
(6,  1, 6,  1.0, '2023-05-05', 'Autoantibody panel negative'),
(7,  1, 5,  2.0, '2023-02-05', 'STR profile generated successfully'),
(8,  1, 7,  0.5, '2023-05-22', 'Microbiome diversity index computed'),
(10, 1, 4,  1.0, '2023-04-18', 'HER2 negative'),
(5,  1, 10, 3.0, '2023-03-05', 'Baseline protein concentration recorded'),
(5,  1, 10, 2.0, '2023-09-20', 'Six-month freeze cycle comparison recorded'),
(9,  1, 9,  0.4, '2023-06-15', 'Cytokine panel run 1 of 3'),
(14, 1, 11, 3.0, '2023-09-18', 'Follow-up HbA1c pending lab result');

-- ---------------------------------------------------------------------
-- STORAGE_TEMP_LOG  (history tracking of freezer conditions)
-- ---------------------------------------------------------------------
INSERT INTO STORAGE_TEMP_LOG (Location_ID, Reading_Time, Temp_Reading, In_Range) VALUES
(1, '2023-06-01 08:00:00', -80.1, 1),
(1, '2023-06-02 08:00:00', -79.8, 1),
(1, '2023-06-03 08:00:00', -74.5, 0),
(2, '2023-06-01 08:00:00', -80.0, 1),
(4, '2023-06-01 08:00:00', -20.2, 1),
(4, '2023-06-02 08:00:00', -19.9, 1),
(6, '2023-06-01 08:00:00', -196.0,1),
(6, '2023-06-02 08:00:00', -190.4,0),
(3, '2023-06-01 08:00:00', -80.3, 1),
(5, '2023-06-01 08:00:00', -20.0, 1),
(9, '2023-06-01 08:00:00', -80.2, 1),
(10,'2023-06-01 08:00:00', -195.8,1);
