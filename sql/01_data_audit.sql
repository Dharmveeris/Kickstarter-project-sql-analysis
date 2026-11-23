/*
=================================================================================
Data Audit: Data Quality and Features check
=================================================================================
Script purpose: 
	This script performs the following functions.
	- Listing data type for columns and check whether all rows are loaded.
	- Checks for data quality issues and inconsistency in data logic, namely it does:
		- Check for null values
		- Duplicates,
		- Extra spaces in text columns
		- Distinct country, category, subcategory and state values 
		- Earliest and last date for dataset
		- Look for inconsistency in data logic(such as successful_yet_failed projects)

This script uses the original table from source, kickstarter_projects
*/

 
-------------------------------- Data insertion --------------------------------
/*
Inserted the data using flat file insert option.
*/
-- 1. Column names and data type
SELECT 
	COLUMN_NAME,
	DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'kickstarter_projects'

-- Column_names		Data_Type
-- ID				int
-- Name				nvarchar
-- Category			nvarchar
-- Subcategory		nvarchar
-- Country			nvarchar
-- Launched			datetime2
-- Deadline			datetime2
-- Goal				int
-- Pledged			int
-- Backers			int
-- State			nvarchar


-- 2.  Total rows are 
SELECT COUNT(*)
FROM dbo.kickstarter_projects
-- All rows are loaded
-- There are 374853 rows


---------------------- Data Quality and Features check ----------------------

-- 1. Checking for NULLs
SELECT *
FROM kickstarter_projects AS p
WHERE 
	p.ID IS NULL OR
	p.Name IS NULL OR
	p.Category IS NULL OR 
	p.Subcategory IS NULL OR 
	p.Launched IS NULL OR
	p.Deadline IS NULL OR
	p.Pledged IS NULL OR 
	p.Goal IS NULL OR 
	p.State IS NULL OR 
	p.Backers IS NULL OR 
	p.Country IS NULL 
-- No nulls found 


-- 2. Checking duplicates
SELECT ID, COUNT(*) AS rep
FROM kickstarter_projects
GROUP BY ID
HAVING COUNT(*) > 1
-- No duplicates found


-- 3. Inconsistency in name column
SELECT 
	Name,
	LEN(NAME),
	TRIM(NAME),
	LEN(TRIM(NAME))
FROM kickstarter_projects
WHERE Name != TRIM(Name)
-- Extra spaces are found, column will be trimmed 


-- 4. Categories are  
SELECT DISTINCT Category
FROM kickstarter_projects
-- 15 categories
-- Dance, Film & Video, Fashion, Food, Photography, Art, Theater, Crafts, Journalism,
-- Comics, Games, Publishing, Design, Music, Technology


-- 5. Subcategories are  
SELECT DISTINCT Subcategory
FROM kickstarter_projects
ORDER BY Subcategory
-- There are 159 subcategories.


-- 6. Inconsistency in Subcategory
SELECT DISTINCT 
	Subcategory,
	DATALENGTH(Subcategory), 
	DATALENGTH(TRIM(Subcategory)), 
	TRIM(Subcategory)
FROM kickstarter_projects
WHERE 
	DATALENGTH(Subcategory) != DATALENGTH(TRIM(Subcategory))
-- No empty spaces found


-- 7. Different countries are
SELECT DISTINCT Country
FROM kickstarter_projects
ORDER BY Country
-- There are 22 countries
-- Australia, Austria, Belgium, Canada, Denmark, France, Germany, Hong Kong, Ireland, Italy, Japan, Luxembourg,
-- Mexico, Netherlands , New Zealand, Norway, Singapore, Spain, Sweden, Switzerland, United Kingdom, United States

-- # Note : DATALENGTH()
-- Simply comparing TRIM() value doesn't catch trailing spaces 
SELECT DISTINCT
	Country
FROM kickstarter_projects
WHERE Country != trim(Country)
-- Gives us no result

-- Using DATALENGTH() we can catch them
SELECT DISTINCT
	Country
FROM kickstarter_projects
WHERE DATALENGTH(Country) != DATALENGTH(TRIM(Country))
-- We have a result

-- trailing spaces can't be found with comparing 'Netherlands' = 'Netherlands '
-- both are equal for sql, even LEN() cannot count the trailing space thus always check with DATALENGTH()
-- and trim all text columns in data cleaning.

-- Text columns with leading/trailing spaces (count of affected rows)
SELECT
    SUM(CASE WHEN DATALENGTH(Name)        <> DATALENGTH(TRIM(Name))        THEN 1 ELSE 0 END) AS name_untrimmed,
    SUM(CASE WHEN DATALENGTH(Category)    <> DATALENGTH(TRIM(Category))    THEN 1 ELSE 0 END) AS category_untrimmed,
    SUM(CASE WHEN DATALENGTH(Subcategory) <> DATALENGTH(TRIM(Subcategory)) THEN 1 ELSE 0 END) AS subcategory_untrimmed,
    SUM(CASE WHEN DATALENGTH(Country)     <> DATALENGTH(TRIM(Country))     THEN 1 ELSE 0 END) AS country_untrimmed,
    SUM(CASE WHEN DATALENGTH(State)       <> DATALENGTH(TRIM(State))       THEN 1 ELSE 0 END) AS state_untrimmed
FROM dbo.kickstarter_projects;
-- name_untrimmed - 1073, category_untrimmed - 0, subcategory_untrimmed - 0, 
-- country_untrimmed - 2868, state_untrimmed - 0
-- name and country column needs trimming


-- 8. Launched and deadline 
SELECT Launched, Deadline
FROM kickstarter_projects
-- Both are datetime2.
-- For this project only date data will suffice thus need to convert them.


-- 9. Inconsistency with launched and deadline data.
SELECT *
FROM kickstarter_projects
WHERE Deadline < Launched
-- No inconsistency found.


-- 10. Data Time period
SELECT
	MIN(Launched) AS first_launched,
	MAX(Launched) AS last_launched,	
	MIN(Deadline) AS first_deadline,
	MAX(Deadline) AS last_deadline
FROM kickstarter_projects
-- Data time period is from april 2009 to 2 january 2018


-- 11. Confirming currency unit
-- Calculating median for each country to check whether goals are converted to USD currency or not
SELECT DISTINCT
    country,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY goal)
        OVER (PARTITION BY country) AS median_goal,
    COUNT(*) OVER (PARTITION BY country) AS projects
FROM kickstarter_projects
ORDER BY median_goal DESC;
-- Currency is not documented in the source. Median goals by country fall in a narrow band
-- ($3k to $15k), which is inconsistent with unconverted local currencies. Goals are treated 
-- as USD. This is an assumption supported by evidence.


-- 12. Goal, Pledged and Backers Inconsistency
SELECT 
	SUM(CASE WHEN Goal < 0 THEN 1 ELSE 0 END) AS negative_goal,
	SUM(CASE WHEN Pledged < 0 THEN 1 ELSE 0 END) AS negative_pledged,
	SUM(CASE WHEN Backers < 0 THEN 1 ELSE 0 END) AS negative_backers,
	SUM(CASE WHEN Goal = 0 THEN 1 ELSE 0 END) AS Zero_goal,
	SUM(CASE WHEN Pledged = 0 THEN 1 ELSE 0 END) AS Zero_pledged,
	SUM(CASE WHEN Backers = 0 THEN 1 ELSE 0 END) AS Zero_backers,
	SUM(CASE WHEN Pledged != 0 AND Backers = 0 THEN 1 ELSE 0 END) AS pledged_without_backers,
	SUM(CASE WHEN Pledged >= Goal AND State = 'Failed' THEN 1 ELSE 0 END) AS successful_yet_failed,
	SUM(CASE WHEN Pledged < Goal AND State = 'Successful' THEN 1 ELSE 0 END) AS failed_yet_successful
FROM kickstarter_projects
-- No negative values in goal, pledged or backers.
-- Zero pledged projects are 51810 and projects with zero backers are 51804.
	-- There are 9 backers who didn't pledge at all
-- There are 4 goals with zero.
-- Inconsistency exists. There exists data where we have pledged_without_backers,
	-- successful_yet_failed, failed_yet_successful however it's negligible. 


-- Inconsistent data 
SELECT
	CASE WHEN Pledged >= Goal AND State = 'Failed' THEN 'successful_yet_failed' END AS problem,
	Goal,
	Pledged,
	Backers,
	State
FROM kickstarter_projects
WHERE 
	Pledged >= Goal AND State = 'Failed' 
-- successful_yet_failed - 10

UNION ALL

SELECT
	CASE WHEN Pledged < Goal AND State = 'Successful' THEN 'failed_yet_successful' END AS problem,
	Goal,
	Pledged,
	Backers,
	State
FROM kickstarter_projects
WHERE 
	Pledged < Goal AND State = 'Successful' 
-- failed_yet_successful - 2

UNION ALL

SELECT
	CASE WHEN Pledged != 0 AND Backers = 0 THEN 'pledged_without_backers' END AS problem,
	Goal,
	Pledged,
	Backers,
	State
FROM kickstarter_projects
WHERE Pledged != 0 AND Backers = 0 
-- pledged_without_backers - 3
-- This query lists the data containing goal, pledged, backers, state with the inconsistency name


-- 13. DISTINCT States of project
SELECT State, COUNT(*)  AS no_of_projects
FROM kickstarter_projects
GROUP BY State
-- There are 5 states namely Failed, Successful, Live, Canceled, Suspended.
-- To find success rate we will consider only failed and successful projects as we don't have the 
-- exact reason why projects were cancelled or suspended and live ones haven't resulted in either one yet.

-- State		no_of_projects
-- Failed		197611
-- Successful	133851
-- Live			2798
-- Canceled		38751
-- Suspended	1842

-- Resolved_projects -> Failed and Successful
-- Unserolved_projects -> Live, Canceled and Suspended

-- 14. Unresolved projects at the time period end.
-- Month wise projects.
SELECT
	YEAR(Launched) AS [yr],
	MONTH(Launched) AS [month] ,
	COUNT(*) AS no_of_projects
FROM kickstarter_projects
WHERE State = 'live'
GROUP BY 
	YEAR(Launched),
	MONTH(Launched)
ORDER BY 
	yr,
	month
-- 2017 November & December, those months have the most live projects, so they are immature.
-- yr		month	no_of_projects
-- 2016		7		1
-- 2017		1		1
-- 2017		3		1
-- 2017		7		1
-- 2017		10		1
-- 2017		11		534
-- 2017		12		2137
-- 2018		1		122

-- 15. Project number in raw data vs resolved data
SELECT
	'Total_projects' AS project_data,
	COUNT(*) AS no_of_projects
FROM kickstarter_projects
UNION ALL 
SELECT
	'Total_resolved_projects',
	COUNT(*) AS no_of_projects
FROM kickstarter_projects
WHERE State IN ('Successful', 'Failed')

-- Total projects -> 374853
-- Total resolved projects -> 331462
-- Total unresolved projects -> 43391

-- 16. Over all success rate
SELECT
	ROUND(CAST(SUM(CASE WHEN State = 'Successful' THEN 1 ELSE 0 END) AS float)/COUNT(*) * 100,2) AS Success_rate
FROM kickstarter_projects
WHERE State IN ('Successful', 'Failed')
-- Average success rate is 40.38%


-- Decisions:
	-- Raw data is loaded in 'kickstarter_projects', considering all checks we will make two views.
	-- 'clean_kickstarter_projects' having the cleaned data containing all rows
	-- 'clean_kickstarter_projects_resolved' containing only resolved projects; failed 
	-- and successful projects as we don't have the exact reason why projects were 
	-- cancelled or suspended and live ones haven't resulted in either one yet.
	
