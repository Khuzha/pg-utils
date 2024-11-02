with s AS
(SELECT sum(mean_exec_time) AS t,sum(blk_read_time+blk_write_time) as iot, sum(mean_exec_time-blk_read_time-blk_write_time) as cput, sum(calls) AS s,sum(rows) as r FROM pg_stat_statements WHERE dbid=(SELECT oid from pg_database where datname=current_database()))
,
_pg_stat_statements as (
select query,sum(mean_exec_time) as mean_exec_time, sum(blk_read_time) as blk_read_time, sum(blk_write_time) as blk_write_time, sum(calls) as calls, sum(rows) as rows
from pg_stat_statements
where dbid=(SELECT oid from pg_database where datname=current_database())
group by query
)

SELECT
(100*mean_exec_time/NULLIF((SELECT t FROM s), 0))::numeric(20,2) AS time_percent,
(100*(blk_read_time+blk_write_time)/NULLIF((SELECT iot FROM s), 0))::numeric(20,2) AS iotime_percent,
(100*(mean_exec_time-blk_read_time-blk_write_time)/NULLIF((SELECT cput FROM s), 0))::numeric(20,2) AS cputime_percent,
mean_exec_time::numeric(20,2) as mean_exec_time,
(mean_exec_time*1000/NULLIF(calls, 0))::numeric(20,2) AS avg_time,
((blk_read_time+blk_write_time)*1000/NULLIF(calls, 0))::numeric(20,2) AS avg_io_time,
calls,
(100*calls/NULLIF((SELECT s FROM s), 0))::numeric(20,2) AS calls_percent,
rows,
(100*rows/NULLIF((SELECT r from s), 0))::numeric(20,2) AS row_percent,
query
FROM _pg_stat_statements
WHERE
(mean_exec_time-blk_read_time-blk_write_time)/NULLIF((SELECT cput FROM s), 0)>=0.02

UNION all

SELECT
(100*sum(mean_exec_time)/NULLIF((SELECT t FROM s), 0))::numeric(20,2) AS time_percent,
(100*sum(blk_read_time+blk_write_time)/NULLIF((SELECT iot FROM s), 0))::numeric(20,2) AS iotime_percent,
(100*sum(mean_exec_time-blk_read_time-blk_write_time)/NULLIF((SELECT cput FROM s), 0))::numeric(20,2) AS cputime_percent,
sum(mean_exec_time)::numeric(20,2),
(sum(mean_exec_time)*1000/NULLIF(sum(calls), 0))::numeric(10,3) AS avg_time,
(sum(blk_read_time+blk_write_time)*1000/NULLIF(sum(calls), 0))::numeric(10,3) AS avg_io_time,
sum(calls),
(100*sum(calls)/NULLIF((SELECT s FROM s), 0))::numeric(20,2) AS calls_percent,
sum(rows),
(100*sum(rows)/NULLIF((SELECT r from s), 0))::numeric(20,2) AS row_percent,
'other' AS query
FROM _pg_stat_statements
WHERE
(mean_exec_time-blk_read_time-blk_write_time)/NULLIF((SELECT cput FROM s), 0)<0.02

ORDER BY 3 DESC;
