SELECT
  pr.product_category_name_english as Category,
  SUM(p.payment_value) as Revenue,
  FORMAT_TIMESTAMP('%Y-%m', o.order_purchase_timestamp) as Month
FROM `olist.clean_products` pr
LEFT JOIN `olist.clean_items` i ON pr.product_id = i.product_id
LEFT JOIN `olist.clean_orders` o ON o.order_id = i.order_id
LEFT JOIN `olist.clean_payments` p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY Month, Category
HAVING Revenue IS NOT NULL
ORDER BY Revenue DESC
