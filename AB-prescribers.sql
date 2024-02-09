--For this exericse, you'll be working with a database derived from the [Medicare Part D Prescriber Public Use File](https://www.hhs.gov/guidance/document/medicare-provider-utilization-and-payment-data-part-d-prescriber-0). More information about the data is contained in the Methodology PDF file. See also the included entity-relationship diagram.

/*1. 
    a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
    
    b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
*/
-- a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi, SUM(total_claim_count) AS all_drug_total_claims
FROM prescription
GROUP BY npi
ORDER BY all_drug_total_claims DESC;
-- npi# 1881634483 had the most claims

-- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, SUM(total_claim_count) AS all_drug_total_claims
FROM prescription AS p1
LEFT JOIN prescriber AS p2
USING(npi)
GROUP BY npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
ORDER BY all_drug_total_claims DESC;
-- npi# 1881634483 (Bruce Pendley, in family practice) had the most claims

/*2. 
    a. Which specialty had the most total number of claims (totaled over all drugs)?

    b. Which specialty had the most total number of claims for opioids?

    c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

    d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
*/
-- a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description, SUM(total_claim_count) AS all_drug_total_claims
FROM prescription AS p1
LEFT JOIN prescriber AS p2
USING(npi)
GROUP BY specialty_description
ORDER BY all_drug_total_claims DESC;
-- Family Practice had the most claims

-- b. Which specialty had the most total number of claims for opioids?
SELECT specialty_description, SUM(total_claim_count) AS all_drug_total_claims
FROM prescription AS p1
LEFT JOIN prescriber AS p2
USING(npi)
LEFT JOIN drug
USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY all_drug_total_claims DESC;
-- Nurse Practitioners have the most claims for opioids with 900,845 claims

-- c. Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT DISTINCT(specialty_description)
FROM 
(SELECT specialty_description, SUM(total_claim_count) AS all_drug_total_claims
FROM prescriber
LEFT JOIN prescription
USING(npi)
GROUP BY specialty_description)
WHERE all_drug_total_claims IS NULL;
-- There are 15 specialties in the prescriber table with no associated prescriptions

-- d. For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
WITH opioid_count
AS
(
SELECT specialty_description, SUM(total_claim_count) AS opioid_total_count
FROM prescription AS p1
LEFT JOIN prescriber AS p2
USING(npi)
LEFT JOIN drug
USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
),

non_opioid_count
AS
(
SELECT specialty_description, SUM(total_claim_count) AS non_opioid_total_count
FROM prescription AS p1
LEFT JOIN prescriber AS p2
USING(npi)
LEFT JOIN drug
USING(drug_name)
WHERE opioid_drug_flag = 'N'
GROUP BY specialty_description
)

SELECT *, 
	opioid_total_count + non_opioid_total_count AS all_drugs_total_count, 
	ROUND(100*opioid_total_count*1./(opioid_total_count + non_opioid_total_count),2) AS opioid_percentage
FROM opioid_count
FULL JOIN non_opioid_count
USING(specialty_description)
ORDER BY opioid_percentage DESC;
--Case Managers and Orthopaedic Surgery have high  opioid percentages, but they don't prescribe often.
-- The highest opioid percentage specialty with over 1000 claims is interventional pain management.


/*3. 
    a. Which drug (generic_name) had the highest total drug cost?

    b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
*/
-- a. Which drug (generic_name) had the highest total drug cost
SELECT generic_name, SUM(total_drug_cost) AS total_cost
FROM drug
LEFT JOIN prescription
USING(drug_name)
WHERE total_drug_cost IS NOT NULL
GROUP BY generic_name
ORDER BY total_cost DESC;
-- Insulin Glargine had the highest total drug cost at $104,264,066.35

--b. Which drug (generic_name) has the hightest total cost per day?
SELECT generic_name, 
	SUM(total_drug_cost) AS total_cost, 
	SUM(total_day_supply) AS total_days, 
	ROUND(SUM(total_drug_cost)/SUM(total_day_supply),2) AS cost_per_day
FROM drug
LEFT JOIN prescription
USING(drug_name)
WHERE total_drug_cost IS NOT NULL
GROUP BY generic_name
ORDER BY cost_per_day DESC;
-- The drug with the highest cost per day is C1 Esterase Inhibitor at $3,495.22/day

/*
4. 
    a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

    b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
*/

-- a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
SELECT drug_name,
(CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
ELSE 'neither' END) AS drug_type
FROM drug;

-- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT drug_type, SUM(total_drug_cost) AS total_cost_by_drug_type
FROM prescription
INNER JOIN(
SELECT drug_name,
(CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
ELSE 'neither' END) AS drug_type
FROM drug
)
USING(drug_name)
GROUP BY drug_type
ORDER BY total_cost_by_drug_type DESC;
-- More was spent on opioids ($105,080,626.37) than antibiotics ($38,435,121.26)

/*
5. 
    a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

    b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

    c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
*/

-- a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(DISTINCT(cbsa))
FROM cbsa
INNER JOIN fips_county
USING(fipscounty)
WHERE state = 'TN';
-- There are 10 CBSAs in Tennessee

-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsaname, SUM(population) AS total_cbsa_population
FROM cbsa
INNER JOIN fips_county
USING(fipscounty)
INNER JOIN population
USING(fipscounty)
GROUP BY cbsaname
ORDER BY total_cbsa_population DESC;
-- Nashville-Davidson-Murfreesboro-Franklin, TN has the highest total cbsa population with 1,830,410 people.
-- Morristown, TN has the lowest total cbsa population with 116,352 people.

-- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT county, population
FROM population
INNER JOIN fips_county
USING(fipscounty)
LEFT JOIN cbsa
USING(fipscounty)
WHERE cbsa IS NULL
ORDER BY population DESC;
-- The largest county in TN not included in a cbsa is Sevier county with 95,523 people.

/*
6. 
    a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

    b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

    c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
*/

-- a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name, total_claim_count, opioid_drug_flag
FROM prescription
LEFT JOIN drug
USING(drug_name)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

-- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT nppes_provider_first_name, nppes_provider_last_org_name, drug_name, total_claim_count, opioid_drug_flag
FROM prescription
LEFT JOIN drug
USING(drug_name)
LEFT JOIN prescriber
USING(npi)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

/*
7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

    a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

    b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
    
    c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
*/

-- a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';
	
-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT combo.npi, combo.drug_name, total_claim_count
FROM prescription
RIGHT JOIN
(
SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y') AS combo
USING(drug_name, npi)
ORDER BY total_claim_count DESC NULLS LAST;

-- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT combo.npi, combo.drug_name, COALESCE(total_claim_count, 0) AS total_claim_count
FROM prescription
RIGHT JOIN
(
SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y') AS combo
USING(drug_name, npi)
ORDER BY total_claim_count DESC;