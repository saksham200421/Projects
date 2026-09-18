/* =====================================================
PROJECT: LOGISTICS OPTIMIZATION – AMAZON
===================================================== */


/* =====================================================
TASK 1: DATA CLEANING & PREPARATION
===================================================== */

-- Task 1.1: Remove duplicate records
DELETE o1
FROM orders o1
JOIN orders o2 
ON o1.Order_ID = o2.Order_ID 
AND o1.Order_Date > o2.Order_Date;

-- Task 1.2: Replace NULL Traffic_Delay_Min

UPDATE routes
	SET Traffic_Delay_Min = (SELECT 
				AVG(Traffic_Delay_Min)
				FROM routes WHERE Traffic_Delay_Min IS NOT NULL
                )
WHERE Traffic_Delay_Min IS NULL;

-- Task 1.3: Format date columns
UPDATE orders
SET Order_Date = STR_TO_DATE(
        DATE_FORMAT(Order_Date, '%Y-%m-%d'),'%Y-%m-%d'),
    Expected_Delivery_Date = STR_TO_DATE(
        DATE_FORMAT(Expected_Delivery_Date, '%Y-%m-%d'),
        '%Y-%m-%d'),
    Actual_Delivery_Date = STR_TO_DATE(
        DATE_FORMAT(Actual_Delivery_Date, '%Y-%m-%d'),
        '%Y-%m-%d');
UPDATE shipment_tracking
SET Checkpoint_Time = STR_TO_DATE(DATE_FORMAT(
Checkpoint_Time, '%Y-%m-%d'),'%Y-%m-%d');


-- Task 1.4: Flag invalid records
ALTER TABLE orders ADD COLUMN date_flag VARCHAR(10);

UPDATE orders
SET date_flag = CASE 
    WHEN Actual_Delivery_Date < Order_Date THEN 'Invalid'
    ELSE 'Valid'
END;


/* =====================================================
TASK 2: DELIVERY DELAY ANALYSIS
===================================================== */

-- Task 2.1: Delay per order
SELECT 
    Order_ID,
    DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) AS delayed_days
FROM orders;

-- Task 2.2: Top 10 delayed routes
SELECT 
    Route_ID,
    avg_delay_days,
    RANK() OVER (ORDER BY avg_delay_days DESC) AS route_rank
FROM (
    SELECT 
        Route_ID,
        AVG(DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date)) AS avg_delay_days
    FROM orders
    WHERE Delivery_Status = 'delayed'
    GROUP BY Route_ID
) t
LIMIT 10;

-- Task 2.3: Rank orders within warehouse
SELECT 
    c.Warehouse_ID,
    p.Order_ID,
    DATEDIFF(p.Actual_Delivery_Date, p.Expected_Delivery_Date) AS delay,
    DENSE_RANK() OVER (
        PARTITION BY c.Warehouse_ID
        ORDER BY DATEDIFF(p.Actual_Delivery_Date, p.Expected_Delivery_Date) DESC
    ) AS delay_rank
FROM orders p
JOIN warehouses c 
ON p.Warehouse_ID = c.Warehouse_ID
WHERE p.Delivery_Status = 'delayed';


/* =====================================================
TASK 3: ROUTE OPTIMIZATION INSIGHTS
===================================================== */

-- Task 3.1.1: Avg delivery time
SELECT 
    Route_ID,
    ROUND(AVG(DATEDIFF(Actual_Delivery_Date, Order_Date))) AS average_delivery_days
FROM orders
GROUP BY Route_ID;

-- Task 3.1.2: Avg traffic delay
WITH Rout_traffic AS (
    SELECT 
        o.Route_ID,
        s.Order_ID,
        COUNT(*) AS delayed_count_per_order
    FROM shipment_tracking s 
    JOIN orders o ON s.Order_ID = o.Order_ID
    WHERE s.Delay_Reason = 'Traffic'
    GROUP BY o.Route_ID, s.Order_ID
)
SELECT 
    rt.Route_ID,
    ROUND(AVG(rt.delayed_count_per_order * r.Traffic_Delay_Min),1) AS avg_delay
FROM Rout_traffic rt 
JOIN routes r ON rt.Route_ID = r.Route_ID
GROUP BY rt.Route_ID;

-- Task 3.1.3: Efficiency ratio
SELECT 
    Route_ID,
    ROUND(Distance_KM / Average_Travel_Time_Min,2) AS efficiency_ratio
FROM routes;

-- Task 3.2: Worst 3 routes
SELECT 
    Route_ID,
    ROUND(Distance_KM / Average_Travel_Time_Min,2) AS efficiency_ratio
FROM routes
ORDER BY efficiency_ratio
LIMIT 3;

-- Task 3.3: Routes with >20% delays
SELECT 
    Route_ID,
    (COUNT(CASE WHEN Delivery_Status = 'Delayed' THEN 1 END) * 100.0 / COUNT(*)) AS delayed_shipment_rate
FROM orders
GROUP BY Route_ID
HAVING delayed_shipment_rate > 20;

-- Task 3.4: potential Route For optimization

-- Route No20 was the worst performing route having around 70% od delay rate for its order and low delivery agaents and low efficiency ration 

/* =====================================================
TASK 4: WAREHOUSE PERFORMANCE
===================================================== */

-- Task 4.1: Find the top 3 warehouses withthe highest average processing time. 

SELECT 
    Warehouse_ID,
    Processing_Time_Min,
    RANK() OVER (ORDER BY Processing_Time_Min DESC) AS top_ranking
FROM warehouses
LIMIT 3;

-- Task 4.2: Total vs delayed shipments
SELECT 
    Warehouse_ID,
    COUNT(CASE WHEN Delivery_Status = 'Delayed' THEN 1 END) AS delayed_shipments,
    COUNT(*) AS total_shipments
FROM orders
GROUP BY Warehouse_ID;

-- Task 4.3: Bottleneck warehouses
WITH average_pr_time AS (
    SELECT AVG(Processing_Time_Min) AS global_average
    FROM warehouses
)
SELECT 
    Warehouse_ID,
    Processing_Time_Min,
    Processing_Time_Min - global_average AS more_by
FROM warehouses, average_pr_time
WHERE Processing_Time_Min > global_average;

-- Task 4.4: Rank by on-time %
WITH on_time_del AS (
    SELECT 
        Warehouse_ID,
        (COUNT(CASE WHEN Delivery_Status = 'On Time' THEN 1 END) / COUNT(*)) * 100 AS on_time_delivery_per
    FROM orders
    GROUP BY Warehouse_ID
)
SELECT 
    Warehouse_ID,
    on_time_delivery_per,
    RANK() OVER (ORDER BY on_time_delivery_per DESC) AS on_time_ranking
FROM on_time_del;


/* =====================================================
TASK 5: DELIVERY AGENT PERFORMANCE
===================================================== */

-- Task 5.1: Rank agents per route
SELECT 
    Route_ID,
    Agent_ID,
    On_Time_Percentage,
    RANK() OVER (PARTITION BY Route_ID ORDER BY On_Time_Percentage DESC) AS ranking
FROM deliveryagents;

-- Task 5.2: Agents with <80% on-time
SELECT * 
FROM deliveryagents
WHERE On_Time_Percentage < 80;

-- Task 5.3: Top 5 vs Bottom 5 agents
WITH ranked AS (
    SELECT 
        Agent_ID,
        Avg_Speed_KM_HR,
        ROW_NUMBER() OVER (ORDER BY Avg_Speed_KM_HR DESC) AS fastest_rank,
        ROW_NUMBER() OVER (ORDER BY Avg_Speed_KM_HR ASC)  AS slowest_rank
    FROM deliveryagents
)
SELECT 
    Agent_ID,
    Avg_Speed_KM_HR,
    CASE 
        WHEN fastest_rank <= 5 THEN 'TOP 5 FASTEST'
        WHEN slowest_rank <= 5 THEN 'BOTTOM 5 SLOWEST'
    END AS category
FROM ranked
WHERE fastest_rank <= 5 OR slowest_rank <= 5
ORDER BY Avg_Speed_KM_HR DESC;


/* =====================================================
TASK 6: SHIPMENT TRACKING ANALYTICS
===================================================== */

-- Task 6.1: Last checkpoint
WITH last_checkpoint AS (
    SELECT 
        Order_ID,
        Checkpoint,
        Checkpoint_Time,
        RANK() OVER (PARTITION BY Order_ID ORDER BY Checkpoint DESC) AS rank_
    FROM shipment_tracking
)
SELECT 
    Order_ID,
    Checkpoint AS last_checkpoint,
    Checkpoint_Time
FROM last_checkpoint
WHERE rank_ = 1;

-- Task 6.2: Most common delay reasons
WITH delay_reason AS (
    SELECT 
        Delay_Reason,
        COUNT(*) AS reason_count
    FROM shipment_tracking
    WHERE Delay_Reason <> 'None'
    GROUP BY Delay_Reason
)
SELECT 
    Delay_Reason,
    reason_count,
    RANK() OVER (ORDER BY reason_count DESC) AS most_common_delay
FROM delay_reason;

-- Task 6.3: Orders with >2 delayed checkpoints
WITH delayed_checkpoint AS (
    SELECT 
        Order_ID,
        COUNT(CASE WHEN Delay_Reason <> 'None' THEN 1 END) AS delayed_checkpoint_count
    FROM shipment_tracking
    GROUP BY Order_ID
)
SELECT 
    Order_ID,
    delayed_checkpoint_count
FROM delayed_checkpoint
WHERE delayed_checkpoint_count > 2
ORDER BY delayed_checkpoint_count DESC;


/* =====================================================
TASK 7: ADVANCED KPI REPORTING
===================================================== */

-- Task 7.1: Avg delay per region
SELECT 
    r.Start_Location,
    ROUND(AVG(DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date)),1) AS average_delay_days
FROM orders o
JOIN routes r ON o.Route_ID = r.Route_ID
GROUP BY r.Start_Location;

-- or

select r.Start_Location ,round(avg(datediff(Actual_Delivery_Date,Expected_Delivery_Date)),1) as average_delay_days 
from orders o
join routes r 
on o.Route_ID=r.Route_ID 
where o.Delivery_Status = 'Delayed' 
group by r.Start_Location;

-- Task 7.2: On-time delivery %
SELECT 
    Route_ID,
    ROUND((COUNT(CASE WHEN Delivery_Status = 'On Time' THEN 1 END) / COUNT(*)) * 100,2) AS on_time_delivery_per
FROM orders
GROUP BY Route_ID;

-- Task 7.3: Avg traffic delay
WITH traffic_delay_count AS (
    SELECT 
        o.Route_ID,
        COUNT(*) AS total_shipments,
        COUNT(CASE WHEN s.Delay_reason = 'Traffic' THEN 1 END) AS traffic_d_count
    FROM shipment_tracking s
    JOIN orders o ON s.Order_ID = o.Order_ID
    GROUP BY o.Route_ID
)
SELECT 
    r.Route_ID,
    ROUND((td.traffic_d_count * r.Traffic_Delay_Min) / td.total_shipments,2) AS avg_traffic_delay_min
FROM traffic_delay_count td
JOIN routes r ON td.Route_ID = r.Route_ID;