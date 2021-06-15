CREATE TABLE `crm-bads7105.super.cust_move` AS
SELECT MONTH_YEAR,
       SUM(COALESCE(NEW_SUM,0)) NEW_SUM,
       SUM(COALESCE(REPEAT_SUM,0)) REPEAT_SUM,
       SUM(COALESCE(REACTIVATED_SUM,0)) REACTIVATED_SUM,
       SUM(COALESCE(CHURN_SUM,0)) CHURN_SUM,
       FROM (
            select  MONTH_YEAR,
                    CASE WHEN CUST_TYPE = 'NEW' THEN  NO_CUST END AS NEW_SUM,
                    CASE WHEN CUST_TYPE = 'REPEAT' THEN  NO_CUST END AS REPEAT_SUM,
                    CASE WHEN CUST_TYPE = 'REACTIVATED' THEN  NO_CUST END AS REACTIVATED_SUM,
                    CASE WHEN CUST_TYPE = 'CHURN' THEN  NO_CUST END AS CHURN_SUM
            FROM (
                SELECT  TRAN_DATE AS MONTH_YEAR, CUST_TYPE,COUNT(CUST_CODE) AS NO_CUST
                 FROM (
                        SELECT 
                            CUST_CODE,TRAN_DATE,FIRST_TIME,LAG_TIME,LEAD_TIME,
                            CASE WHEN TRAN_DATE = FIRST_TIME THEN 'NEW'
                                WHEN DATE_DIFF(TRAN_DATE,LAG_TIME,MONTH) < 3 THEN 'REPEAT'
                                WHEN DATE_DIFF(TRAN_DATE,LAG_TIME,MONTH) >= 3 THEN 'REACTIVATED'
                            END AS CUST_TYPE
                        FROM (             
                                SELECT
                                    CUST_CODE,TRAN_DATE,
                                    MIN(TRAN_DATE) OVER (PARTITION BY CUST_CODE ORDER BY TRAN_DATE) AS FIRST_TIME,
                                    LAG(TRAN_DATE) OVER (PARTITION BY CUST_CODE ORDER BY TRAN_DATE) AS LAG_TIME,
                                    COALESCE(LEAD(TRAN_DATE) OVER (PARTITION BY CUST_CODE ORDER BY TRAN_DATE) , MAX(TRAN_DATE) OVER()) AS LEAD_TIME
                                FROM (
                                        select distinct DATE_TRUNC(parse_date('%Y%m%d', CAST(SHOP_DATE AS STRING)),MONTH) AS TRAN_DATE,CUST_CODE
                                        FROM `crm-bads7105.super.trans`
                                        WHERE CUST_CODE IS NOT NULL
                                    )

                            )
                        union all 
                                SELECT 
                                    CUST_CODE,DATE_ADD(TRAN_DATE,INTERVAL 3 MONTH) TRAN_DATE,FIRST_TIME,LAG_TIME,LEAD_TIME,
                                    CASE WHEN DATE_DIFF(LEAD_TIME,TRAN_DATE,MONTH) >= 3  THEN 'CHURN' END AS CUST_TYPE
                                FROM (             
                                        SELECT
                                            CUST_CODE,TRAN_DATE,
                                            MIN(TRAN_DATE) OVER (PARTITION BY CUST_CODE ORDER BY TRAN_DATE) AS FIRST_TIME,
                                            LAG(TRAN_DATE) OVER (PARTITION BY CUST_CODE ORDER BY TRAN_DATE) AS LAG_TIME,
                                            COALESCE(LEAD(TRAN_DATE) OVER (PARTITION BY CUST_CODE ORDER BY TRAN_DATE) , MAX(TRAN_DATE) OVER()) AS LEAD_TIME
                                        FROM (
                                                select distinct DATE_TRUNC(parse_date('%Y%m%d', CAST(SHOP_DATE AS STRING)),MONTH) AS TRAN_DATE,CUST_CODE
                                                FROM `crm-bads7105.super.trans`
                                                WHERE CUST_CODE IS NOT NULL
                                            )

                            )
                                where  CASE WHEN DATE_DIFF(LEAD_TIME,TRAN_DATE,MONTH) >= 3  THEN 'CHURN'END  = 'CHURN'
                            )
                GROUP BY MONTH_YEAR,
                        CUST_TYPE
                        )
                    )
GROUP BY MONTH_YEAR
ORDER BY MONTH_YEAR

#Get data
SELECT *
FROM `crm-bads7105.super.cust_move`

