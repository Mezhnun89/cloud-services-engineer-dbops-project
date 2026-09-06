-- Previous complete calendar week, Monday inclusive to Monday exclusive.
-- Per assignment, sum every ordered item; no status filter is specified.
SELECT o.date_created AS order_date, SUM(op.quantity) AS sausages_quantity
FROM public.orders o
JOIN public.order_product op ON op.order_id=o.id
WHERE o.date_created >= date_trunc('week',DATE '2026-09-06')::date - 7
 AND o.date_created < date_trunc('week',DATE '2026-09-06')::date
GROUP BY o.date_created
ORDER BY o.date_created;
