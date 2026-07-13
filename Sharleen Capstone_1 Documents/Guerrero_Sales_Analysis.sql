# ------------------------------------------------------------------------------------------------- #
# Capstone 1:            Sales Territory Analysis
# Name:                  Sharleen Guerrero
# Date:                  April 27, 2026
# Sales Manager:         Shruti Reddy
# Project Objective:     The objective of this project is to conduct a comprehensive business 
#                        analysis of the sample_sales database for a fictional bookstore chain called 
#                        EmporiUm. The analysis focuses on the Northeast region, specifically the 
#                        Maryland sales territory. Key insights will be explored through SQL queries 
#             			 to identify performance trends, and data-driven recommendations will be 
#                        provided for where to focus sales attention in the next quarter.
# -------------------------------------------------------------------------------------------------- #

USE sample_sales;

-- Identifying Sales Territory
-- This query aims to identify the assigned sales territory based on the sales manager.
SELECT * 
FROM management
WHERE SalesManager = 'Shruti Reddy';

-- Assigned Region: Northeast Region - State of Maryland.
-- Online Sales is its own sales territory managed separately in the
-- West region and is therefore excluded from this analysis.

# Part 1 & 2: Business Analysis Questions & Query Development Logic

-- ==========================================================
-- Question 1:
-- What is total revenue overall for sales in the assigned
-- territory, plus the start date and end date that tell you
-- what period the data covers?
-- ==========================================================
SELECT sl.State,
    SUM(ss.Sale_Amount) AS Total_Revenue,
    MIN(ss.Transaction_Date) AS Start_Date,
    MAX(ss.Transaction_Date) AS End_Date
FROM store_sales ss
INNER JOIN store_locations sl 
	ON ss.Store_ID = sl.StoreId
WHERE sl.State = 'Maryland';

-- Explanation of Logic:
-- Question demands calculation of total revenue for Maryland territory.
-- Store ID acts as the bridge between store_sales and territory
-- through StoreId and Store_ID to filter sales by Maryland.
-- SUM calculates total revenue, and MIN and MAX identify start date
-- and end date from the result.
     
-- ==========================================================
-- Question 2:
-- What is the month by month revenue breakdown for the
-- sales territory?
-- ==========================================================
SELECT
    DATE_FORMAT(ss.Transaction_Date, '%Y-%m') AS Revenue_Month,
    SUM(ss.Sale_Amount) AS Monthly_Revenue
FROM store_sales ss
INNER JOIN store_locations sl 
	ON ss.Store_ID = sl.StoreId
WHERE sl.State = 'Maryland'
GROUP BY Revenue_Month
ORDER BY Revenue_Month;
-- ORDER BY Monthly_Revenue DESC;
-- To quickly pull highest and lowest months.

-- Explanation of Logic:
-- A month by month revenue breakdown for Maryland is useful to
-- display revenue trends over time.
-- There is no direct link between store_sales and territory state.
-- Store ID acts as the bridge between store_sales and territory
-- through StoreId and Store_ID to filter sales by Maryland.
-- GROUP BY ensures calculations are per month, not overall.

-- ==========================================================
-- Question 3:
-- Provide a comparison of total revenue for the specific
-- sales territory and the region it belongs to.
-- ==========================================================    
WITH Northeast_Sales AS (
    SELECT sl.State, ss.Sale_Amount AS Revenue
    FROM store_sales ss
    INNER JOIN store_locations sl 
		ON ss.Store_ID = sl.StoreId
    INNER JOIN management m 
		ON sl.State = m.State
    WHERE m.Region = 'Northeast'
)
SELECT 
    'Northeast' AS Region,
    State,
    SUM(Revenue) AS Total_Revenue,
    (SELECT SUM(Revenue) FROM Northeast_Sales) AS Northeast_Total,
    ROUND(SUM(Revenue) / (SELECT SUM(Revenue) FROM Northeast_Sales) * 100, 2) 
    AS Region_Percentage_Contribution
FROM Northeast_Sales
GROUP BY State
ORDER BY Total_Revenue DESC;

-- Explanation of Logic:
-- Maryland is in the Northeast region. This query compares the state's
-- revenue with other states in the Northeast region.
-- A CTE is used to define store sales data for the Northeast region. There
-- is no direct link from store_sales to region, but I created a path by linking
-- Store_sales to Store_locations through StoreId and Store_ID, and finally
-- reaching management through shared State from Store_locations.
-- GROUP BY State collapses revenue into one row for each Northeast state.
-- A subquery pulls Northeast total as a reference column on every row
-- for direct comparison. ORDER BY sorts by Total_Revenue DESC to show
-- highest performing states first. Each store's SUM is divided by the 
-- grand total and multiplied by 100 to get its percentage share.

-- ==========================================================
-- Question 4:
-- What is the number of transactions per month and average
-- transaction size by product category for the sales 
-- territory?
-- =========================================================
SELECT
	DATE_FORMAT(ss.Transaction_Date,'%Y-%m') AS Revenue_Month,
    ic.Category as Product_Category,
	COUNT(*) AS Transaction_Count,
    ROUND(AVG(ss.Sale_Amount), 2) AS Average_Transaction_Size,
    SUM(ss.Sale_Amount) AS Category_Revenue
    FROM store_sales ss
    INNER JOIN store_locations sl
		ON ss.Store_ID = sl.StoreId
	INNER JOIN products p
		ON ss.Prod_Num = p.ProdNum
	INNER JOIN inventory_categories ic
		ON p.Categoryid = ic.Categoryid
	WHERE sl.State = 'Maryland'
	GROUP BY Revenue_Month, Product_Category
    ORDER BY Revenue_Month, Category_Revenue DESC;
    
-- Explanation of Logic:
-- Breaking down transaction activity by product category can help
-- visualize which categories drive the most sales in Maryland.
-- There is no direct link from store_sales to inventory_categories,
-- but the chain begins with store_locations. Store_sales joins 
-- store_locations through StoreId and Store_ID, Store_sales joins 
-- products through ProdNum, and inventory_categories is reached through 
-- shared Categoryid.
-- COUNT calculates the number of transactions, AVG calculates the
-- average transaction size, and SUM calculates category revenue.
-- Results are filtered directly by sl.State.
-- Results are grouped by month and category and ordered by
-- category revenue DESC to display top performing categories first.

-- ==========================================================
-- Question 5:
-- Can you provide a ranking of in-store sales performance by
-- each store in the sales territory?
-- ==========================================================
SELECT ss.Store_ID AS Store_ID,
	   sl.StoreLocation AS Store_City,
    SUM(ss.Sale_Amount) AS Total_Revenue,
	COUNT(ss.Sale_Amount) AS Transaction_Count,
	ROUND(AVG(ss.Sale_Amount), 2) AS Average_Transaction_Size,
	RANK() OVER (ORDER BY SUM(ss.Sale_Amount) DESC) AS Store_Rank
FROM store_sales ss
INNER JOIN store_locations sl
	ON ss.Store_ID = sl.StoreId
WHERE sl.State = 'Maryland'
GROUP BY Store_ID, Store_City
ORDER BY Store_Rank;

-- Explanation of Logic:
-- Manager Reddy manages all stores in Maryland, but performance can 
-- vary across stores. 
-- Store_sales is linked to store_locations through shared Store_ID
-- and StoreId to filter by Maryland and display store city names.
-- COUNT(ss.Sale_Amount) calculates total transactions, SUM(ss.Sale_Amount)
-- calculates total revenue, and AVG(ss.Sale_Amount) measures average
-- revenue per transaction.
-- RANK() assigns a rank to each store ordered determined by total revenue.
-- GROUP BY collapses all transactions into one row per store.
-- Results are ordered by Store_Rank to display top performing
-- stores first.

-- ==========================================================
-- Question 6:
-- What is your recommendation for where to focus sales
-- attention in the next quarter?
-- ==========================================================
-- Additional Exploration:

-- Top Performing Products in Maryland
SELECT 
    p.ProdNum,
    p.Product,
    ic.Category AS Product_Category,
    SUM(ss.Sale_Amount) AS Total_Revenue,
    COUNT(*) AS Transaction_Count
FROM store_sales ss
INNER JOIN store_locations sl 
    ON ss.Store_ID = sl.StoreId
INNER JOIN products p 
    ON ss.Prod_Num = p.ProdNum
INNER JOIN inventory_categories ic 
    ON p.Categoryid = ic.Categoryid
WHERE sl.State = 'Maryland'
GROUP BY p.ProdNum, p.Product, Product_Category
ORDER BY Total_Revenue DESC
LIMIT 10;

-- Category Revenue Trend Year over Year
SELECT 
    YEAR(ss.Transaction_Date) AS Year,
    ic.Category AS Product_Category,
    SUM(ss.Sale_Amount) AS Annual_Revenue,
    LAG(SUM(ss.Sale_Amount)) OVER (PARTITION BY ic.Category ORDER BY YEAR(ss.Transaction_Date)) AS Previous_Year_Revenue,
    ROUND(SUM(ss.Sale_Amount) - LAG(SUM(ss.Sale_Amount)) OVER (PARTITION BY ic.Category ORDER BY YEAR(ss.Transaction_Date)), 2) AS Revenue_Change
FROM store_sales ss
INNER JOIN store_locations sl ON ss.Store_ID = sl.StoreId
INNER JOIN products p ON ss.Prod_Num = p.ProdNum
INNER JOIN inventory_categories ic ON p.Categoryid = ic.Categoryid
WHERE sl.State = 'Maryland'
GROUP BY Year, Product_Category
ORDER BY Product_Category, Year;
-- LAG identifies the previous year's revenue within each category through PARTITION BY,
-- and subtracting it from the current year gives the revenue change.
-- A positive value indicates growth, a negative value indicates decline.
-- Results are ordered by category and year to show each category's trend over time.

/* Key Insights:
Q1: Marylands' Total Revenue: $11,451,615.09
    Range: January 1, 2022 - December 31, 2025 (Four fiscal years)

Q2: Highest Month: October 2025 ($359,699.69)
	Lowest Month: September 2022 ($158,952.74)
    Revenue indicates an upward trend across all four fiscal years.
    
Q3: Maryland Revenue: $11,451,615.09
	Top performing territory in Northeast region, contributing 47.25% to
    region's total revenue. 
    
Q4: Revenue Totals and Averages per Category Across Entire Period
	Technology & Accessories: $5,044,301.53 | 11,071 transactions | Avg $454.26
	Textbooks: $1,525,841.02 | 8,726 transactions | Avg $174.46
	Books (General): $305,221.28 | 9,604 transactions | Avg $31.72
	Apparel and Merchandise: $300,812.21 | 9,352 transactions | Avg $32.13
	Art Supplies: $258,838.94 | 8,255 transactions | Avg $31.32
	Stationery and Supplies: $102,807.88 | 9,862 transactions | Avg $10.44 
    
Q5: Highest Performing Store: Store 736 (North Harford):  $8,708,119.00 | 69,530 transactions | Avg $125.24 
	Lowest Performing Store: Store 731 (Annapolis): $288,865.31 | 2,207 transactions | Avg $130.89
    North Harford's success is due to its disproportionately high transaction count compared to
    other stores in the territory, but its average transaction size is the lowest overall. All other store 
    performance is consistent, staying within the $300k to $320k range, with the primary outlier being 
    North Harford at a staggering 8.7 million total revenue. 
    
Q6a: Top 10 performing products in Maryland all belong to the Technology & Accessories
category, with the MSI Creator Z16 bringing in the most revenue at $306,883.80. However, 
the Lenovo IdeaPad Flex 5 is the highest-demand, with 194 transactions.

Q6b: Technology & Accessories 2023-2025 Trend: +$415,266 | +$5,627 | +$521,971
	 Textbooks 2023-2025 Trend: -$78,125 | +$1,491 | -$99,322 
     All other categories showing positive growth throughout the years.

Analyst Recommendation: 
Based on the analysis, Reddy's primary focus for the next quarter should be Technology & Accessories, 
which generated $5 million in revenue, with a steady increase each fiscal year and a jump of
$521,971 in 2025 alone, with no signs of slowing down based on four years of consistent growth.
The category commands the top average transaction size of $454, indicating strong customer willingness 
to spend on premium products. To leverage this, bundle promotions for products with lower transaction count, 
such as the MSI Creator Z16, could increase transaction sales for a potentially high-revenue product. 
For high-demand products such as the Lenovo IdeaPad Flex 5, which leads in transaction volume at 194 units 
but averages only $1,294 per transaction compared to the MSI's $1,764, further pricing analysis is recommended 
before any price adjustments to avoid disrupting existing demand.

Stationery & Supplies is a low performing category, but with potential worth re-examining. While revenue 
sits at $102,807 with an average of $10.44 per transaction, it is the second leading category in transaction 
volume with 9,862 transactions. This suggests customers are frequently purchasing, but spending minimally per 
transaction. To capitalize on this demand, introducing bundle promotions that pair Stationery & Supplies with 
higher ticket categories could increase average transaction size and drive increased revenue from a customer 
base that already exists. Possible bundles could include Books (General) or Art Supplies to gear toward a student
consumer base as a back-to-school or premium studying bundle. Both categories average around $32 per transaction 
but have lower transaction counts, indicating the bundle would benefit all three categories by increasing transaction counts
and therefore revenue across the board.

Despite being the second highest revenue category at $1.5 million, the Textbooks category is a concern. Revenue has declined
twice, once in 2023 and in 2025. Although the decline was not consecutive, with a small recovery of $1,491 in 2024, the second 
decline in 2025 was a staggering $99,322, which is worse than the initial drop. It would be a risk to continue investing heavily 
in textbook inventory, but as a student-geared bookstore chain it shouldn't be entirely eliminated. Instead, management should focus
on demand-based stocking decisions and exploring a potential consolidation with the Books (General) category to maximize budgeting while
minimizing potential heavy losses as textbooks are continuously updated.

At the store level, the Harford location accounts for $8.7 million of Maryland's total revenue, driven by transaction volume rather 
than transaction size. Many factors could contribute to its disproportionate success compared to other stores, such as location, 
store size, or highly experienced staff. Reddy should investigate the sales tactics used by employees at the Harford location and 
implement them across mid-level and lower performing stores.  Besides Harford as the outlier, most store performance is consistent, 
falling within the $288k to $320k range, with Germantown being an secondary outlier at $584,676. These stores may benefit most from 
bundle promotions and targeted local marketing campaigns. For the lowest performing store, Annapolis, a dual improvement plan could be 
implemented targeting improved staff training and seasonal promotions to drive foot traffic, while also conducting further research into 
whether location or city population are contributing factors outside of management's control. As a store with a student-driven customer base, 
Maryland's next quarter success depends on strengthening what works currently for top-performing stores, stabilizing what's declining, and 
closing the performance gap across stores. Maryland is clearing a strong performing territory and clear opportunities for targeted growth.
*/
