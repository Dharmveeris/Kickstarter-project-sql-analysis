/*
==================================================================================================
Extra exploration: Analysing beyond stakeholder questions to better understand the data 
==================================================================================================
Script purpose: This script aims to enrich our understanding of the data by asking more detailed 
				questions about data.
				It consists of following sections:
				- A. Campaign Duration & Success
				- B. Geographic expansion
				- C. Pledging behaviour: pledged-to-goal, pledged per backer, amount share
				- D. Investigating the 2014 decline 
					- D1. Monthly performance in 2014 
					- D2. July 2013 vs July 2014: Category comparison
					- D3. Investigating zero-pledged projects
						- D3.1 Historical anuual zero pledged rate(2009-2017)
						- D3.2 Monthly zero pledged rate in 2014.

This script uses clean_kickstarter_projects and clean_kickstarter_projects_resolved view
*/

/*
===========================================
A. Campaign Duration & Success
===========================================

-- Kickstarter initially had campaign running up to 90 days this changed to a 60 days  maximum on 
-- 17 June 2011. More can be read about here [https://www.kickstarter.com/blog/shortening-the-maximum-project-length] 
-- So there are two eras

Question: 
	-- Does campaign duration have any relation with success rate.
	-- Finding if there's any difference between two eras success rate.
	 
*/
-- A.1 successrate for different campaign length
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
campaign_range		successful_project		total_project		project_share		success_per
0-15					8693					17284				5.21				50.3
16-30					77687					193997				58.53				40.05
31-45					34195					73699				22.23				46.4
46-60					11407					41658				12.57				27.38
60+						1869					4824				1.46				38.74
*/
-- Findings:
	-- 0-15 Days have maximum success rate 50.3% but it's project share is only 5.21%
	-- 16-30 has maximum project share at 58.53% and successrate 40.05%
	-- success rate decreases for 46-60 range but campaign going over 2 months had more success rate. 
		-- This reverses within each era.


-- A.2 Before and after rule success rate for campaign lengths

SELECT
	campaign_range,
	MAX(CASE WHEN era = 'before rule' THEN success_per END) AS [before rule],
	MAX(CASE WHEN era = 'after rule' THEN success_per END) AS [after rule]
FROM(
	SELECT
		CASE WHEN launched < '2011-06-17' THEN 'before rule' ELSE 'after rule' END AS era,
		campaign_range,
		ROUND(CAST(SUM(CASE WHEN state = 'Successful' THEN 1 ELSE 0 END) AS FLOAT)/ COUNT(*) * 100, 2) AS success_per
	FROM clean_kickstarter_projects_resolved
	GROUP BY CASE WHEN launched < '2011-06-17' THEN 'before rule' ELSE 'after rule' END, campaign_range
	) t
GROUP BY campaign_range
ORDER BY campaign_range 
/*
Comparison of success rate before and after rule.
campaign_range		before_rule(%)		after_rule(%)
	0-15				63.48				49.77
	16-30				53.78				39.58
	31-45				54.92				45.68
	46-60				46.79				25.55
	60+					39.16				23.85
*/

-- no of projects in different eras
SELECT
	SUM(CASE WHEN Launched < '2011-06-17' AND campaign_days > 60 THEN 1 ELSE 0 END)AS before_rule,
	SUM(CASE WHEN Launched >= '2011-06-17' AND campaign_days > 60 THEN 1 ELSE 0 END)AS after_rule
FROM clean_kickstarter_projects_resolved
-- before_rule -> 4694, after_rule -> 130

-- Findings:
	-- 0-15 days has the highest success rate in both eras (63.48% before the rule, 49.77% after).
	-- 46-60 days is among the lowest in both (46.79% before, 25.55% after).
	-- 31-45 days beats 16-30 days in both eras (54.92% vs 53.78%, then 45.68% vs 39.58%).
	-- 60+ is lowest in the early era (39.16%). After the rule it has only 130 projects.
		
-- #Note: After rule 130 projects having campaign length over 60 days are anomalies and are discussed in the data audit.

-- Interpretation:
	-- The relation between campaign duration and  success is not linear
	-- short campaign have highest success rate, long campaign have least and medium are mixed.

-- Limitations:
	-- These results show association, not causation

/*
======================================
B. Geographic expansion
======================================

Question:
	How are the projects distributed across countries, and when did each country start launching projects.

*/
SELECT 
	country,
	SUM(CASE WHEN YEAR(launched) = 2009 THEN 1 ELSE 0 END) AS [2009],
	SUM(CASE WHEN YEAR(launched) = 2010 THEN 1 ELSE 0 END) AS [2010],
	SUM(CASE WHEN YEAR(launched) = 2011 THEN 1 ELSE 0 END) AS [2011],
	SUM(CASE WHEN YEAR(launched) = 2012 THEN 1 ELSE 0 END) AS [2012],
	SUM(CASE WHEN YEAR(launched) = 2013 THEN 1 ELSE 0 END) AS [2013],
	SUM(CASE WHEN YEAR(launched) = 2014 THEN 1 ELSE 0 END) AS [2014],
	SUM(CASE WHEN YEAR(launched) = 2015 THEN 1 ELSE 0 END) AS [2015],
	SUM(CASE WHEN YEAR(launched) = 2016 THEN 1 ELSE 0 END) AS [2016],
	SUM(CASE WHEN YEAR(launched) = 2017 THEN 1 ELSE 0 END) AS [2017],
	ROUND(CAST(COUNT(*)AS float)/(SELECT COUNT(*) FROM clean_kickstarter_projects) * 100,2) AS country_share
FROM clean_kickstarter_projects
GROUP BY country
ORDER BY country_share DESC
/*
Country			2009	2010	2011	2012	 2013	2014	2015	2016	2017	country_share(%)
United States	1329	10519	26236	40546	38687	50769	53543	38029	32878	78.06
United Kingdom	0		0		0		615		5013	8154	7999	6017	5856	8.98
Canada			0		0		0		0		876		4201	4191	2894	2588	3.94
Australia		0		0		0		0		197		2257	2277	1598	1504	2.09
Germany			0		0		0		0		0		0		1345	1426	1398	1.11
France			0		0		0		0		0		0		888		1071	979		0.78
Italy			0		0		0		0		0		0		705		1110	1062	0.77
Netherlands		0		0		0		0		0		787		965		547		569		0.77
Spain			0		0		0		0		0		0		552		883		840		0.61
Mexico			0		0		0		0		0		0		0		290		1460	0.47
Sweden			0		0		0		0		0		168		614		515		458		0.47
New Zealand		0		0		0		0		63		390		394		303		297		0.39
Denmark			0		0		0		0		0		117		404		320		272		0.3
Ireland			0		0		0		0		0		75		276		234		226		0.22
Switzerland		0		0		0		0		0		0		167		318		275		0.2
Norway			0		0		0		0		0		75		260		207		166		0.19
Belgium			0		0		0		0		0		0		159		251		207		0.16
Hong Kong		0		0		0		0		0		0		0		130		488		0.16
Austria			0		0		0		0		0		0		165		227		205		0.16
Singapore		0		0		0		0		0		0		0		140		412		0.15
Luxembourg		0		0		0		0		0		0		15		26		21		0.02
Japan			0		0		0		0		0		0		0		0		39		0.01
*/
-- Findings:
	-- United States was the only country launching projects in 2009-2011.
	-- United Kingdom joined from 2012.
	-- Canada, Australia and New Zealand joined from 2013.
	-- Several others joined in the following years.
	-- Japan joined at last in 2017.
	-- The United States accounts for 78% of projects, United Kingdom 8.9% and Canada 3.9% together
		-- these three make 91% of total projects.

-- Interpretation:
	-- Expansion of geographical participation does not necessarily indicate equal activity on platform.
		-- United States continues to dominate through the observed period.

-- Limitation:
	-- The data does not show when each country was added to the platform, only when it first appears.
	-- A zero in an early year means the country was not yet launching projects on the platform, not that it 
		-- had no interest. The data holds project counts only, not backers' locations.


/*
============================================================
C.Pledging behaviour: how much money do projects attract?
============================================================

Questions: Beyond success rate, how much money raised against projects,
how much each backer gives, and which categories raise most money.

Appraoch: pledged_to_goal = total_pledged/total_goal
*/

-- Pledged to goal rate for resolved projects
SELECT TOP 3
	category,
	ROUND(CAST(SUM(pledged) AS float)/SUM(goal) *  100,2) AS pledged_rate
FROM clean_kickstarter_projects_resolved
GROUP BY category
ORDER BY pledged_rate DESC
/*
category	pledged_rate(%)
Design			72.72
Games			64.38
Dance			43.36
*/
-- Design -> 72.72%, Games -> 64.38%, and Dance -> 43.36%.

-- Pledged to goal rate for failed project
SELECT TOP 3
	category,
	ROUND(CAST(SUM(pledged) AS float)/SUM(goal) *  100,2) AS pledged_rate
FROM clean_kickstarter_projects_resolved
WHERE state = 'Failed'
GROUP BY category
ORDER BY pledged_rate
/*
category		pledged_rate(%)
Journalism			0.61
Art					0.92
Film & Video		1.24
*/
-- top three most under pledged categories are Journalism at 0.61%, Art at 0.92%, Film & Video at 1.24%


-- Pledged to goal rate yearly analysis
SELECT
	YEAR(launched) yr,
	ROUND(CAST(SUM(pledged) AS float)/SUM(goal) *  100,2) AS pledged_rate
FROM clean_kickstarter_projects_resolved
GROUP BY YEAR(launched)
ORDER BY yr
/*
yr		pledged_rate(%)
2009		34.94
2010		22.92
2011		43.81
2012		46.17
2013		45.4
2014		17.78%
2015		14.35
2016		24.32
2017		34.72
-- 2014 and 2015 have the lowest pledged to goal amount indicating the anomaly of success dip there.
*/

-- Pledged per backer
SELECT 
	category,
	ROUND(CAST(SUM(pledged) AS float)/SUM(backers),2) AS pledged_per_backer
FROM clean_kickstarter_projects_resolved
WHERE state = 'Successful'
GROUP BY category
ORDER BY pledged_per_backer DESC
/*
category		pledged_per_backer()
Technology			129.11
Design				102.24
Food				96.09
Fashion				93.49
Photography			92.98
Film & Video		91.44
Theater				84.72
Dance				81.93
Art					77.16
Music				71.64
Journalism			67.92
Games				66.59
Crafts				59.8
Publishing			59.42
Comics				49.2
*/
-- Technology ranks first in the most amount pledged per backer followed by Design then Food
-- Technology -> $129.11, Design -> $102.24, Food -> $96.09


-- Share of all money pledged to successful projects, by category. 
SELECT
	category,
	ROUND(CAST(SUM(pledged) AS float)/SUM(SUM(pledged)) OVER() * 100, 2) amount_share
FROM clean_kickstarter_projects_resolved
WHERE state = 'Successful'
GROUP BY category
ORDER BY amount_share DESC
/*
category		amount_share(%)
Games				22.38
Design				21.86
Technology			19.65
Film & Video		10.86
Music				5.84
Publishing			3.83
Fashion				3.74
Food				3.48
Art					2.65
Comics				2.19
Theater				1.29
Photography			1.1
Dance				0.4
Crafts				0.39
Journalism			0.35
*/
-- Game -> 22.38%, Design -> 21.86% and Technology -> 19.65%, these three category have 64% of 
-- total money ever funded from 2009 to 2017

-- Category share for projects
SELECT
	category,
	ROUND(CAST(COUNT(id) AS FLOAT)/SUM(COUNT(id)) OVER() * 100,2) AS project_share
FROM clean_kickstarter_projects_resolved
GROUP BY category
/*
category		project_share
Dance				1.08
Film & Video		17.05
Fashion				5.97
Food				6.65
Photography			2.92
Art					7.74
Theater				3.09
Crafts				2.36
Journalism			1.25
Comics				2.98
Games				8.6
Publishing			10.68
Design				7.65
Music				13.82
Technology			8.16
*/
-- Game -> 8.6%, Design -> 7.65%, Technology -> 8.16%, project share of total is 24.4%

/*
Findings:
	- Pledged to goal : Design -> 72.72%, Games -> 64.38%, and Dance -> 43.36%.
	- Failed projects in Journalism(0.61%), Art(0.92%) and Film & Video(1.24%) got the least pledged 
		against their goal.
	- Yearly pledged rate dropped from 45.4% in 2013 to 17.78% in 2014 and 14.35% in 2015.
	- Technology at $129.11 got the highest pledged per backer, Comics at $49.2 got the least.
	- Game(22.38%), Design(21.86%) and Technology(19.65%) make up 64% of total funding ever processed 
		and in projects share make up only 24.45% .

Interpretation:
	- Success rate and money do not move together, Dance has the highest success rate but has only 0.4%
		of money share, while Games(22.38%), Design(21.86%) and Technology(19.65%) have 65% of money share.
	- 2014 and 2015 decline follows up with pledged rate, suggests the successrate drop might be 
		connected to not enough funding in those years
	- Games, Design, and Technology constitute only about a quarter of projects but hold 64% of total funding.

Limitations:
	- Ratios are dollar weighted, where few projects can dominate the category.
	- Per backer and amount_share considers only successful projects.
*/

/* 
==============================================================================
D. Investigating the 2014 decline 
==============================================================================

=============================================
D1 : Monthly performance in 2014 
=============================================

Business question:
How did the success rate change throughout 2014, and when did the sharpest decline occurred?

Approach:
Comparing monthly successrate and projects volume to identify significant changes during the year 
*/
SELECT	
	MONTH(launched) AS [month],
	SUM(CASE WHEN state = 'Successful' THEN 1 ELSE 0 END) AS successful_projects,
	COUNT(*) AS total_projects,
	ROUND(CAST(SUM(CASE WHEN state = 'Successful' THEN 1 ELSE 0 END) AS float)/COUNT(*) * 100 ,2) AS success_per
FROM clean_kickstarter_projects_resolved
WHERE YEAR(launched) = 2014
GROUP BY MONTH(launched)
ORDER by month
/*
month	 successful_projects	total_projects		success_per(%)
1				1393				3152				44.19
2				1670				3446				48.46
3				1851				3994				46.34
4				1793				4005				44.77
5				1785				4174				42.76
6				1753				4448				39.41
7				2257				9303				24.26
8				1831				6503				28.16
9				1912				5574				34.3
10				1999				5875				34.03
11				1773				5238				33.85
12				1089				3593				30.31

Findings:
	- June's success rate was 39.41%, and it fell to 24.26% in July
	- A 15.15 percentage point drop in a single month is the highest drop of the year
	- Project volume increased from 4448 in June to 9303 in July (about twice in volume)

Interpretation:
	- July 2014 marks a significant change in project activity. The sharp increase in project volume 
	coincided with substantial decline of success rate

Limitations:
	- Monthly analysis told us when the decline occurred. Why & where(category) is not explained yet.
*/

/*
==================================================
D2. July 2013 vs July 2014: Category comparison
==================================================

Business question:
	- Was the july 2014 decline isolated to certain categories or was it widespread across kickstarter?

Approach:
	- Comparing each category of july 2014 to july 2013 for success rate and finding their difference
	- difference = 2014 - 2013, +ve value -> Growth, -ve value -> Decline 
*/
SELECT
	category,
	MAX(CASE WHEN yr = 2013 THEN success_per END) AS [2013],
	MAX(CASE WHEN yr = 2014 THEN success_per END) AS [2014],
	MAX(CASE WHEN yr = 2014 THEN success_per END)  - 
	MAX(CASE WHEN yr = 2013 THEN success_per END)AS difference
FROM (
SELECT
	YEAR(launched) AS yr,
	category,
	ROUND(CAST(SUM(CASE WHEN state = 'Successful' THEN 1 ELSE 0 END) AS float)/COUNT(*) * 100 ,2) AS success_per
FROM clean_kickstarter_projects_resolved
WHERE MONTH(launched) IN (7) AND YEAR(launched) IN (2013,2014)
GROUP BY 
	YEAR(launched),
	category
)T
GROUP BY category
ORDER BY difference DESC
/*
Category		2013	2014	difference
Comics			52.32	57.45	5.13
Film & Video	43.29	33.33	-9.96
Publishing		35.67	21.45	-14.22
Games			49.07	31.31	-17.76
Theater			68.13	49.3	-18.83
Fashion			38.46	19.42	-19.04
Design			45.81	26.42	-19.39
Dance			67.39	46.51	-20.88
Music			56.17	33.97	-22.2
Photography		36.79	12.48	-24.31
Art				54.3	27.14	-27.16
Crafts			47.22	19.61	-27.61
Food			44.95	16.25	-28.7
Technology		44.26	14.02	-30.24
Journalism		59.09	13.93	-45.16

findings:
	- 14 out of 15 categories experienced a decline.
	- Comics was the only category to improve,
	  increasing from 52.32% to 57.45%.
	- Journalism recorded the largest decline
	  at 45.16 percentage points.
	- Technology followed with a decline of
	  30.24 percentage points.
	- Film & Video experienced the smallest decline
	  among the affected categories, at 9.96 points.

Interpretation:
	- The decline was not limited to a category. Decline of 14 out of 15 category suggests a broader
	 change in project activity in july 2014.

Limitations:
	- Broader decline fails to suggest the reason for decline in 2014 july.
	- Some categories may have small size which make rate unstable.
*/

/* 
===========================================
D3. Investigating zero-pledged projects
===========================================

Business question:
	Did the proportion of projects receiving zero pledges increase during the 2014 decline, particularly 
	in july?
*/

-- D3.1 Historical annual zero pledged rate(2009-2017)
SELECT 
	YEAR(launched) As yr,
    COUNT(*) AS resolved_projects,
    ROUND(CAST(SUM(CASE WHEN pledged = 0 THEN 1 ELSE 0 END) AS float)/ COUNT(*) * 100, 2) AS zero_pledge_rate
FROM clean_kickstarter_projects_resolved
GROUP BY YEAR(launched)
ORDER BY yr;
/*
yr		resolved_projects		zero_pledge_rate
2009		1179					12.98
2010		9577					12.3
2011		24048					9.41
2012		38478					8.16
2013		41088					5.85
2014		59305					12.93
2015		65272					18.77
2016		49096					10.55
2017		43419					10.14
*/


-- D3.2 Monthly zero pledged rate in 2014.
SELECT 
	MONTH(launched) As month,
    COUNT(*) AS resolved_projects,
    ROUND(CAST(SUM(CASE WHEN pledged = 0 THEN 1 ELSE 0 END) AS float)/ COUNT(*) * 100, 2) AS zero_pledge_rate
FROM clean_kickstarter_projects_resolved
WHERE YEAR(launched) = 2014
GROUP BY MONTH(launched)
ORDER BY MONTH
/*
month	resolved_projects	zero_pledge_rate
1		  	 3152				4.98
2		  	 3446				6.73
3		  	 3994				5.93
4		  	 4005				6.67
5		  	 4174				7.24
6		  	 4448				8.23
7		  	 9303				23.13
8		  	 6503				18.27
9		  	 5574				15.18
10		  	 5875				15.06
11		  	 5238				13.13
12		  	 3593				9.66
*/


-- Composition of failed projects across years
SELECT
	YEAR(launched) As yr,
	-- Rates among all resolved projects
	ROUND(CAST(SUM(CASE WHEN pledged = 0 THEN 1 ELSE 0 END) AS float)/ COUNT(*) * 100, 2) AS zero_pledge_failure_rate,
	ROUND(CAST(SUM(CASE WHEN pledged > 0 AND state = 'Failed' THEN 1 ELSE 0 END) AS float)/ COUNT(*) * 100, 2) AS pledged_but_failed_rate,
	-- Composition of all failed projects
	ROUND(CAST(SUM(CASE WHEN pledged = 0 THEN 1 ELSE 0 END) AS float)/(SUM(CASE WHEN state != 'Successful' THEN 1 ELSE 0 END))*100,2) AS zero_pledge_share_of_failures,
	ROUND(CAST(SUM(CASE WHEN pledged > 0 AND state = 'Failed' THEN 1 ELSE 0 END) AS float)/(SUM(CASE WHEN state != 'Successful' THEN 1 ELSE 0 END))*100,2) AS pledged_failure_share_of_failures
FROM clean_kickstarter_projects_resolved
GROUP BY YEAR(launched)
ORDER BY yr
/*
yr		zero_pledge_failure_rate	pledged_but_failed_rate		zero_pledge_share_of_failures	 pledged_failure_share_of_failures
2009			12.98						37.91							25.5							74.5
2010			12.3						39.74							23.64							76.36
2011			9.41						39.98							19.05							80.95
2012			8.16						45.34							15.25							84.75
2013			5.85						46.93							11.09							88.91
2014			12.93						51.48							20.07							79.93
2015			18.77						49.1							27.66							72.34
2016			10.55						51.41							17.03							82.97
2017			10.14						47.34							17.64							82.36


findings:

1. The annual zero-pledge rate increased from 5.85% in 2013 to 12.93% in 2014, reaching 18.77% in 2015. 
However, rates around 12–13% were also observed in 2009–2010.

2. July 2014 recorded the highest monthly zero-pledge rate at 23.13%, compared with 8.23% in June. 
Elevated rates continued in subsequent months.

3. Between 2013 and 2014, the zero-pledge failure rate increased by 7.08 percentage points, while the 
pledged-but-failed rate increased by 4.55 percentage points. About 61% of the rise in the failure rate 
from 2013 to 2014 came from projects with no pledges (7.08 of 11.63 points), and about 39% from 
failures that did receive pledges.

4. Zero-pledged projects accounted for 20.07% of all failures in 2014, compared with 11.09% in 2013. 
Nevertheless, approximately 80% of failed projects in 2014 had received at least some pledges.

Interpretation:

The increase in zero-pledged projects coincided with the deterioration in project success rates, 
particularly during July 2014.

Zero-pledged failures accounted for a larger share of the increase in the overall failure rate between 
2013 and 2014. However, projects receiving some pledges but failing to reach their goals remained the 
dominant form of failure.

Limitations:

- The analysis identifies associations but does not establish the underlying causes of the decline.
- Annual failure composition cannot establish whether the same pattern occurred specifically in July.
- The analysis does not investigate why projects receiving pledges failed to reach their funding goals.

Conclusion:

Zero-pledged projects appear to have contributed to the deterioration in project performance during 2014. 
However, they do not fully explain the decline, as pledged-but-failed projects continued to account for 
the majority of failures.
*/
