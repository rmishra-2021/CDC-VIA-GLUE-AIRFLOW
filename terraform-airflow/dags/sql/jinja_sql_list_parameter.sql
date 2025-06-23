{% for table in table_list %}

drop table if exists {{ table["target_table"] }}_cdc;
CREATE TABLE {{ table["target_table"] }}_cdc
WITH (
  format = '{{ data_format }}',
  external_location = 's3://uturntransformeddata/parquet_table/{{ table["target_table"] }}_cdc/',
  parquet_compression = '{{ compression }}')
AS
WITH temp AS (select * from {{ table["target_table"] }} where ({{ table["key_column"] }}) in (select {{ table["key_column"] }} from 
    (select {{ table["key_column"] }} , count(distinct op) as op_count from {{ table["target_table"] }} group by {{ table["key_column"] }} having count(distinct op) > 1 order by {{ table["key_column"] }} )
    )
    ) 
select * from (
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY {{ table["key_column"] }} ORDER BY dms_cdc_timestamp DESC) AS rn
    FROM temp
) sub
WHERE rn = 1 
) where op in ('I','U');

{% endfor %}
