\set ON_ERROR_STOP on
\timing on
-- Execute once with Flyway at target=3 and again after target=4.
-- Save output with psql ... -f sql/benchmark.sql > before.txt / after.txt.
\i sql/weekly_sales.sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.date_created AS order_date, SUM(op.quantity) AS sausages_quantity
FROM public.orders o
JOIN public.order_product op ON op.order_id=o.id
WHERE o.date_created >= date_trunc('week',CURRENT_DATE)::date - 7
 AND o.date_created < date_trunc('week',CURRENT_DATE)::date
GROUP BY o.date_created
ORDER BY o.date_created;
