-- EDA on kickstarter data set
-- Scenario: advising company on their first tabletop game via kickstarter
-- Company needs to raise at least $15,000 to launch

USE kickstarter;
/* exploring data */
SELECT COUNT(DISTINCT id) AS Total_Campaigns FROM campaign; 
SELECT * FROM campaign LIMIT 10;
SELECT * FROM sub_category LIMIT 10;
SELECT COUNT(DISTINCT name) AS unique_sub_categories_total FROM sub_category;
SELECT 
	DISTINCT name 
    , id
    , category_id 
FROM sub_category 
ORDER BY 2; 
# note that 14 is sub_category id for TabletopGames under category_id of 5 as Games
SELECT DISTINCT name FROM currency ORDER BY name;
SELECT DISTINCT name, id FROM country ORDER BY id;
SELECT DISTINCT name, id FROM currency ORDER BY id;
SELECT * FROM category;
SELECT * FROM sub_category;
SELECT 
	MIN(launched) AS earliest_date_represented 
    , MAX(launched) AS latest_date_represented
FROM campaign;
SELECT count(*) AS num_tabletop_game_campaigns FROM campaign WHERE sub_category_id=14; 

/* exploring unexpected country 'N,0"*/
SELECT * FROM country WHERE name = 'N,0"';
SELECT COUNT(id) FROM campaign WHERE country_id = 11;
SELECT COUNT(id) FROM campaign WHERE country_id = 11 AND outcome="successful";
SELECT * FROM campaign WHERE country_id = 11 ORDER BY outcome;
SELECT * FROM campaign WHERE country_id = 11 AND sub_category_id=14;
/* null island seems to have little impact on data, 
especially inside of the tabletop subcategory*/

/* exploring currency and country impact on outcomes */
SELECT
	m.name
    , SUM(p.backers)
    , SUM(p.pledged)
    , p.outcome
FROM campaign p
LEFT JOIN currency AS m
ON m.id = p.currency_id
GROUP BY 1,4
ORDER BY 4, 3 DESC;

SELECT
	ROUND(SUM(CASE WHEN currency_id=2 THEN backers ELSE 0 END)/SUM(backers)*100,0) AS percent_USD_backers
    , ROUND(SUM(CASE WHEN currency_id=2 THEN 1 ELSE 0 END)/COUNT(id)*100,0) AS percent_USD_campaigns
    , SUM(CASE WHEN currency_id=2 THEN 1 ELSE 0 END) AS total_USD_campaigns
FROM campaign;

/* top countries by total backers*/
SELECT 
	cy.name as Country
    , sum(cmp.backers)
FROM campaign AS cmp
	JOIN country AS cy
    ON cy.id=cmp.country_id
WHERE cmp.outcome="successful" AND sub_category_id=14
GROUP BY 1
ORDER by 2 DESC;

/* US was top country with nearly 13 times as many backers as 2nd top country (Great Britain)
USD was top in all outcome categories 
and more than 3/4 of the data overall and by backers
with a total of 11772 data points to work from so from here
we will limit all comparisons to campaigns with USD for 
easier comparison*/

/* calculating general stats */
SELECT 
	outcome
    , COUNT(*)
    , MAX(goal)
    , AVG(goal)
    , MIN(goal)
    , STDDEV(goal) 
FROM campaign
WHERE currency_id=2
GROUP BY outcome;

/*the bottom 75% of successful and failed data separately*/
SELECT 
	outcome
    , COUNT(*)
    , MAX(goal)
    , AVG(goal)
    , MIN(goal)
    , STDDEV(goal)
FROM (
    SELECT 
		outcome
        , goal
    FROM campaign
    WHERE outcome = "successful" AND currency_id=2
    ORDER BY goal DESC
    LIMIT 3990 OFFSET 1329
) AS bottom_75_successful
GROUP BY outcome
UNION ALL
SELECT 
	outcome
    , COUNT(*)
    , MAX(goal)
    , AVG(goal)
    , MIN(goal)
    , STDDEV(goal)
FROM (
    SELECT 
		outcome
        , goal
    FROM campaign
    WHERE outcome = "failed" AND currency_id=2
    ORDER BY goal DESC
    LIMIT 5888 OFFSET 1962
) AS bottom_75_failed
GROUP BY outcome;

/* upper 25% of data 
failed projects occurred 150% more than successful (2.5 times larger as a category)*/
SELECT 
	outcome
    , COUNT(*)
    , MAX(goal)
    , MIN(goal)
FROM (
    SELECT 
		outcome
		, goal
    FROM campaign
    WHERE currency_id = 2
    ORDER BY goal DESC
    LIMIT 3750
) AS top_25_percent
GROUP BY outcome;

/* upper half of innerquartile range
32% more failed than succeeded (or 1.3 times larger as a category)*/ 
SELECT 
	outcome
    , COUNT(*)
    , MAX(goal)
    , MIN(goal)
FROM (
    SELECT 
		outcome
        , goal
    FROM campaign
    WHERE currency_id = 2
    ORDER BY goal DESC
    LIMIT 3750 OFFSET 3750
) AS upper_half_interquartile
group by outcome;

/* lower half of interquartile range
nearly equal successful vs failed, with small percentage more of successful*/
SELECT 
	outcome
    , COUNT(*)
    , MAX(goal)
    , MIN(goal)
FROM (
    SELECT 
		outcome
        , goal
    FROM campaign
    WHERE currency_id = 2
    ORDER BY goal DESC
    LIMIT 3750 OFFSET 7500
) AS lower_half_interquartile
GROUP BY outcome;

/* lowest 25% of data 
more successful than failed by 25%*/
SELECT 
	outcome
    , COUNT(*)
    , MAX(goal)
    , MIN(goal)
FROM (
    SELECT 
		outcome
        , goal
    FROM campaign
    WHERE currency_id = 2
    ORDER BY goal DESC
    LIMIT 3750 OFFSET 11250 
) AS lowest_25_percent
GROUP BY outcome;


/*bottom 75% of data*/
SELECT 
	outcome
    , COUNT(*)
    , MAX(goal)
    , AVG(goal)
    , MIN(goal)
    , STDDEV(goal)
FROM (
	SELECT 
		outcome
        , goal
    FROM campaign
    WHERE currency_id = 2
    ORDER BY goal DESC
    LIMIT 11250 OFFSET 3750
) AS bottom_75_percent
GROUP BY outcome;


/* returns top and bottom three total backers per subcategory ordered by total backers*/

WITH joined_campaign_subcategory_category_for_backers AS (
    SELECT
        cmp.name
        , cmp.sub_category_id
        , cat.subcategory_name
        , cat.category_index
        , cat.category_name
        , cmp.backers
    FROM campaign AS cmp
    LEFT JOIN (
        SELECT 
            s.id AS subcategory_index 
            , s.name AS subcategory_name
            , s.category_id AS category_index 
            , c.name AS category_name
        FROM sub_category AS s
        LEFT JOIN category AS c 
        ON s.category_id=c.id
    ) AS cat ON cmp.sub_category_id = cat.subcategory_index
    WHERE currency_id = 2
)
SELECT *
FROM (
    SELECT
        sub_category_id
        , subcategory_name
        , SUM(backers) AS total_backers 
    FROM joined_campaign_subcategory_category_for_backers
    GROUP BY sub_category_id
    ORDER BY total_backers DESC
    LIMIT 3
) AS top_results
UNION ALL
SELECT *
FROM (
    SELECT
        sub_category_id
        , subcategory_name
        , SUM(backers) AS total_backers 
    FROM joined_campaign_subcategory_category_for_backers
    GROUP BY sub_category_id
    ORDER BY total_backers ASC
    LIMIT 3
) AS bottom_results;

/* returns top and bottom three total backers per category ordered by total backers*/

WITH joined_campaign_subcategory_category_for_backers AS (
    SELECT
        cmp.name
        , cmp.sub_category_id
        , cat.subcategory_name
        , cat.category_index
        , cat.category_name
        , cmp.backers
    FROM campaign AS cmp
    LEFT JOIN (
        SELECT 
            s.id AS subcategory_index 
            , s.name AS subcategory_name
            , s.category_id AS category_index 
            , c.name AS category_name
        FROM sub_category AS s
        LEFT JOIN category AS c 
        ON s.category_id=c.id
    ) AS cat ON cmp.sub_category_id = cat.subcategory_index
    WHERE currency_id = 2
)
SELECT *
FROM (
	SELECT
		category_index
		, category_name
		, SUM(backers) AS total_backers 
	FROM joined_campaign_subcategory_category_for_backers
	GROUP BY category_index
	ORDER BY total_backers DESC
	LIMIT 3
) AS top_results
UNION
SELECT *
FROM (
	SELECT
		category_index
		, category_name
		, SUM(backers) AS total_backers 
	FROM joined_campaign_subcategory_category_for_backers
	GROUP BY category_index
	ORDER BY total_backers ASC
	LIMIT 3
) AS bottom_results;

/* returns top and bottom three total pledged per category ordered by total pledged */

WITH joined_campaign_subcategory_category_for_pledged AS (
    SELECT
		cmp.name
		, cmp.sub_category_id
		, cat.subcategory_name
		, cat.category_index
		, cat.category_name 
		, cmp.pledged
    FROM campaign AS cmp
    LEFT JOIN (
        SELECT 
            s.id AS subcategory_index 
            , s.name AS subcategory_name
            , s.category_id AS category_index 
            , c.name AS category_name
        FROM sub_category AS s
        LEFT JOIN category AS c 
        ON s.category_id=c.id
    ) AS cat ON cmp.sub_category_id = cat.subcategory_index
    WHERE currency_id = 2
)
SELECT *
FROM (
	SELECT
		category_index
		, category_name
		, SUM(pledged) AS total_pledged
	FROM joined_campaign_subcategory_category_for_pledged
	GROUP BY category_index
	ORDER BY total_pledged DESC
    LIMIT 3
) as top_results
UNION
SELECT *
FROM (
	SELECT
		category_index
		, category_name
		, SUM(pledged) AS total_pledged
	FROM joined_campaign_subcategory_category_for_pledged
	GROUP BY category_index
	ORDER BY total_pledged ASC
    LIMIT 3
) as bottom_results;

/* returns top and bottom three total pledged per subcategory ordered by total pledged */

WITH joined_campaign_subcategory_category_for_pledged AS (
    SELECT
		cmp.name
		, cmp.sub_category_id
		, cat.subcategory_name
		, cat.category_index
		, cat.category_name 
		, cmp.pledged
    FROM campaign AS cmp
    LEFT JOIN (
        SELECT 
            s.id AS subcategory_index 
            , s.name AS subcategory_name
            , s.category_id AS category_index 
            , c.name AS category_name
        FROM sub_category AS s
        LEFT JOIN category AS c 
        ON s.category_id=c.id
    ) AS cat ON cmp.sub_category_id = cat.subcategory_index
    WHERE currency_id = 2
)
SELECT *
FROM (
	SELECT
		sub_category_id
		, subcategory_name
		, SUM(pledged) AS total_pledged
	FROM joined_campaign_subcategory_category_for_pledged
	GROUP BY sub_category_id
	ORDER BY total_pledged DESC
    LIMIT 3
) AS top_results
UNION
SELECT *
FROM (
	SELECT
		sub_category_id
		, subcategory_name
		, SUM(pledged) AS total_pledged
	FROM joined_campaign_subcategory_category_for_pledged
	GROUP BY sub_category_id
	ORDER BY total_pledged ASC
    LIMIT 3
) AS bottom_results;

/* returns number of successful tabletop games with a goal equal to or larger than Gloomhaven*/
SELECT
	COUNT(*)
FROM campaign
WHERE outcome="successful" AND goal>=100000 AND sub_category_id=14 AND currency_id = 2;

/*exploring subcategories related to GAME category
analyzing subcategory 13 (generic "games") specifically to see if it might contain data
that is relevant to and could significantly impact our analysis
if we limit detailed analysis to subcategory 14 */
SELECT * FROM sub_category WHERE category_id=7;
SELECT * FROM campaign WHERE sub_category_id=13 AND currency_id = 2;

/*count in each subcategory for 13 and 14*/
SELECT
    CASE
        WHEN sub_category_id = 13 THEN 'games'
        WHEN sub_category_id = 14 THEN 'tabletop games'
        ELSE 'unknown'
    END AS subcategory,
    COUNT(*) 
FROM
    campaign
WHERE
    sub_category_id IN (13, 14) AND currency_id = 2
GROUP BY
    subcategory;
    
/* top stats by various measures for subcategory 13 to compare to 14*/
SELECT
	name
    , goal
    , pledged
    , pledged-goal AS exceeded_money
    ,(pledged-goal)/goal as percent_over
    , backers
    , outcome
FROM campaign
WHERE sub_category_id=13 AND outcome="successful" AND currency_id = 2
ORDER BY pledged DESC;

/*top tabletop game by various measures*/
SELECT 
	name
    , goal
    , pledged
    , pledged-goal AS exceeded_money
    ,(pledged-goal)/goal as percent_over
    , backers
    , outcome
FROM campaign
WHERE sub_category_id=14 AND outcome="successful" AND currency_id = 2
ORDER BY pledged DESC;

SELECT * FROM campaign WHERE name="Gloomhaven (Second Printing)";



/* total backers and total pledged by campaign time length in days */
SELECT 
	length_in_days
    , SUM(backers) AS total_backers
    , SUM(pledged) AS pledged_total
FROM (
	SELECT
		launched
		, deadline
		, TIMESTAMPDIFF(day, launched, deadline) AS length_in_days
		, pledged
        , outcome
        , backers
	FROM campaign
    WHERE currency_id = 2)
	AS time_table
WHERE outcome="successful" 
GROUP BY length_in_days
ORDER BY length_in_days;

/* total backers and total pledged by campaign time length in days for subcategory 14 */
SELECT 
	length_in_days
    , SUM(backers) AS total_backers
    , SUM(pledged) AS pledged_total
FROM (
	SELECT
		launched
		, deadline
		, TIMESTAMPDIFF(day, launched, deadline) AS length_in_days
		, pledged
        , outcome
        , backers
        , sub_category_id
	FROM campaign
    WHERE currency_id = 2)
	AS time_table
WHERE outcome="successful" AND sub_category_id=14
GROUP BY length_in_days
ORDER BY length_in_days;

/* outcome totals for campaign goals over $15000 */
    
SELECT
	outcome
	, COUNT(*) AS overall_total_count
	, COUNT(CASE WHEN sub_category_id = 14 THEN 1 END) AS tabletop_only_count
FROM campaign
WHERE goal > 15000 AND currency_id = 2
GROUP BY outcome;

/* general stats for tabletop games by outcome */
SELECT 
	outcome
	, AVG(goal)
    , STDDEV(goal)
    , AVG(pledged)
    , STDDEV(pledged)
    , AVG(backers) 
    , STDDEV(backers)
    , max(backers)
FROM campaign 
WHERE sub_category_id=14 AND currency_id = 2
GROUP BY outcome;

SELECT count(*) FROM campaign WHERE sub_category_id=14 and outcome="failed" AND currency_id = 2; 
SELECT count(*) FROM campaign WHERE sub_category_id=14 and outcome="failed" and backers<=233 AND currency_id = 2;

/* stats about backers for successful tablecop campaigns above 15000 */
SELECT
	"above 15000" AS goal
	, max(backers)
    , AVG(backers)
    , STDDEV(backers)
    , min(backers)
FROM campaign
WHERE sub_category_id=14 AND goal>=15000 AND outcome="successful" AND currency_id = 2
UNION ALL
SELECT
	"between 15000 and 16000" AS goal
	, max(backers)
    , AVG(backers)
    , STDDEV(backers)
    , min(backers)
FROM campaign
WHERE sub_category_id=14 AND goal>=15000 AND goal<=16000 AND outcome="successful";

/* stats about average backers by sub_category_id */
SELECT
    sub_category_id,
    AVG(backers) AS avg_backers,
    AVG(CASE WHEN outcome = 'successful' THEN backers END) AS avg_successful_backers
FROM campaign
WHERE currency_id = 2
GROUP BY sub_category_id
ORDER BY avg_backers DESC;

/* information about amount over goal by outcome */
SELECT
	outcome, AVG(pledged-goal) AS amount_over_goal
FROM campaign
WHERE sub_category_id=14 and goal>=15000 and goal<16000 AND currency_id = 2
GROUP BY outcome;

/* tabletop games is the 4th best backed sub category by average and is not at a far
shot from the general average to get to the average for successful campaigns*/ 

