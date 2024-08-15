# Data Cleaning Project: Layoffs Dataset

This repository contains the SQL scripts used for an exploratory data analysis (EDA) and data cleaning project on a dataset detailing company layoffs. The project is structured into several stages, focusing on data cleaning, standardization, and preparing the data for further analysis.

## Project Overview

The project consists of the following key steps:

1. **Data Backup and Staging**: Creating a staging table to preserve the original dataset.
2. **Duplicate Detection and Removal**: Identifying and removing duplicate records.
3. **Data Standardization**: Standardizing the data to ensure consistency.
4. **Handling Null and Blank Values**: Identifying and populating missing values where possible.
5. **Column Removal**: Dropping unnecessary columns to streamline the dataset.

## Steps and SQL Code

### 1. Data Backup and Staging

To ensure the safety of the raw data during transformations, a staging table `layoffs_staging` was created. This table is a duplicate of the original `layoffs` table.

```sql
CREATE TABLE layoffs_staging LIKE layoffs;

INSERT layoffs_staging
SELECT * FROM layoffs;
```

## 2. Duplicate Detection and Removal

Duplicates were identified using a `ROW_NUMBER()` function over a partition by key columns. A Common Table Expression (CTE) was used to identify and later remove these duplicates.

```sql
WITH duplicate_cte AS (
    SELECT *,
    ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
    FROM layoffs_staging
)
SELECT * FROM duplicate_cte WHERE row_num > 1;
```
Duplicates were deleted by creating a new table `layoffs_staging2` with an additional `row_num` column and removing rows where `row_num > 1`.

```sql
DELETE FROM layoffs_staging2 WHERE row_num > 1;
```

## 3. Data Standardization

Standardization involved cleaning and ensuring consistency across key columns such as `company`, `industry`, `location`, and `country`. For example, discrepancies in industry names were corrected:

```sql
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
```
Similarly, inconsistent country names were fixed:

```sql
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';
```
The date column was also standardized by converting string representations into the DATE format:
```sql
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;
```

## 4. Handling Null and Blank Values

Null and blank values were identified and populated where possible, particularly in the industry column. For instance, missing industries were filled by joining records from the same company:

```sql
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2 ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;
```

## 5. Column Removal

Columns that were either incomplete or no longer necessary were removed. For example, rows with null or blank values in the total_laid_off and percentage_laid_off columns were deleted, and the row_num column was dropped:

```sql
DELETE FROM layoffs_staging2 WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

ALTER TABLE layoffs_staging2 DROP COLUMN row_num;
```

## Conclusion

This project provided a comprehensive approach to cleaning and standardizing a dataset, preparing it for further analysis. By following best practices such as staging, duplication checks, and standardization, we ensured the data was consistent and reliable.
