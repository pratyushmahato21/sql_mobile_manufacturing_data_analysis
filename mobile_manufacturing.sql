--SQL Advance Case Study

--Q1--BEGIN 

SELECT DISTINCT
    ("state")
FROM
    [dbo].[DIM_LOCATION]
WHERE
    idlocation IN (
        SELECT
            idlocation
        FROM
            [dbo].[FACT_TRANSACTIONS]
        WHERE
            "date" >= '2005-01-01');


--Q1--END


--Q2--BEGIN


SELECT 
    TOP 1
	[dbo].[DIM_LOCATION].state, 
	SUM([dbo].[FACT_TRANSACTIONS].totalprice) AS highest_sales
FROM 
	[dbo].[DIM_MODEL]
	LEFT OUTER JOIN  [dbo].[DIM_MANUFACTURER] ON [dbo].[DIM_MODEL].idmanufacturer = [dbo].[DIM_MANUFACTURER].idmanufacturer
	LEFT OUTER JOIN [dbo].[FACT_TRANSACTIONS] ON [dbo].[FACT_TRANSACTIONS].idmodel = [dbo].[DIM_MODEL].idmodel
	LEFT OUTER JOIN [dbo].[DIM_LOCATION] ON [dbo].[DIM_LOCATION].idlocation = [dbo].[FACT_TRANSACTIONS].idlocation
WHERE 
	(
	[dbo].[DIM_MANUFACTURER].manufacturer_name = 'Samsung' 
	AND [dbo].[DIM_LOCATION].country = 'US'
	)
GROUP BY 
	[dbo].[DIM_LOCATION].state
ORDER BY 
	highest_sales DESC
;

--Q2--END


--Q3--BEGIN      

select
  [dbo].[FACT_TRANSACTIONS].idmodel,
  [dbo].[DIM_LOCATION].zipcode,
  [dbo].[DIM_LOCATION].state,
  count(*) as txn_count
from
  [dbo].[FACT_TRANSACTIONS]
  left outer join [dbo].[DIM_LOCATION] on [dbo].[FACT_TRANSACTIONS].idlocation = [dbo].[DIM_LOCATION].idlocation
group by
  [dbo].[FACT_TRANSACTIONS].idmodel,
  [dbo].[DIM_LOCATION].state,
  [dbo].[DIM_LOCATION].zipcode
order by
  [dbo].[FACT_TRANSACTIONS].idmodel,
  [dbo].[DIM_LOCATION].state,
  [dbo].[DIM_LOCATION].zipcode;

--Q3--END

--Q4--BEGIN

select
  [dbo].[DIM_MODEL].idmodel,
  [dbo].[DIM_MODEL].model_name,
  [dbo].[DIM_MANUFACTURER].manufacturer_name,
  [dbo].[DIM_MODEL].unit_price
from
  [dbo].[DIM_MODEL]
  left outer join [dbo].[DIM_MANUFACTURER] on [dbo].[DIM_MODEL].idmanufacturer = [dbo].[DIM_MANUFACTURER].idmanufacturer
where
  unit_price = (
    select
      min(unit_price)
    from
      [dbo].[DIM_MODEL]
  );

--Q4--END

--Q5--BEGIN

with top_5_manufacturers as (
  select 
    TOP 5
    [dbo].[DIM_MANUFACTURER].idmanufacturer,
    count([dbo].[FACT_TRANSACTIONS].totalprice) as sales_qty
  from
    [dbo].[FACT_TRANSACTIONS]
    left outer join [dbo].[DIM_MODEL] on [dbo].[FACT_TRANSACTIONS].idmodel = [dbo].[DIM_MODEL].idmodel
    left outer join [dbo].[DIM_MANUFACTURER] on [dbo].[DIM_MODEL].idmanufacturer = [dbo].[DIM_MANUFACTURER].idmanufacturer
  group by
    [dbo].[DIM_MANUFACTURER].idmanufacturer
  order by
    sales_qty desc
  
)
select
  [dbo].[DIM_MODEL].model_name,
  ROUND(AVG([dbo].[FACT_TRANSACTIONS].TotalPrice), 2) as avg_price
from
  [dbo].[FACT_TRANSACTIONS]
  left outer join [dbo].[DIM_MODEL] on [dbo].[FACT_TRANSACTIONS].idmodel = [dbo].[DIM_MODEL].idmodel
where
  [dbo].[DIM_MODEL].idmanufacturer in (
    select
      top_5_manufacturers.idmanufacturer
    from
      top_5_manufacturers
  )
group by
  [dbo].[DIM_MODEL].model_name
order by
  avg_price desc;

--Q5--END

--Q6--BEGIN

select
  dim_customer.customer_name,
  round(avg([dbo].[FACT_TRANSACTIONS].TotalPrice), 2) as avg_spend
from
  [dbo].[FACT_TRANSACTIONS]
  left outer join dim_customer on [dbo].[FACT_TRANSACTIONS].idcustomer = dim_customer.idcustomer
where
    year(
      [dbo].[FACT_TRANSACTIONS].date
  ) = '2009'
group by
  dim_customer.customer_name
having
  avg([dbo].[FACT_TRANSACTIONS].TotalPrice) > 500;

--Q6--END
	
--Q7--BEGIN  

SELECT idmodel
FROM (
    SELECT idmodel, YEAR(Date) AS transaction_year, 
           RANK() OVER (PARTITION BY YEAR(Date) ORDER BY COUNT(*) DESC) AS model_rank
    FROM [dbo].[FACT_TRANSACTIONS]
    WHERE YEAR(Date) IN (2008, 2009, 2010)
    GROUP BY idmodel, YEAR(Date)
) AS ranked_models
WHERE model_rank <= 5
GROUP BY idmodel
HAVING COUNT(DISTINCT transaction_year) = 3;


--Q7--END

--Q8--BEGIN

WITH manu_sales_table AS (
    SELECT
        [dbo].[DIM_MANUFACTURER].manufacturer_name,
        year([dbo].[FACT_TRANSACTIONS].date) AS 'year',
        sum([dbo].[FACT_TRANSACTIONS].TotalPrice) AS total_sales,
        dense_rank() OVER (PARTITION BY (year([dbo].[FACT_TRANSACTIONS].date)) ORDER BY sum([dbo].[FACT_TRANSACTIONS].TotalPrice) DESC) AS sales_rank
FROM
    [dbo].[FACT_TRANSACTIONS]
    LEFT OUTER JOIN [dbo].[DIM_MODEL] ON [dbo].[FACT_TRANSACTIONS].idmodel = [dbo].[DIM_MODEL].idmodel
    LEFT OUTER JOIN [dbo].[DIM_MANUFACTURER] ON [dbo].[DIM_MANUFACTURER].idmanufacturer = [dbo].[DIM_MODEL].idmanufacturer
    WHERE
        year([dbo].[FACT_TRANSACTIONS].date) IN (2009, 2010)
    GROUP BY
        [dbo].[DIM_MANUFACTURER].manufacturer_name,
        year([dbo].[FACT_TRANSACTIONS].date)
    ORDER BY
        year([dbo].[FACT_TRANSACTIONS].date),
        sum([dbo].[FACT_TRANSACTIONS].TotalPrice) DESC
        OFFSET 0 ROWS
    )
SELECT 
    * 
    FROM 
        manu_sales_table
    WHERE
        sales_rank = 2;


--Q8--END

--Q9--BEGIN

SELECT DISTINCT
    ([dbo].[DIM_MANUFACTURER].manufacturer_name)
FROM
    [dbo].[FACT_TRANSACTIONS]
    LEFT OUTER JOIN [dbo].[DIM_MODEL] ON [dbo].[FACT_TRANSACTIONS].idmodel = [dbo].[DIM_MODEL].idmodel
    LEFT OUTER JOIN [dbo].[DIM_MANUFACTURER] ON [dbo].[DIM_MODEL].idmanufacturer = [dbo].[DIM_MANUFACTURER].idmanufacturer
WHERE
    year([dbo].[FACT_TRANSACTIONS].date) IN (2010)
EXCEPT
SELECT DISTINCT
    ([dbo].[DIM_MANUFACTURER].manufacturer_name)
FROM
    [dbo].[FACT_TRANSACTIONS]
    LEFT OUTER JOIN [dbo].[DIM_MODEL] ON [dbo].[FACT_TRANSACTIONS].idmodel = [dbo].[DIM_MODEL].idmodel
    LEFT OUTER JOIN [dbo].[DIM_MANUFACTURER] ON [dbo].[DIM_MODEL].idmanufacturer = [dbo].[DIM_MANUFACTURER].idmanufacturer
WHERE
    year([dbo].[FACT_TRANSACTIONS].date) IN (2009);


--Q9--END

--Q10--BEGIN

WITH cust_data AS (
    SELECT
        year([dbo].[FACT_TRANSACTIONS].date) AS 'year',
        dim_customer.customer_name,
        round(avg([dbo].[FACT_TRANSACTIONS].totalprice), 2) AS avg_spend,
        round(avg([dbo].[FACT_TRANSACTIONS].quantity), 1) AS avg_qty
    FROM
        [dbo].[FACT_TRANSACTIONS]
        LEFT OUTER JOIN dim_customer ON [dbo].[FACT_TRANSACTIONS].idcustomer = dim_customer.idcustomer
GROUP BY
    year([dbo].[FACT_TRANSACTIONS].date),
    dim_customer.customer_name
ORDER BY
    'year',
    avg_spend DESC,
    avg_qty DESC
    OFFSET 0 ROWS
),
cust_data_change AS (
    SELECT
        customer_name,
        cust_data.year,
        avg_qty,
        avg_spend,
        lag(avg_spend) OVER (PARTITION BY customer_name ORDER BY cust_data.year asc) AS prev_avg_spend
    FROM
        cust_data
        
)
SELECT 
    TOP 100
    cust_data_change.year,
    customer_name,
    avg_qty,
    avg_spend,
    round(((avg_spend - prev_avg_spend) / prev_avg_spend * 100), 2) AS "%_spend_change"
FROM
    cust_data_change
ORDER BY
    avg_spend DESC
;

--Q10--END