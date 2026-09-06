# Tesco Customer Analysis
---

This project is based on the Tesco dataset which contains data about Customers, Sales and diffrent type of stores 

The main objective is to analyse Customer Churning, high value customers and diffrent teir of customers along with performance of all the stores and their types

### Files
- **Churned Labled Customers** - all the customers who were churned or are at risk of churning. columns like last transaction data and days since last purchase are present in this file.
- **Customer Demographic** - Demographic details about the customers like Gender, Income Group, marital status and Membership details are present in this file.
- **Customer Transaction**- Transaction columns for all the transaction done by customers  along with quantity, product category, transaction amount and Promotion (applied/not applied) are present in this file.
- **Loyality Program**- details about customer tier are present here (Gold,Silver,Platinum) along with points erned and points redeemed.
- **Store location**- details about store and their locations along with store type are present in this file

### Objectives
1. Data Preparation and transformation - during data preparation we used Power Query editor to verify each column data types, remove any duplicate or empty rows and and merged any unnecessary column. created columns - Membership duration, Transaction year and Transaction month 

2. Identifying Churn rate trend - We created measure and created visuals to find out the Current churn rate and rettention rate along with repeate and non repeating customers and visualized it by customer demographic and income group. We also identified customers who baught the membership but never made a purchase
3. Understanding Customer and loyalty tiers - created measures to find the average purchase amount and purchase frequency by diffrent teir with or without promtion, also found out the churning rate by each tier. We also created segementation for high, low and mid teir customer by how many times they pruchased from tesco and more.
4. Analyzing promotions and Retention - We visualized the % of transaction during promotion, average quantity and amount during promotion and without promotion filtered by store type
5. Store performance - Visualized perfomance of each store by average purchase value , No. of customers and No. of purchases along with churn rate and repeat rate for each store filtered by region and store type.
6. Identifying High value customer (CLV) - we calculated CLV and visualized it across diffrent demographic, tier and raw table to see top 10 customer according to their CLV.

### Conclusion

Overall, churn is the biggest problem area for Tesco in this dataset - the churn rate came out higher than the retention rate, even though repeat customers make up more than 50% of everyone who joined. That gap is the main thing the business needs to close.

**Where churn is worst**
- Low income customers in Birmingham had the highest churn of any demographic/city combination, at around 75%.
- London stores had the highest average churn rate among all regions, at 53.71%.
- Store S108 had the single highest churn rate of any store, at 57.30%.
- Among loyalty tiers, Platinum had the highest churn rate overall.
- Out of the customers who churned, 155 of them were previously repeat customers - losing already-loyal customers like this is a bigger loss than losing one-time buyers.

**Loyalty tier and promotion performance**
- Promotions worked in general - they increased both average purchase quantity and purchase amount, and lifted total sales by about 4.67% during promotional periods.
- Gold tier was the best performing segment overall: it had the highest number of customers, responded most positively to promotions, and was the only tier with consistently positive performance across every metric.
- Platinum tier was the exception - it was the only tier where promotions had a negative effect on sales, and despite having the highest redemption rate (over 70% on average across tiers), it still had the highest churn. The categories Platinum and Silver customers buy most often are beverages and clothing, so targeted deals in those categories are the most likely lever to fix this.
- The loyalty programme is working as intended for Gold and Silver members, but not for Platinum - it needs new perks/rewards rather than just more points.

**Store and CLV insights**
- Superstores had a lower average churn rate than other formats, but Tesco only operates four of them - there's a case for opening more.
- Express stores are generating the most high-value customers, so reducing churn specifically in that format should be a priority.
- Only three customers qualified as "high CLV," which points to an opportunity to grow average CLV across the wider base rather than relying on a handful of top spenders.

**Recommendations**
1. Launch a retention-focused campaign specifically in London and for Store S108.
2. Redesign the Platinum tier's perks/rewards and target promotions in beverages and clothing to reverse its negative promotion response and high churn.
3. Prioritize win-back efforts for the 155 previously-repeat customers who churned, since they represent the highest-value losses.
4. Consider expanding the Superstore format given its comparatively low churn.
5. Reduce churn among Express store customers, since they otherwise skew high-value.
6. Continue and expand promotions overall (excluding Platinum), given the measurable 4.67% sales lift.
