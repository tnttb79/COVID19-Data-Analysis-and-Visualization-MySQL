-- COVID 19 DATA EXPLORATION 
-- LINK TO THE DATASET: https://ourworldindata.org/covid-deaths 

USE mydatabase;

-- RENAMETABLES------
RENAME TABLE coviddeaths TO covid_deaths;
RENAME TABLE covidvaccinations TO covid_vaccinations;

-- EYEBALLING THE DATASET------
SELECT 
    *
FROM
    covid_deaths
ORDER BY location , date;
SELECT 
    *
FROM
    covid_vaccinations    
ORDER BY location, date;
    
-- CONVERT DATE COLUMN FROM STRING TO DATETIME IN covid_deaths TABLE------
UPDATE covid_deaths 
SET 
    date = STR_TO_DATE(date, '%d/%m/%Y');

ALTER TABLE covid_deaths
MODIFY date DATETIME;

-- CONVERT total_deaths FROM TEXT TO INT ----
UPDATE covid_deaths 
SET 
total_deaths = NULL
WHERE total_deaths = '';

ALTER TABLE covid_deaths
MODIFY total_deaths INT;

-- SELECT THE DATASET-------
SELECT 
    continent,
    location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM
    covid_deaths
ORDER BY location, date
LIMIT 20;

-- DEATH PERCENTAGE IN THE U.S
SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    (total_deaths/total_cases)*100 as death_percentage
FROM
    covid_deaths
WHERE location = 'United States'
ORDER BY location, date;

-- COVID 19 INFECTION RATE IN THE U.S
SELECT 
    location,
    date,
    total_cases,
    population,
    (total_cases/population)*100 as infection_rate
FROM
    covid_deaths
WHERE location = 'United States'
ORDER BY location, date;

-- COUNTRIES WITH HIGHEST INFECTION RATE OVER POPULATION
SELECT 
    location,
    population,
    MAX(total_cases) AS total_cases,
    MAX((total_cases / population)) * 100 AS infection_rate
FROM
    covid_deaths
WHERE continent != ''
GROUP BY location, population
ORDER BY infection_rate DESC; 

-- HIGHEST DEATH COUNTS OVER POPULATION BROKEN DOWN BY COUNTRIES
SELECT 
    location,
    MAX(total_deaths) AS total_deaths
FROM
    covid_deaths 
WHERE continent != ''
GROUP BY location
ORDER BY total_deaths DESC; 

-- HIGHEST DEATH COUNTS OVER POPULATION BROKEN DOWN BY CONTINENTS
SELECT 
    location,
    MAX(total_deaths) AS total_deaths
FROM
    covid_deaths
WHERE
    continent = ''
GROUP BY location
ORDER BY total_deaths DESC;  


-- GLOBAL DEATH COUNTS
SELECT 
    date, SUM(total_deaths)
FROM
    covid_deaths
WHERE
    continent != ''
GROUP BY date
ORDER BY date DESC ;

-- GLOBAL DEATH RATE
SELECT 
    SUM(new_cases) AS global_deaths,
    SUM(total_cases) AS global_cases,
    ROUND(((SUM(new_deaths) / SUM(new_cases)) * 100), 2) AS global_death_rate
FROM
    covid_deaths
WHERE
    continent != '';

-- VACCINATIONS TABLE--------------------------------------------------------------------------
-- CONVERT DATE COLUMN FROM STRING TO DATETIME IN covid_deaths TABLE------
UPDATE covid_vaccinations 
SET 
    date = STR_TO_DATE(date,'%d/%m/%Y');

ALTER TABLE covid_vaccinations
MODIFY date DATETIME;

-- CONVERT TEXT COLUMNS TO INT ----
UPDATE covid_vaccinations 
SET 
    total_tests = NULL
WHERE
    LENGTH(total_tests) = 0;

UPDATE covid_vaccinations 
SET 
    new_tests = NULL
WHERE
    LENGTH(new_tests) = 0;

UPDATE covid_vaccinations 
SET 
    new_vaccinations = NULL
WHERE
    LENGTH(new_vaccinations) = 0;

UPDATE covid_vaccinations 
SET 
    total_vaccinations = NULL
WHERE
    LENGTH(total_vaccinations) = 0;

ALTER TABLE covid_vaccinations
MODIFY total_tests INT,
MODIFY new_tests INT,
MODIFY new_vaccinations INT,
MODIFY total_vaccinations INT;


-- PERCENTAGE OF POPULATION WHO GOT VACCINATED
WITH vac_over_pouplation AS (
SELECT 
    d.continent,
    d.location,
    d.date,
    d.population,
    v.new_vaccinations,
    SUM(v.new_vaccinations) OVER(PARTITION BY d.location ORDER BY d.date) AS total_vaccinations
FROM
    covid_vaccinations v
        JOIN
    covid_deaths d ON d.location = v.location AND d.date = v.date
WHERE d.continent != ''
)
SELECT *, (total_vaccinations/population)*100 AS vaccination_percentage FROM vac_over_pouplation;

-- ALTERNATIVE WITH TEMP TABLE
DROP TABLE IF EXISTS temp_vac_over_pouplation;
CREATE TEMPORARY TABLE temp_vac_over_pouplation
SELECT 
    d.continent,
    d.location,
    d.date,
    d.population,
    v.new_vaccinations,
    SUM(v.new_vaccinations) OVER(PARTITION BY d.location ORDER BY d.date) AS total_vaccinations
FROM
    covid_vaccinations v
        JOIN
    covid_deaths d ON d.location = v.location AND d.date = v.date
WHERE d.continent != '';
SELECT *, (total_vaccinations/population)*100 AS vaccination_percentage FROM temp_vac_over_pouplation;

-- VISUALIZATIONS-------------------------------------------------
CREATE VIEW vaccination_percentage AS 
SELECT 
    d.continent,
    d.location,
    d.date,
    d.population,
    v.new_vaccinations,
    SUM(v.new_vaccinations) OVER(PARTITION BY d.location ORDER BY d.date) AS total_vaccinations
FROM
    covid_vaccinations v
        JOIN
    covid_deaths d ON d.location = v.location AND d.date = v.date
WHERE d.continent != '';

SELECT * FROM vaccination_percentage;

-- 1. GLOBAL DEATH PERCENTAGE:
SELECT 
    SUM(new_cases) AS global_deaths,
    SUM(total_cases) AS global_cases,
    ROUND(((SUM(new_deaths) / SUM(new_cases)) * 100), 2) AS global_death_rate
FROM
    covid_deaths
WHERE
    continent != '';
    
-- 2. CONTINENTS' TOTAL DEATHS:
SELECT 
    location,
    MAX(total_deaths) AS total_deaths
FROM
    covid_deaths
WHERE
    continent = '' AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY total_deaths DESC;  

-- 3. HIGEST INFECTION RATE BY COUNTRIES
SELECT 
    location,
    population,
    MAX(total_cases) AS total_cases,
    MAX((total_cases / population)) * 100 AS infection_rate
FROM
    covid_deaths
WHERE continent != ''
GROUP BY location, population
ORDER BY infection_rate DESC; 

-- 4. HIGHEST INFECTION RATES BY COUNTRIES (GROUP BY DATE)
SELECT 
    location,
    population,
    date,
    MAX(total_cases) AS total_cases,
    MAX((total_cases / population)) * 100 AS infection_rate
FROM
    covid_deaths
WHERE continent != ''
GROUP BY location, population, date; 
