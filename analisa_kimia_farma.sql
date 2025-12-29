CREATE OR REPLACE TABLE `Rakamin_KF_Analytics.tabel_analisa` AS
SELECT
    t.transaction_id,
    t.date,
    t.branch_id,
    c.branch_name,
    c.kota,
    
    -- PERBAIKAN NAMA PROVINSI (LENGKAP)
    CASE 
        WHEN c.provinsi = 'DKI Jakarta' THEN 'Jakarta'
        WHEN c.provinsi = 'DI Yogyakarta' THEN 'Yogyakarta'
        WHEN c.provinsi = 'Bangka Belitung' THEN 'Kepulauan Bangka Belitung'
        ELSE c.provinsi 
    END AS provinsi,

    c.rating AS rating_cabang,
    t.customer_name,
    t.product_id,
    p.product_name,
    t.price AS actual_price,
    t.discount_percentage,
    
    CASE
        WHEN t.price <= 50000 THEN 0.10
        WHEN t.price > 50000 AND t.price <= 100000 THEN 0.15
        WHEN t.price > 100000 AND t.price <= 300000 THEN 0.20
        WHEN t.price > 300000 AND t.price <= 500000 THEN 0.25
        WHEN t.price > 500000 THEN 0.30
    END AS persentase_gross_laba,

    (t.price - (t.price * t.discount_percentage)) AS nett_sales,

    ((t.price - (t.price * t.discount_percentage)) * CASE
        WHEN t.price <= 50000 THEN 0.10
        WHEN t.price > 50000 AND t.price <= 100000 THEN 0.15
        WHEN t.price > 100000 AND t.price <= 300000 THEN 0.20
        WHEN t.price > 300000 AND t.price <= 500000 THEN 0.25
        WHEN t.price > 500000 THEN 0.30
     END) AS nett_profit,

    t.rating AS rating_transaksi

FROM 
    `Rakamin_KF_Analytics.kf_final_transaction` t
LEFT JOIN 
    `Rakamin_KF_Analytics.kf_kantor_cabang` c ON t.branch_id = c.branch_id
LEFT JOIN 
    `Rakamin_KF_Analytics.kf_product` p ON t.product_id = p.product_id;