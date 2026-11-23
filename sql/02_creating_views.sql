/*
================================================================================
Creating views: clean_kickstarter_projects, clean_kickstarter_projects_resolved
================================================================================
Script purpose: This script creates a cleaned view of the raw table and a
				second view limited to resolved projects.
				- kickstarter_projects -> clean_kickstarter_projects
				- clean_kickstarter_projects -> clean_kickstarter_projects_resolved

Where 'kickstarter_projects' contains raw and uncleaned data after cleaning, 
it is loaded into 'clean_kickstarter_projects'. 
Our analysis is done on resolved(successful and failed) projects mostly, for 
that we will create a view for resolved projects only
*/

-- Creating clean_kickstarter_projects view from kickstarter_projects
CREATE OR ALTER VIEW clean_kickstarter_projects AS 
SELECT
	ID AS id,
	TRIM(Name) AS name,
	Category AS category,
	Subcategory AS subcategory,
	TRIM(Country) AS country,
	CAST(Launched AS date) AS launched,
	CAST(Deadline AS date) AS deadline,
	DATEDIFF(DAY,Launched,Deadline) AS campaign_days,
	CASE 
	WHEN DATEDIFF(DAY,Launched,Deadline) <= 15 THEN '0-15' 
	WHEN DATEDIFF(DAY,Launched,Deadline) <= 30 THEN '16-30'
	WHEN DATEDIFF(DAY,Launched,Deadline) <= 45 THEN '31-45'
	WHEN DATEDIFF(DAY,Launched,Deadline) <= 60 THEN '46-60'
	WHEN DATEDIFF(DAY,Launched,Deadline) > 60 THEN '60+'
	END AS campaign_range,
	CAST(Goal AS bigint) AS goal,
	CASE 
	WHEN goal <= 500 THEN '1: 0-500'
	WHEN goal <= 1000 THEN '2: 501-1K'
	WHEN goal <= 5000 THEN '3: 1K-5K'
	WHEN goal <= 10000 THEN '4: 5K-10K'
	WHEN goal <= 50000 THEN '5: 10K-50K'
	WHEN goal <= 100000 THEN '6: 50K-100K'
	ELSE '7: 100K+'
	END AS goal_range,
	CAST(Pledged AS bigint) AS pledged,
	Backers AS backers,
	State AS state
FROM kickstarter_projects;
GO
/*
-- inconsistent text columns are trimmed
-- launched and deadline columns are cast to date from datetime2  
-- campaign days are calculated from launched to deadline date
-- campaign days are categorized into 15 days time interval such as 0-15 where 15 is included here
	-- campaign range are 0-15,16-30,31-45,46-60 and 60+ 
-- goal and pledged are cast to bigint from int
-- goal are categorized into range such as 1k-5k where lower end is exclusive and high end is 
inclusive(except 0-500 range where both are inclusive). Such as  exactly 1000 falls in '2: 501-1k'
and '3: 1k-5k' has 1001-5000 value. 
	-- ranges are '1: 0-500', '2: 501-1K', '3: 1K-5K', '4: 5K-10K', '5: 10K-50K', '6: 50K-100K', '7: 100K+'
	-- the initial number are '1:' is to keep the ranges in order
*/

-- Creating clean_kickstarter_projects_resolved view from clean_kickstarter_projects
CREATE OR ALTER VIEW clean_kickstarter_projects_resolved AS 
SELECT
	id,
	name,
	category,
	subcategory,
	country,
	launched,
	deadline,
	campaign_days,
	campaign_range,
	goal,
	goal_range,
	pledged,
	backers,
	state
FROM clean_kickstarter_projects
WHERE state IN ('Failed','Successful'); 
GO
-- 15 rows across three checks show inconsistencies in success logic. They are retained, and 
-- State is treated as the source of truth.
 


-- Validation
SELECT COUNT(*) FROM clean_kickstarter_projects;
-- Rows in clean_kickstarter_projects: 374,853 (matches raw table)

SELECT COUNT(*) FROM clean_kickstarter_projects_resolved;
-- Rows in clean_kickstarter_projects_resolved: 331,462 (see audit section 15)

SELECT campaign_range, COUNT(*) FROM clean_kickstarter_projects GROUP BY campaign_range ORDER BY campaign_range;
-- campaign_range counts: 0-15: 18,738 | 16-30: 217,434 | 31-45: 84,043 | 46-60: 49,171 | 60+: 5,467 (no NULL group)
