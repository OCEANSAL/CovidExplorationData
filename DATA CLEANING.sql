-- SQL Project - Data Cleaning ( Alex_the_analyst inspo)

-- https://www.kaggle.com/datasets/swaptr/layoffs-2022

SELECT *
FROM layoffs;

-- We create a staging table to clean our data, leaving the raw data table intact if something happens

CREATE TABLE layoffs_staging
LIKE layoffs;

-- insert layoffs_staging 
INSERT layoffs_staging
SELECT * 
FROM layoffs;


-- We can start cleaning our data by following these steps :
-- 1. identify duplicates and remove them
-- 2. check the different anomalies and standarize data
-- 3. check the null values
-- 4. remove unnecessary columns and rows


-- Let's remove duplicates 

-- Identify duplicates 
SELECT *,
ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) AS Index1
FROM layoffs_staging;


-- Making a CTE table of duplicates 

With duplicates AS (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) AS Index1
FROM layoffs_staging
)

Select *
from duplicates
WHERE Index1 <> 1;

-- Let's check 'Yahoo' to confirm

SELECT *
FROM layoffs_staging
WHERE company = 'Yahoo';

-- yuy all good

-- To delete these duplicates, we'll create a new column and add those row numbers in. Then delete where row numbers are over 2, then delete that column
ALTER TABLE layoffs_staging 
ADD COLUMN row_num int;

SELECT *
FROM layoffs_staging;


CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, 'date', stage, country, funds_raised_millions) 
FROM layoffs_staging;

-- now we can delete the duplicated rows
DELETE
FROM layoffs_staging2 
where row_num <> 1;


-- 2. Standarize data

SELECT * 
FROM layoffs_staging2;

-- Let's have a better display for company
UPDATE layoffs_staging2
SET company = trim(company);

-- Let's check industry

SELECT distinct(industry)
FROM layoffs_staging2
order by industry;

-- I noticed Crypto has multiple variations, let's standarize it
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE '%crypto%';

-- All seems good, except a trailing '.' in United States, let's fix it
-- We can use our former solution

UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE '%States%';

-- Or use :
SELECT distinct(country), trim(trailing '.' FROM country)
FROM layoffs_staging2
order by 1;


-- The date column is stored as text, needs fixing
-- Let's use str_to_date function to do the format update first

select distinct(date) , str_to_date(date, '%m/%d/%y')	
from layoffs_staging2;

UPDATE layoffs_staging2
set date = str_to_date(date, '%m/%d/%Y') ;

-- Let's convert the date type to DATE
ALTER TABLE layoffs_staging2
MODIFY COLUMN date DATE;

SELECT*
FROM layoffs_staging2;


-- 3. Looking at Null Values, null values in total_laid_off, percentage_laid_off, and funds_raised_millions all look normal. I don't think I want to change that
-- I like having them null because it makes it easier for calculations during the EDA phase

-- Let's check null values in industry 

select * 
FROM layoffs_staging2
WHERE industry is Null 
OR industry = '';

-- first, I will update blanks to nulls

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Let's take a look at the company 'Airbnb'

SELECT *
FROM layoffs_staging
WHERE company LIKE 'airbnb%' ;

-- It looks like airbnb is a travel, but there are some rows that just aren't populated
-- to fix this, we need a query that can take the industry on an another row if it's the same company
-- I'll be using a join query 

-- Now those are all null
SELECT *
FROM layoffs_staging2 T1
JOIN layoffs_staging2 T2 
	ON T1.company = T2.company
    AND T1.location = T2.location
WHERE T1.industry is NULL 
AND T2.industry is not null 
;

-- Let's populate them
UPDATE layoffs_staging2 T1
JOIN layoffs_staging2 T2 
	ON T1.company = T2.company
    AND T1.location = T2.location
    SET T1.industry = T2.industry
WHERE T1.industry is NULL 
AND T2.industry is not null 
;

-- and if we check it looks like Bally's was the only one without a populated row to populate this null values because it has only one row 
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
ORDER BY industry;


-- 4. remove unnecessary columns and rows 

SELECT *
from layoffs_staging2
WHERE total_laid_off is null
AND percentage_laid_off is null;

-- these rows don't seem really useful because we don't have layoffs information so let's delete them

DELETE 
FROM layoffs_staging2
WHERE total_laid_off is null
AND percentage_laid_off is null
;

-- We also need to drop our row_num column as we don't need it anymore

alter table layoffs_staging2
drop column row_num;


-- Our dataset is clean now and ready to explore

SELECT * 
FROM layoffs_staging2
;