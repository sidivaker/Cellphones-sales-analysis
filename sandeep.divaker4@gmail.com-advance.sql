--SQL Advance Case Study

/* Q1 List all the states in which we have customers who have bought cellphones  
from 2005 till today.  */ 
--BEGIN 
	
SELECT L.STATE
FROM DIM_LOCATION  AS L
LEFT JOIN FACT_TRANSACTIONS F
ON L.IDLOCATION=F.IDLOCATION
WHERE YEAR(F.DATE)>2005
group by L.STATE
order by STATE desc


--Q1--END

        
/* What state in the US is buying the most 'Samsung' cell phones?   */

--Q2--BEGIN
	


SELECT TOP 1 K.Country,K.State,A.Manufacturer_Name ,SUM(K.QUANTITY) TOTAL_BUYING
   FROM 
   (
   SELECT F.IDModel,F.IDLocation,L.Country,L.State ,F.Quantity
   FROM FACT_TRANSACTIONS AS F
   LEFT JOIN DIM_LOCATION  AS L
   ON F.IDLocation=L.IDLocation
   )AS K

   LEFT JOIN
  (
  SELECT O.IDModel,O.IDManufacturer,M.Manufacturer_Name
  FROM DIM_MODEL AS O
  LEFT JOIN  DIM_MANUFACTURER AS M
  ON O.IDMANUFACTURER =M.IDManufacturer) AS A
  ON K.IDModel=A.IDModel
   WHERE  K.COUNTRY = 'US'
           AND
     A.Manufacturer_Name = 'SAMSUNG'
  GROUP BY K.Country,K.State,A.Manufacturer_Name
  ORDER BY TOTAL_BUYING DESC



--Q2--END


 /* Show the number of transactions for each model per zip code per state.  */
--Q3--BEGIN      
	
  SELECT K.IDModel,K.State,K.ZipCode,  SUM (K.TotalPrice) AS TRANACTION_
  FROM(
   SELECT F.IDModel,L.ZipCode,L.State,F.TotalPrice
   FROM FACT_TRANSACTIONS AS F
   LEFT JOIN  DIM_LOCATION   AS L
   ON F.IDLocation =L.IDLocation)K
   LEFT JOIN DIM_MODEL AS M
   ON K.IDModel=M.IDModel
   GROUP BY K.IDModel,K.State,K.ZipCode

--Q3--END


/* Show the cheapest cellphone (Output should contain the price also) */
--Q4--BEGIN


 SELECT TOP 1 O.IDModel,O.Model_Name,M.Manufacturer_Name,O.Unit_price
 FROM DIM_MODEL AS O
 LEFT JOIN DIM_MANUFACTURER AS M
 ON O.IDManufacturer=M.IDManufacturer
 ORDER BY O.Unit_price


--Q4--END

/* Find out the average price for each model in the top5 manufacturers in  
terms of sales quantity and order by average price.   */

--Q5--BEGIN
 
select Model_Name, avg(Unit_price) as 'Average Price'
from DIM_MODEL
where IDManufacturer in (
								select top 5 O.IDManufacturer 
								--sum(Quantity) as [Sales Quantity],avg(Unit_price) as [Average Price]
								from FACT_TRANSACTIONS as T 
								inner join DIM_MODEL as O
										on T.IDModel=O.IDModel
								inner join DIM_MANUFACTURER as M
								      on M.IDManufacturer=O.IDManufacturer
								group by O.IDManufacturer
								order by avg(Unit_price) desc  ) 
Group by  Model_Name
     

--Q5--END


/*List the names of the customers and the average amount spent in 2009,  
where the average is higher than 500  */
--Q6--BEGIN


    SELECT  C.Customer_Name, AVG(F.TotalPrice) AS AVG_SPENT
    FROM DIM_CUSTOMER   AS C
    LEFT JOIN  FACT_TRANSACTIONS  AS F
    ON C.IDCUSTOMER=F.IDCustomer
	WHERE YEAR(F.DATE)= 2009   
	GROUP BY  C.Customer_Name
	HAVING AVG(F.TotalPrice) > 500
	order by AVG_SPENT desc

--Q6--END


/*List if there is any model that was in the top 5 in terms of quantity,  
simultaneously in 2008, 2009 and 2010   */
--Q7--BEGIN  
	
	SELECT A.IDModel
	FROM
	(
     SELECT TOP 5 IDMODEL,   SUM(QUANTITY) AS TOTAL_QTY
     FROM FACT_TRANSACTIONS  
     WHERE YEAR(DATE)= 2008
     GROUP BY IDMODEL
     ORDER BY TOTAL_QTY DESC) AS A
	 INTERSECT
    SELECT B.IDModel
	FROM (
    SELECT TOP 5 IDMODEL,   SUM(QUANTITY) AS TOTAL_QTY
     FROM FACT_TRANSACTIONS 
     WHERE YEAR(DATE)= 2009
     GROUP BY IDMODEL
     ORDER BY TOTAL_QTY DESC) AS B
     INTERSECT
	 SELECT C.IDModel
	 FROM (
     SELECT TOP 5 IDMODEL,   SUM(QUANTITY) AS TOTAL_QTY
     FROM FACT_TRANSACTIONS 
     WHERE YEAR(DATE)= 2010
     GROUP BY IDMODEL
     ORDER BY TOTAL_QTY DESC) AS C

--Q7--END	

/*Show the manufacturer with the 2nd top sales in the year of 2009 and the  
manufacturer with the 2nd top sales in the year of 2010.*/

--Q8--BEGIN
   
          SELECT *
		  FROM (
         
          select  R.Manufacturer_Name,R.years,sum (R.TotalPrice) as total_sale,
		  rank() OVER (PARTITION BY R.years ORDER BY SUM(R.TotalPrice) DESC) AS sales_rank
          from (
          SELECT K.Manufacturer_Name,year (F.Date) as years,F.TotalPrice  
          FROM (
          SELECT D.IDModel,D.IDManufacturer,M.Manufacturer_Name
          FROM  DIM_MODEL AS D
          LEFT JOIN DIM_MANUFACTURER AS M
          ON D.IDManufacturer=M.IDManufacturer) AS K
          LEFT JOIN
          FACT_TRANSACTIONS AS F
          ON K.IDModel=F.IDModel
          WHERE YEAR(F.Date) IN (2009,2010))R
		  group by R.Manufacturer_Name,R.years) AS A
		  WHERE sales_rank=2

--Q8--END

 /*Show the manufacturers that sold cellphones in 2010 but did not in 2009. */

--Q9--BEGIN

  
       SELECT M.Manufacturer_Name
       FROM DIM_MANUFACTURER AS M
       LEFT JOIN DIM_MODEL D
       ON M.IDManufacturer=D.IDManufacturer
       LEFT JOIN FACT_TRANSACTIONS AS F
       ON  D.IDModel= F.IDModel
       WHERE YEAR (F.Date) = 2010
       GROUP BY M.Manufacturer_Name

       EXCEPT
    
       SELECT M.Manufacturer_Name
       FROM DIM_MANUFACTURER AS M
       LEFT JOIN DIM_MODEL D
       ON M.IDManufacturer=D.IDManufacturer
       LEFT JOIN FACT_TRANSACTIONS AS F
       ON  D.IDModel= F.IDModel
       WHERE YEAR (F.Date) = 2009
 
      

--Q9--END



/* Find top 100 customers and their average spend, average quantity by each  
year. Also find the percentage of change in their spend. */

--Q10--BEGIN
WITH TOP10CUST
AS(

     SELECT TOP 10 IDCustomer,AVG (Quantity) AS AVG_QTY ,AVG (TotalPrice) AS AVG_SPEND
     FROM FACT_TRANSACTIONS 
	 GROUP BY  YEAR (DATE),IDCustomer
	 ORDER BY  AVG_SPEND DESC,AVG_QTY DESC
	 ),
	 YEAR_WISE_SPEND
	 AS(
	 SELECT Y.Date,T.IDCustomer,T.AVG_SPEND,T.AVG_QTY
	 FROM TOP10CUST AS T
	 INNER JOIN FACT_TRANSACTIONS AS Y
	 ON T.IDCustomer=Y.IDCustomer
	 ),
	 avg_spend_cahnge
	 as (
      SELECT Y.Date,Y.IDCustomer,Y.AVG_SPEND,Y.AVG_QTY
      FROM YEAR_WISE_SPEND AS Y
     
	  ),
	  year_spend_change 
	  as(
	  select z.IDCustomer,z.Date,z.AVG_SPEND,z.AVG_QTY ,
	  lag (z.AVG_SPEND,1) over (partition by z.IDCustomer order by year(z.date) ) as previous_avg_spend
	  from avg_spend_cahnge  as z
	  )
	  select *,(AVG_SPEND-previous_avg_spend/previous_avg_spend*100)as '% change'
	  from year_spend_change 



--Q10--END



     
	 
    

	




