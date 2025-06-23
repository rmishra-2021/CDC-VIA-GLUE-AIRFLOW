
This Project will show you a working example of:

1. Glue to identify data structure and create a catalog of data files in the S3 source bucket.

2. Query data in Athena using Data Catalog to capture CDC in another S3 target bucket.

3. Step 2 is all written in AWS airflow (MWAA) via DBT (jinja)

![Computer](flow_diagram_better.png)








































--show total business change from all events before and after changes 
create table sporting_event_ticket_initial as 
WITH temp AS (select * from sporting_event_ticket where id in (select id from 
    (select id , count(distinct op) as op_count from sporting_event_ticket group by id having count(distinct op) > 1 order by id )
    )
    ) 
select * from (
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY dms_cdc_timestamp ASC ) AS rn
    FROM temp
) sub
WHERE rn = 1 
) where op = 'I'; -- result: count=344745

select sum(initial_ticket_price) as initial_business , sum(cdc_ticket_price) as cdc_business
from(
select i.id as id , i.ticket_price as initial_ticket_price ,c.ticket_price as cdc_ticket_price
from sporting_event_ticket_initial i inner join sporting_event_ticket_cdc c
on i.id=c.id);












INSTALLATIONS:
--------------
AWSCLI
Last login: Wed Mar 26 10:01:15 on ttys000
(base) ritumishra@Ritus-MacBook-Air ~ % aws --version
aws-cli/2.25.3 Python/3.12.9 Darwin/24.1.0 source/arm64
(base) ritumishra@Ritus-MacBook-Air ~ % 


REPO:
https://github.com/uturndata-public/data-engineering-tech-challenge-ritu-mishra.git
git clone https://rmishra-2021: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@github.com/uturndata-public/data-engineering-tech-challenge-ritu-mishra.git
ERROR:Write access to repo not granted

DBEAVER
brew install --cask dbeaver-community

TERRAFORM
Terraform v1.11.3 on darwin_arm64

export AWS_PROFILE=uturn 


Git rmishra-2021/Manj.._111
git clone https://username:password@github.com/username/repository.git
git clone https://github.com/YOUR-USERNAME/YOUR-REPOSITORY (***.git)
git clone https://username:token@github.com/user/repo

Name:
Ritu-Git-Token
Token:
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





Steps:
export AWS_PROFILE=uturn 
terraform apply -auto-approve 

cd /Users/ritumishra/Documents/uturn/Repo/data-engineering-tech-challenge-ritu-mishra-main/sample_raw_data
(base) ritumishra@Ritus-MacBook-Air sample_raw_data % aws s3 cp . s3://uturnrawdata --recursive 

aws glue start-crawler --name uturn-multi-table-crawler




STARTING WORK WITH FEWER RECORDS:(THIS IS THE SOLUTION)
-------------------------------------------------------
CREATE TABLE temp1 AS 
select id , count(distinct op) as op_count from sporting_event_ticket group by id having count(distinct op) > 1 order by id limit 10
NOTE:In actual code , we will remove the limit

CREATE TABLE sporting_event_ticket_small as
select * from sporting_event_ticket where id in (select id from temp1)

select * from (
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY dms_cdc_timestamp DESC) AS rn
    FROM sporting_event_ticket_small
) sub
WHERE rn = 1 
) where op in ('I','U')

Combined SQL>>>>>

select * from (
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY dms_cdc_timestamp DESC) AS rn
    FROM (select * from sporting_event_ticket where id in (select id from 
    (select id , count(distinct op) as op_count from sporting_event_ticket group by id having count(distinct op) > 1 order by id limit 10)))
) sub
WHERE rn = 1 
) where op in ('I','U')

Combined sql with CTE>>>>>

SHOW SQLs
*************************************************************************************************

WITH temp AS (select * from sporting_event_ticket where id in (select id from 
    (select id , count(distinct op) as op_count from sporting_event_ticket group by id having count(distinct op) > 1 order by id )
    )
    ) 
select * from (
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY dms_cdc_timestamp DESC) AS rn
    FROM temp
) sub
WHERE rn = 1 
) where op in ('I','U');

#Second table:

WITH temp AS (select * from ticket_purchase_hist where (purchased_by_id ,sporting_event_ticket_id,transferred_from_id) in (select purchased_by_id ,sporting_event_ticket_id,transferred_from_id from 
    (select purchased_by_id ,sporting_event_ticket_id,transferred_from_id , count(distinct op) as op_count from ticket_purchase_hist group by purchased_by_id ,sporting_event_ticket_id,transferred_from_id having count(distinct op) > 1 order by purchased_by_id ,sporting_event_ticket_id,transferred_from_id )
    )
    ) 
select * from (
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY purchased_by_id ,sporting_event_ticket_id,transferred_from_id ORDER BY dms_cdc_timestamp DESC) AS rn
    FROM temp
) sub
WHERE rn = 1 
) where op in ('I','U');

INTERESTING INSIGHTS:
---------------------------
--top 10 sporting events with max profit?
WITH temp AS (
select sporting_event_id,op,sum(ticket_price) as total_ticket_price from (
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY dms_cdc_timestamp DESC) AS rn
    FROM sporting_event_ticket
) sub
WHERE rn = 1 
) group by sporting_event_id,op having op in ('I','U')
union all
select sporting_event_ticket_id as sporting_event_id,op,sum(purchase_price) as total_ticket_price from  (
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY purchased_by_id ,sporting_event_ticket_id,transferred_from_id ORDER BY dms_cdc_timestamp DESC) AS rn
    FROM ticket_purchase_hist
) sub
WHERE rn = 1 
) group by sporting_event_ticket_id,op having op in ('I','U')
)
select sporting_event_id , sum(total_ticket_price) as business FROM temp group by sporting_event_id order by 2 desc limit 10;



--------------------------------------------------------------------------------
DEMO

RUN IN LOCAL MACHINE:
export AWS_PROFILE=uturn 
/Users/ritumishra/Documents/uturn/OUTPUT
python sql_athena.py

