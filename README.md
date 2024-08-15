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

