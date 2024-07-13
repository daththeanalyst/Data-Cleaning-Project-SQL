-- Data Cleaning Project
-- Step 1 is to try remove any duplicated/repetitive data
-- Step 2 Standardize the data so it can be used
-- Step 3 Null Values or Blank values, to see if we can populate that
-- Step 4 Remove any columns 

-- Before we start, we make a staging table, to make sure we dont lose any important data when we transform the dataset
-- Very good practice so you can make sure you have all the raw data safe

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT*
FROM layoffs;

SELECT*
FROM layoffs_staging;

-- Firstly we want to partition by all of these columns
-- We will do a few in the beginning

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, 'date') AS row_num
FROM layoffs_staging;


-- Now we put this into a CTE, (common table expression use for temporary queries for use within the context of a larger query)
-- Before checking duplicates, make sure they are duplicates because some might be very similar looking but different
-- Change CTE to partition everything since we figured out there are many similar ones to we have to make sure by putting all the columns so we can have full image

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Do this to check the duplicated data to make sure its a duplicate
SELECT *
FROM layoffs_staging
WHERE company = 'Elemy';

-- Create new table duplicate of layoff_staging

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
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- empty columns made, and we also added extra column - row_num so we can also delete

SELECT*
FROM layoffs_staging2;

-- Add all info from layoff_staging into layoff_staging2

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- To do this succesffully you have to disable Safe Updates, to do that go to 'Edit', press 'Preferences' then go to 'SQL Editor' and go down and untick the box that says 'Safe Updates'

DELETE FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2;

-- Standardizing data
-- Now its time to Standarize the data
-- first step check for any spaces before the company name 

SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company= TRIM(company);

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- Doing this lets us find issues in industry names
-- Executing this you see that Crypto has 3 different namings

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Now we update for all of them to be 'Crypto'

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Now we look for issues at the column 'location'

SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

-- Since no problems are detected we will try a different column
-- Now we do the same for country

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- The 'United States' has two entries, one with a period at the end, to fix this we do the following
-- Trailing function removes the last letter/character of the words of a column, here we define the period as the character
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE COUNTRY LIKE 'United States%'
;

-- y gives Year with 2 digits, capital Y gives full year date

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Change data type

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Check if changes are ok

SELECT `date`
FROM layoffs_staging2;

-- Removing Null values
-- Now after removing duplicated and standardizing the data, we remove null values
-- We check where there are the null values and blank values
SELECT* 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- By running this we see that there are 4 company's with empty and null Industry,

SELECT *
from layoffs_staging2
WHERE industry IS NULL 
OR industry = '';

-- To fix this we will do the following
-- We will use Airbnb as an example

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb'; 

-- We will check companies like AIRBNB that are in the travel industry, in one row it shows it as blank,and in the other it shows the industry
-- so we will join the ones that are not blank with the blank ones

SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL	;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NOT NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- The blanks are an issue, wherever there is a null it works, but the blanks are causing the issue
-- To fix this we will make the column null then change it

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2;

-- After having done all the nulls and the blanks, we will remove any columns we dont need
-- In this case due to the incomplete nature of total_laid_off and percentage_laid_off we will delete the column
-- This is how u delete the column where there is blank and nulls together or vice versa

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- And then we will drop the row_num column because we dont need it, this is how to completely remove it
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;