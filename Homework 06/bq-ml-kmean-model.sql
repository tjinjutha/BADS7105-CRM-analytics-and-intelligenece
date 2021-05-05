CREATE OR REPLACE MODEL `crm-bads7105.supermarket.supermarket_clusters`
OPTIONS(model_type='kmeans', num_clusters=3, kmeans_init_method='kmeans++', max_iterations=50)
AS (
    SELECT 
        *,
    FROM `crm-bads7105.supermarket.supermarket`
)