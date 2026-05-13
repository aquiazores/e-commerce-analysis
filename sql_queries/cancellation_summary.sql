SELECT
  FORMAT_TIMESTAMP('%Y-%m', order_purchase_timestamp) as Month,
  COUNTIF(order_status = 'canceled') as cancelled_orders,
  COUNT(order_id) as total_orders,
  COUNTIF(order_status = 'canceled') / COUNT(order_id) as cancellation_rate
FROM `olist.clean_orders`
GROUP BY Month
ORDER BY Month ASC
