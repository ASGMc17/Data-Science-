create schema capstone1;
use capstone1;

-- change table and column names
rename table `hospitalisation details` to hospitalization_details;

rename table`medical examinations` to medical_examinations;

alter table hospitalization_details
rename column `Customer ID` to customer_id,
rename column `Hospital tier` to hospital_tier,
rename column `City tier` to city_tier,
rename column `State ID` to state_id;

alter table medical_examinations
rename column `Customer ID` to customer_id,
rename column `Heart Issues` to heart_issues,
rename column `Any Transplants` to any_transplants,
rename column `Cancer history` to cancer_history;

alter table names
rename column `ï»¿Customer ID` to customer_id;

-- 1.a. Merge the two tables by first identifying the columns in the data tables that will help you in merging

-- create view for merged tables
CREATE OR REPLACE VIEW vw_patient_full AS
SELECT
  h.customer_id,
  n.name,
  h.year, h.month, h.date,
  h.children,
  h.charges,
  h.hospital_tier,
  h.city_tier,
  h.state_id,
  m.bmi,
  m.hba1c,
  m.heart_issues,
  m.any_transplants,
  m.cancer_history,
  m.numberofmajorsurgeries,
  m.smoker
FROM hospitalization_details h
JOIN medical_examinations m
  ON m.customer_id = h.customer_id
LEFT JOIN names n
  ON n.customer_id = h.customer_id;
  
-- See new view
select * from vw_patient_full;

-- 1.b. In both tables, add a Primary Key constraint for these columns
-- set customer ids to acceptable key type
ALTER TABLE hospitalization_details
MODIFY customer_id VARCHAR(50);

ALTER TABLE medical_examinations
MODIFY customer_id VARCHAR(50);

-- Remove Nulls and blanks
DELETE FROM hospitalization_details
WHERE customer_id IS NULL OR TRIM(customer_id) IN ('', '?');

DELETE FROM medical_examinations
WHERE customer_id IS NULL OR TRIM(customer_id) IN ('', '?');
    
-- Remove duplicates using new clean table
CREATE TABLE hospitalization_details_clean AS
SELECT *
FROM (
  SELECT h.*,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY customer_id) AS rn
  FROM hospitalization_details h
) x
WHERE x.rn = 1;

ALTER TABLE hospitalization_details_clean DROP COLUMN rn;

CREATE TABLE medical_examinations_clean AS
SELECT *
FROM (
  SELECT m.*,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY customer_id) AS rn
  FROM medical_examinations m
) x
WHERE x.rn = 1;

ALTER TABLE medical_examinations_clean DROP COLUMN rn;

-- Rename new to old and drop old
DROP TABLE hospitalization_details;
RENAME TABLE hospitalization_details_clean TO hospitalization_details;

DROP TABLE medical_examinations;
RENAME TABLE medical_examinations_clean TO medical_examinations;

-- Add primary keys
ALTER TABLE hospitalization_details
ADD CONSTRAINT pk_hospitalization_details PRIMARY KEY (customer_id);

ALTER TABLE medical_examinations
ADD CONSTRAINT pk_medical_examinations PRIMARY KEY (customer_id);
-- 2. Retrieve information about people who are diabetic and have heart problems with their average age, the average number of dependent children, average BMI, and average hospitalization costs
SELECT 
    AVG(TIMESTAMPDIFF(YEAR,
        STR_TO_DATE(CONCAT(h.year, '-', h.month, '-', h.date),
                '%Y-%m-%d'),
        CURDATE())) AS avg_age,
    AVG(h.children) AS avg_children,
    AVG(m.bmi) AS avg_bmi,
    AVG(h.charges) AS avg_hospitalization_cost
FROM
    hospitalization_details h
        JOIN
    medical_examinations m ON m.customer_id = h.customer_id
WHERE
    m.hba1c > 6.5
        AND LOWER(m.heart_issues) = 'yes';
-- avg age is null because the DOB fields cannot be converted to a valid date.

-- 3. Find the average hospitalization cost for each hospital tier and each city level
SELECT
  h.hospital_tier,
  h.city_tier,
  AVG(h.charges) AS avg_cost
FROM hospitalization_details h
GROUP BY
  h.hospital_tier,
  h.city_tier
ORDER BY
  h.hospital_tier,
  h.city_tier;
  
-- 4. Determine the number of people who have had major surgery with a history of cancer
SELECT COUNT(DISTINCT customer_id) AS people_count
FROM medical_examinations
WHERE LOWER(cancer_history) = 'yes'
  AND numberofmajorsurgeries > 0;
  
-- 5. Determine the number of tier-1 hospitals in each state
SELECT
  state_id,
  COUNT(*) AS tier1_count
FROM hospitalization_details
WHERE REPLACE(LOWER(TRIM(hospital_tier)), ' ', '') IN ('tier1','tier-1','1')
GROUP BY state_id
ORDER BY tier1_count DESC;