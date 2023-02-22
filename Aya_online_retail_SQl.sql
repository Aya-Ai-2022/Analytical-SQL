
--write at least 5 analytical SQL queries that tells a story about the data 
--write small description about the business meaning behind each query

Describe tableretail;

Select count( distinct customer_id ) "Number of Customers"from tableretail;


select distinct country from tableretail;

 Select count( distinct STOCKCODE ) as "Number of Products"from tableretail;

SELECT min(TO_DATE(INVOICEDATE,  'MM/DD/YYYY HH24:MI')) as StartDate, max(TO_DATE(INVOICEDATE,  'MM/DD/YYYY HH24:MI')) as LastDate from tableretail;

Select count( distinct invoice ) "Number of Transactions"from tableretail;

--I changed invoicedate to date type
/*Alter table tableretail ADD (new_col DATE);
Update tableretailSET new_col=TO_DATE(INVOICEDATE,'MM/DD/YYYY HH24:MI');
Create table onlineretail as select INVOICE, STOCKCODE, QUANTITY, PRICE, CUSTOMER_ID, COUNTRY, NEW_COL from tableretail;
 Alter table onlineretail rename column NEW_COL to INVOICEDATE ;
*/





/*
Dataset Story
• This dataset describes UK Sales between DEC 2010 - DEC 2011 .
• The product catalog of this company includes 2335 different products..
• There is also information about 717 transactions from 110 customers.
--1-we want to calculate the highest revenue for highest day in each month. 
*/
  SELECT  t.month_,t.revenue  FROM( SELECT invoicedate, EXTRACT( MONTH FROM invoicedate )   || '-' || EXTRACT( YEAR FROM invoicedate ) as month_,QUANTITY*PRICE as revenue , 
  RANK() OVER( PARTITION BY EXTRACT(MONTH FROM invoicedate) ,EXTRACT(year FROM invoicedate) ORDER BY  (QUANTITY*PRICE) DESC) order_rank FROM onlineretail ) t
WHERE order_rank = 1
ORDER BY invoicedate;



--We noticed a significant raise for revenue in Aug 2011 then an aggressive decline So we must try to study this.
---2-Top 10  Products that have been ordered 
Select stockcode, quantity, rnk
    from (select stockcode, quantity,
   dense_rank() over (order by quantity desc) rnk  from onlineretail order by quantity desc )t  where rnk between 1 and 10 order by quantity desc;




---3-Summary of number of transactions for each customer for each month
SELECT *FROM
  (SELECT EXTRACT(MONTH FROM invoicedate)  AS month_val,
    Customer_id,invoice FROM onlineretail
  ) PIVOT (  count(invoice) for month_val in(01  ,02,03,04,05,6,7,8,9,10,11,12));

--3-Summary of Sales for each customer for each month 
SELECT *FROM
  (SELECT EXTRACT(MONTH FROM invoicedate)  AS month_val,
    Customer_id,invoice FROM onlineretail
  ) PIVOT ( SUM(revenue) for month_val in(01  ,02,03,04,05,6,7,8,9,10,11,12));


----4-what is the last highest amount for which an order was sold by product(stockcode) 
 SELECT stockcode, quantity, LAG(quantity, 1) OVER ( PARTITION BY stockcode
  ORDER BY quantity DESC) last_highest_amount
FROM onlineretail
ORDER BY stockcode, quantity DESC;



----5-Top 1% product that occur highest revenue
select distinct* from (select stockcode ,(quantity*price) as revenue,
round(PERCENT_RANK() over(order by (quantity*price)  )*100,2) as rnk
from onlineretail) where rnk >99 
order by rnk desc;
----

---*********************************************************************--------------Customer Segmentation--------------************************************-------------
SELECT customer_id, 
	     Recency,Frequency,Monetary,Recency_Score ,round(((Monetary_Score+Frequency_Score)/2),0) as FM_Score
	    
	           , CASE
	   WHEN  (round(((Monetary_Score+Frequency_Score)/2),0))+(Recency_Score*10) IN (55,54,45) THEN 'Champions'    
	   WHEN (round(((Monetary_Score+Frequency_Score)/2),0))+(Recency_Score*10) IN (33,43,42,52) THEN 'Potential Loyalists'                    
	   WHEN (round(((Monetary_Score+Frequency_Score)/2),0))+(Recency_Score*10) IN (34, 35, 44, 53) THEN 'Loyal Customers'                                   
	   WHEN (round(((Monetary_Score+Frequency_Score)/2),0))+(Recency_Score*10) IN (51) THEN 'Recent Customers'                         
	   WHEN (round(((Monetary_Score+Frequency_Score)/2),0))+(Recency_Score*10) IN (31,41) THEN 'Promising'                                
	   WHEN (round(((Monetary_Score+Frequency_Score)/2),0))+(Recency_Score*10) IN (22,32,23,21) THEN 'Customers Need Attention' ---21 not in document but I see it is the nearest segmen
       WHEN (round(((Monetary_Score+Frequency_Score)/2),0))+(Recency_Score*10) IN (24,25,13) THEN 'At Risk' 
       WHEN (round(((Monetary_Score+Frequency_Score)/2),0))+(Recency_Score*10) IN (15,14) THEN 'Can not lose them' 
       WHEN (round(((Monetary_Score+Frequency_Score)/2),0))+(Recency_Score*10) IN (12) THEN 'Hibernating' 
       WHEN (round(((Monetary_Score+Frequency_Score)/2),0))+(Recency_Score*10) IN (11) THEN 'Lost' 
	   
	                                     
       END "Customer Segment"
FROM (
      SELECT customer_id, Recency,Frequency,Monetary,
             NTILE(4) OVER (ORDER BY LastOrderDate) AS Recency_Score,
             NTILE(4) OVER (ORDER BY Frequency) AS Frequency_Score,
             NTILE(4) OVER (ORDER BY Monetary) AS Monetary_Score
             from(
SELECT
	customer_id,
	sum(quantity*price)AS Monetary,
	COUNT(invoice) AS Frequency,
	MAX(invoicedate) AS LastOrderDate,
	(SELECT MAX(invoicedate) FROM onlineretail) AS MaxOrderDate, round(min((sysdate-4050)-invoicedate),0) AS Recency ---select (sysdate-4050) from dual; ------I tried Several dates and choose day near to last day of onlineretail invoicedate(1/18/2012 9:47:32 AM)
FROM onlineretail
GROUP BY CUSTOMER_id));

----------------------
