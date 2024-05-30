--RFM DATAOM CALISMASI

SELECT top 10 * FROM superstoredb.dbo.superstore

CREATE TABLE RFM_DATAOM (
    CustomerID varchar(200),
    Recency int,
    Frequency int,
    Monetary int,
    Tenure int,
    Basket_Size float,
    Recency_Scale int,
    Frequency_Scale int,
    Monetary_Scale int,
    Tenure_Scale int,
    RF_Segment varchar(50) ,
    RFM_SEGMENT VARCHAR(50)
)

SELECT * FROM RFM_DATAOM

-- RFM MEKTRIKLERIN OLUŞTURMASI

SELECT CustomerID,
DATEDIFF(day, MIN(OrderDate),'20180101') as Tenure,
DATEDIFF(day, MAX(OrderDate),'20180101') as Recency,
COUNT(DISTINCT OrderID) as Frequency, 
SUM(Sales) as Monetary, 
SUM(Sales) / COUNT(DISTINCT OrderID) as BasketSize,
Null recency_score,
Null Frequency_score,
Null Monetary_score ,
NULL RF_Segment ,
NULL RFM_Segment
INTO RFM_DATAOM_AOM
from superstoredb.dbo.superstore
group by CustomerID


SELECT * FROM RFM_DATAOM_AOM

---###### SCALE HESAPLARI #######-----

--RECENCY SCALE OLUSTURMA

UPDATE RFM_DATAOM_AOM SET recency_score= 
( select RANK from
 (
    SELECT  *, NTILE(5) OVER( ORDER BY Recency desc) Rank
    FROM RFM_DATAOM_AOM
) t
WHERE CustomerID = RFM_DATAOM_AOM.CustomerID)

--FREKANS SCALE OLUSTURMA

UPDATE RFM_DATAOM_AOM SET Frequency_score =
(SELECT FREKANS_SCORE FROM 
 (SELECT CustomerID ,
CASE
WHEN Frequency between 9 and 17 THEN  5
WHEN Frequency between 7 and 8 THEN  4
WHEN Frequency between 5 and 6 THEN  3
WHEN Frequency = 4 THEN  2
WHEN Frequency between 1 and 3 THEN  1
ELSE ''
END AS FREKANS_SCORE
 from RFM_DATAOM_AOM ) t
where CustomerID=RFM_DATAOM_AOM.CustomerID)

--MONETARY HESAPLAMA

UPDATE RFM_DATAOM_AOM SET Monetary_score =
(SELECT MONETARTY_SCORE_ FROM 
 (SELECT CustomerID ,
CASE
WHEN Monetary between 0 and 1000 THEN  1
WHEN Monetary between 1001 and 2000 THEN  2
WHEN Monetary between 2001 and 3000 THEN  3
WHEN Monetary between 3001 and 5000 THEN  4
WHEN Monetary>= 5001 THEN  5
ELSE ''
END AS MONETARTY_SCORE_
 from RFM_DATAOM_AOM ) t
where CustomerID=RFM_DATAOM_AOM.CustomerID)

--RF_Segment HESAPLAMA
UPDATE RFM_DATAOM_AOM SET RF_Segment = 'Need_Attention'
WHERE Recency_Score LIKE '[3]' AND Frequency_Score LIKE '[3]'
UPDATE RFM_DATAOM_AOM SET RF_Segment = 'Hibernating'
WHERE Recency_Score LIKE '[1-2]' AND Frequency_Score LIKE '[1-2]'
UPDATE RFM_DATAOM_AOM SET RF_Segment ='At_Risk' 
WHERE Recency_Score LIKE  '[1-2]' AND Frequency_Score LIKE '[3-4]'  
UPDATE RFM_DATAOM_AOM SET RF_Segment ='Cant_Loose' 
WHERE Recency_Score LIKE  '[1-2]' AND Frequency_Score LIKE '[5]'  
UPDATE RFM_DATAOM_AOM SET RF_Segment ='About_to_Sleep' 
WHERE Recency_Score LIKE  '[3]' AND Frequency_Score LIKE '[1-2]'  
UPDATE RFM_DATAOM_AOM SET RF_Segment ='Loyal_Customers' 
WHERE Recency_Score LIKE  '[3-4]' AND Frequency_Score LIKE '[4-5]' 
UPDATE RFM_DATAOM_AOM SET RF_Segment ='Promising' 
WHERE Recency_Score LIKE  '[4]' AND Frequency_Score LIKE '[1]' 
UPDATE RFM_DATAOM_AOM SET RF_Segment ='New_Customers' 
WHERE Recency_Score LIKE  '[5]' AND Frequency_Score LIKE '[1]' 
UPDATE RFM_DATAOM_AOM SET RF_Segment ='Potential_Loyalists' 
WHERE Recency_Score LIKE  '[4-5]' AND Frequency_Score LIKE '[2-3]' 
UPDATE RFM_DATAOM_AOM SET RF_Segment ='Champions' 
WHERE Recency_Score LIKE  '[5]' AND Frequency_Score LIKE '[4-5]'

--RFM_Score HESAPLAMA
ALTER TABLE RFM_DATAOM_AOM ADD RFM_Score AS (recency_score+Frequency_score+Monetary_score)

--RFM Segmenti Hesaplama
UPDATE RFM_DATAOM_AOM SET RFM_Segment =
(SELECT RFM_Score_ FROM 
 (SELECT CustomerID ,
CASE
WHEN Rfm_Score between 0 and 6 THEN 'IRON'
WHEN Rfm_Score between 7 and 8 THEN 'BRONZE'
WHEN Rfm_Score between 9 and 10 THEN  'SILVER'
WHEN Rfm_Score between 11 and 12 THEN  'GOLD'
WHEN Rfm_Score between 13 and 14 THEN  'PLANTINIUM'
WHEN Rfm_Score>= 14 THEN 'PLATINIUM PLUS'
ELSE ''
END AS RFM_SCORE_
 from RFM_DATAOM_AOM ) t
where CustomerID=RFM_DATAOM_AOM.CustomerID)

--RFM Etiket Numarası Ekleme
ALTER TABLE RFM_DATAOM_AOM 
ADD RFM_Etiket_No 
as (CONCAT(CAST(recency_score as varchar),'-',CAST(Frequency_score as varchar),'-',CAST(Monetary_score as varchar)))

--RF Etiket Numarası Ekleme
ALTER TABLE RFM_DATAOM_AOM 
ADD RF_Etiket_No 
as (CONCAT(CAST(recency_score as varchar),'-',CAST(Frequency_score as varchar)))
