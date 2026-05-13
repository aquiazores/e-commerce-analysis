SELECT
  c.customer_state as State,
  SUM(p.payment_value) as Revenue,
  FORMAT_TIMESTAMP('%Y-%m', o.order_purchase_timestamp) as Month
FROM `olist.clean_customers` c
JOIN `olist.clean_orders` o ON c.customer_id = o.customer_id
JOIN `olist.clean_payments` p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY Month, State
ORDER BY Month ASC, Revenue DESC
