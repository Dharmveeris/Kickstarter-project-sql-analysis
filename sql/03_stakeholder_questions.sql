/*
=====================================================================================================
Business questions: Answering Stakeholder questions
=====================================================================================================
Script purpose: This script aims to answer stakeholder questions.
			The questions are :
			1. Which category has the highest success percentage? How many projects have been successful?
			2. What project with a goal over $1,000 USD, had the biggest Goal Completion % (Pledged / Goal)? 
			How much money was pledged?
			3. Can you identify any trends in project success rates over the years?
			4. As an investor, what types of projects should you be looking at?

This script uses clean_kickstarter_projects_resolved view
*/

-- ==================================
-- Stakeholder questions 
-- ==================================

/*
Q1. Which category has the highest success percentage? How many projects have been successful?
Answer: 
	Dance, 65.44% (2,338 of 3,573). Overall, 133,851 of 331,462 resolved projects succeeded (40.38%)
*/

-- Category successful rate
SELECT
	category,
	SUM(CASE WHEN state = 'Successful' THEN 1 ELSE 0 END) AS successful_projects,
	COUNT(*) AS total_projects,
	ROUND(CAST(COUNT(*) AS float)/SUM(COUNT(*)) OVER() * 100, 2) AS category_share,
	ROUND(CAST(SUM(CASE WHEN state = 'Successful' THEN 1 ELSE 0 END) AS float)/ COUNT(*) * 100 , 2) AS success_per
FROM clean_kickstarter_projects_resolved
GROUP BY category
ORDER BY success_per DESC
/*
category		successful_projects		total_projects		category_share		success_per
Top 3
Dance			2338					3573				1.08				65.44
Theater			6534					10242				3.09				63.8
Comics			5842					9878				2.98				59.14

Highest share
Music			24105					45801				13.82				52.63
Film & Video	23612					56503				17.05				41.79

- 'Dance' is the most successful category having 65.44%(2338 out of 3573) success rate but its share 
is only 1% top three category are of only 1-3% project share only, maximum(About 17% to total projects)
project belong to 'Film & Video' category having success rate 41.79%(23612 out of 56503) followed by 
'Music' at 13.82% with 52.63%(24105 out of 45801) success rate.
*/


-- successful projects out of total_projects and success rate
SELECT
	SUM(CASE WHEN state = 'Successful' THEN 1 ELSE 0 END) AS successful_projects,
	COUNT(*) AS total_projects,
	ROUND(CAST(SUM(CASE WHEN state = 'Successful' THEN 1 ELSE 0 END) AS float)/COUNT(*) *100, 2) success_per
FROM clean_kickstarter_projects_resolved
-- successful_projects -> 133851	
-- total_projects -> 331462
-- success_per -> 40.38%



-- Q2. What project with a goal over $1,000 USD, had the biggest Goal Completion % (Pledged / Goal)? How much money was pledged?
-- Answer:
-- "Exploding Kittens" (Games) had the highest goal completion: $8,782,572 pledged on a $10,000 goal (87,825.72%)

-- Top 3 Projects having highest goal completion rate
SELECT --TOP 3
	name,
	category,
	ROUND(CAST(pledged AS float)/goal * 100,2) goal_completion,
	goal,
	pledged
FROM clean_kickstarter_projects_resolved
WHERE goal > 1000
ORDER BY goal_completion DESC

/*
name														category	goal_completion(%)		goal		pledged						
Exploding Kittens											Games			87825.72		10000		8782572
The World's Best TRAVEL JACKET with 15 Features || BAUBAX	Design			45960.28		20000		9192056
Fidget Cube: A Vinyl Desk Toy								Design			43104.6			15000		6465690

- "Exploding Kittens" (Games) had the highest goal completion: $8,782,572 pledged on a $10,000 goal (87,825.72%)
Followed by "The World's Best TRAVEL JACKET with 15 Features || BAUBAX" (Design): $9,192,056 pledged on a $20,000 goal(45,960.28%)
Followed by "Fidget Cube: A Vinyl Desk Toy" (Design): $6,465,690 pledged on a $15,000 goal (43,104.6%)
*/


/*
Q3. Can you identify any trends in project success rates over the years?
Answer: 
	Yearly success rate was 46 - 51% through 2013. It dropped to 32% in 2015 from there it partly 
	recovered to 43% in 2017. 
*/

-- yearly success rate 
SELECT 
	YEAR(launched) AS yr,
	COUNT(*) AS no_of_projects,
	ROUND(CAST(SUM(CASE WHEN state = 'Successful' THEN 1 ELSE 0 END) AS float)/COUNT(*)* 100,2) AS success_rate
FROM clean_kickstarter_projects_resolved
GROUP BY YEAR(launched)
ORDER BY yr
/*
yr		no_of_projects		Success_rate(%)
2009		1179				49.11
2010		9577				47.96
2011		24048				50.61
2012		38478				46.5
2013		41088				47.22
2014		59305				35.59
2015		65272				32.13
2016		49096				38.04
2017		43419				42.52

- Yearly success rate was 46 - 51% through 2013. It dropped to 32% in 2015 from there it partly 
recovered to 43% in 2017.
- "2009 is a partial year (it starts in April), and 2017 is immature (many Nov-Dec projects are 
unresolved). 2018 has two days of data, none of them resolved.
*/


/*
Q4. As an investor, what types of projects should you be looking at?
Answer: 
	Success on Kickstarter means reaching the funding goal, not earning a return, so the data can
	only show which projects had better odds of being funded. It cannot guarantee any outcome. The projects
	with the best odds had goals under about $5,000, short (0-15 days) or mid-length (31-45 days) campaigns,
	and categories like Music.


-- Variables to consider : category, goal_range, campaign_range and country.
*/

/*
category (Note: for query and table see Q1 result)

- 'Dance' is the most successful category having 65.44%(2338 out of 3573) success rate but its share 
is only 1% top three category are of only 1-3% project share only, maximum(About 17% to total projects)
project belong to 'Film & Video' category having success rate 41.79%(23612 out of 56503) followed by 
'Music' at 13.82% with 52.63%(24105 out of 45801) success rate.
*/

-- campaign range
SELECT
	campaign_range,
	SUM(CASE WHEN state = 'Successful' THEN 1 ELSE 0 END) AS successful_project,
	COUNT(*) total_project,
	ROUND(CAST(COUNT(*) AS float)/SUM(COUNT(*)) OVER() * 100 ,2) AS project_share,
	ROUND(CAST(SUM(CASE WHEN state = 'Successful' THEN 1 ELSE 0 END) AS float)/COUNT(*) * 100 ,2) AS success_per
FROM clean_kickstarter_projects_resolved
GROUP BY campaign_range
ORDER BY campaign_range
/*
campaign_range	successful_project	total_project	project_share	success_per
0-15			8693				17284			5.21			50.3
16-30			77687				193997			58.53			40.05
31-45			34195				73699			22.23			46.4
46-60			11407				41658			12.57			27.38
60+				1869				4824			1.46			38.74

- Overall, campaigns of 15 days or less had the highest success rate (50.3%, but only 5.2% of projects). 
The  overall table mixes eras: before 17 June 2011 campaigns could run up to 90 days, so the 60+ bucket is 
almost entirely early projects. Split by era, the pattern holds in both: the shortest campaigns do 
best and campaigns of 46 days or more do worst (see 04_extra_exploration.sql, A. Campaign Duration & Success). 
This is an association. Creators choose their own campaign length.
*/


-- goal_range
SELECT 
	goal_range,
	SUM(CASE WHEN state = 'Successful' THEN 1 ELSE 0 END) AS successful_project,
	COUNT(*) total_project,
	ROUND(CAST(COUNT(*) AS float)/SUM(COUNT(*)) OVER() * 100 ,2) AS project_share,
	ROUND(CAST(SUM(CASE WHEN state = 'Successful' THEN 1 ELSE 0 END) AS float)/COUNT(*) * 100 ,2) AS success_per
FROM clean_kickstarter_projects_resolved
GROUP BY goal_range
ORDER BY goal_range
/*
goal_range		successful_project	total_project	project_share	success_per
1: 0-500		15460				27597			8.33			56.02
2: 501-1K		14388				27888			8.41			51.59
3: 1K-5K		52328				112291			33.88			46.6
4: 5K-10K		23344				59165			17.85			39.46
5: 10K-50K		25333				81593			24.62			31.05
6: 50K-100K		2264				13176			3.98			17.18
7: 100K+		734					9752			2.94			7.53


- Success rate falls as the goal size increases.
- $0-500 has highest success rate of 56.02% but its share of projects in only 8.33%.
- $1k-5k has one third project share and success rate is 46.6%.
- 2.9% of projects had over $100k goal, their and success rate was 7.53%.
*/

-- Top 3 countries by success rate
SELECT TOP 3
	country,
	SUM(CASE WHEN state = 'Successful' THEN 1 ELSE 0 END) AS successful_projects,
	COUNT(*) AS no_of_projects,
	SUM(COUNT(*)) OVER() AS total_projects,
	ROUND(CAST(COUNT(*) AS float)/SUM(COUNT(*)) OVER() * 100, 2) AS percent_share,
	ROUND(CAST(SUM(CASE WHEN state = 'Successful' THEN 1 ELSE 0 END) AS float)/COUNT(*) * 100 , 2) AS success_per
FROM clean_kickstarter_projects_resolved
GROUP BY country
ORDER BY success_per DESC
/*
country			successful_projects	no_of_projects	total_projects	percent_share	success_per
Hong Kong		216					477				331462			0.14			45.28
United States	109299				261358			331462			78.85			41.82
United Kingdom	12067				29453			331462			8.89			40.97

- Hong Kong has the highest success_rate(45.28%) but only 0.14% of projects.
- United States have highest number of projects, contributing to 78.85% of all projects with success rate 41.82%
- Followed by United Kingdom with 8.89% of project_share and success rate of 40.97%  
*/


/*
==================================
Combining them all
==================================

Variables and specifics selection:
Variables that contribute the most projects were selected.
country: 'United states' and 'United kingdom' because they make up to 88% of total projects
category: 'Music',  'Film & Video' and 'Publishing' because they make 42% of total_projects
Campaign range: '16-30' and 31-45 contribute 81% of total projects
goal range : '3: 1K-5K', '4: 5K-10K' and '5: 10K-50K' make 76% of total_projects

Conditions:
-- Every segment should have more than 1000 projects. 
*/

-- Top 10 success rate results, considering all variables.
SELECT Top 10
	country,
	category,
	campaign_range,
	goal_range,
	SUM(CASE WHEN state = 'Successful' THEN 1 ELSE 0 END) AS successful_project,
	COUNT(*) total_project,
	ROUND(CAST(SUM(CASE WHEN state = 'Successful' THEN 1 ELSE 0 END) AS float)/COUNT(*) * 100 ,2) AS success_per
FROM clean_kickstarter_projects_resolved
WHERE 
	country IN('United States', 'United Kingdom') AND 
	category IN('Film & Video', 'Music', 'Publishing') AND 
	goal_range IN ('3: 1K-5K', '4: 5K-10K', '5: 10K-50K') AND 
	campaign_range IN('16-30', '31-45') 
GROUP BY 
	country,
	category,
	campaign_range,
	goal_range
HAVING COUNT(*) > 1000
ORDER BY success_per DESC
/*
Country				category	 campaign_range		goal_range		successful_projects		total_projects		success_per(%)
United States		 Music			31-45			 3: 1K-5K				2752				 4364				63.06
United States		 Music			31-45			 4: 5K-10K				1304		 	 	 2156				60.48
United States		 Music			16-30			 3: 1K-5K				5800		 		 9901				58.58
United States		 Music			16-30		     4: 5K-10K				2361		 	  	 4260				55.42
United Kingdom		 Film & Video	16-30			 3: 1K-5K				584					 1094				53.38
United States		 Film & Video	31-45			 3: 1K-5K				1614			  	 3032				53.23
United States		 Film & Video	16-30			 3: 1K-5K				4596				 8757				52.48
United States		 Music			31-45			 5: 10K-50K				930					 1795				51.81
United States		 Film & Video	31-45			 4: 5K-10K				962					 2008				47.91
United States		 Film & Video	16-30			 4: 5K-10K				2192				 4760				46.05


Findings:
	- Music takes four of the top five segments, all in the US.
	- Within Music, 31-45 days beats 16-30 days at the same goal size (63.1% vs 58.6% at $1K-5K, 60.5% vs 55.4% at $5K-10K).
	- Within Music at 31-45 days, the smaller goal band does better (63.1% vs 60.5%).
	- At the same length and goal size, Music beats Film & Video (63.1% vs 53.2%).

Interpretation:
	- Among the largest segments United States Music with 31-45 days and goal 1k-5k did best(63.1%).

Limitations:
	- The variables were chosen because they are the largest groups, so smaller categories like Dance and 
	Theater are excluded by design.
	- These are associations, because creators choose their own goals and lengths. The results describe 
	past projects. And the 1,000-project minimum is a judgment call.
	- Rates pool all years, and 2014-2016 behave differently.
*/	 
