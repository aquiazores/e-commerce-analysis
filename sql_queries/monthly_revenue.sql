SELECT
  SUM(payment_value) as Revenue,
  FORMAT_TIMESTAMP('%Y-%m', o.order_purchase_timestamp) as Month
FROM `olist.clean_payments` p
JOIN `olist.clean_orders` o ON p.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY Month
ORDER BY Month ASC
