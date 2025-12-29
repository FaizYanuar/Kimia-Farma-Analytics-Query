-- Membuat tabel analisa baru (Data Mart) untuk menyimpan hasil join dan agregasi
-- Menggunakan CREATE OR REPLACE agar kalau tabelnya sudah ada, bisa langsung ditimpa (update) tanpa error
CREATE OR REPLACE TABLE `Rakamin_KF_Analytics.tabel_analisa` AS
SELECT
    -- Mengambil kolom-kolom identitas transaksi yang penting
    t.transaction_id,
    t.date,
    t.branch_id,
    
    -- Mengambil data detail cabang dari tabel cabang (c)
    c.branch_name,
    c.kota,
    
    -- [DATA CLEANING] 
    -- Memperbaiki nama provinsi agar sesuai standar Google Maps di Looker Studio
    -- Masalah: Google Maps tidak detect 'DKI Jakarta' (harus 'Jakarta') dan 'DI Yogyakarta' (harus 'Yogyakarta')
    -- Solusi: Pakai CASE WHEN untuk standarisasi nama, sisanya biarkan default (ELSE c.provinsi)
    CASE 
        WHEN c.provinsi = 'DKI Jakarta' THEN 'Jakarta'
        WHEN c.provinsi = 'DI Yogyakarta' THEN 'Yogyakarta'
        WHEN c.provinsi = 'Bangka Belitung' THEN 'Kepulauan Bangka Belitung'
        ELSE c.provinsi 
    END AS provinsi,

    c.rating AS rating_cabang, -- Rating performa cabang
    
    -- Mengambil data customer dan detail produk
    t.customer_name,
    t.product_id,
    p.product_name, -- Mengambil nama obat dari tabel produk (p)
    t.price AS actual_price, -- Harga asli sebelum diskon
    t.discount_percentage,
    
    -- [BUSINESS LOGIC]
    -- Menentukan persentase laba kotor (Gross Laba) berdasarkan tier harga obat
    -- Aturan: Semakin mahal obat, semakin besar persentase labanya (range 10% - 30%)
    CASE
        WHEN t.price <= 50000 THEN 0.10
        WHEN t.price > 50000 AND t.price <= 100000 THEN 0.15
        WHEN t.price > 100000 AND t.price <= 300000 THEN 0.20
        WHEN t.price > 300000 AND t.price <= 500000 THEN 0.25
        WHEN t.price > 500000 THEN 0.30
    END AS persentase_gross_laba,

    -- [CALCULATED FIELD 1]
    -- Menghitung Nett Sales (Pendapatan Bersih)
    -- Rumus: Harga Asli - (Harga Asli * Diskon)
    (t.price - (t.price * t.discount_percentage)) AS nett_sales,

    -- [CALCULATED FIELD 2]
    -- Menghitung Nett Profit (Keuntungan Bersih)
    -- Rumus: Nett Sales * Persentase Gross Laba (dari logic CASE WHEN di atas)
    ((t.price - (t.price * t.discount_percentage)) * CASE
        WHEN t.price <= 50000 THEN 0.10
        WHEN t.price > 50000 AND t.price <= 100000 THEN 0.15
        WHEN t.price > 100000 AND t.price <= 300000 THEN 0.20
        WHEN t.price > 300000 AND t.price <= 500000 THEN 0.25
        WHEN t.price > 500000 THEN 0.30
     END) AS nett_profit,

    t.rating AS rating_transaksi -- Rating kepuasan customer terhadap transaksi

FROM 
    -- Tabel Utama: Transaksi (diberi alias 't')
    `Rakamin_KF_Analytics.kf_final_transaction` t

-- Menggabungkan dengan tabel Cabang (alias 'c') berdasarkan branch_id
-- Pakai LEFT JOIN agar data transaksi tetap ada walaupun data cabangnya mungkin tidak lengkap
LEFT JOIN 
    `Rakamin_KF_Analytics.kf_kantor_cabang` c ON t.branch_id = c.branch_id

-- Menggabungkan dengan tabel Produk (alias 'p') berdasarkan product_id
-- Pakai LEFT JOIN untuk mengambil nama produk
LEFT JOIN 
    `Rakamin_KF_Analytics.kf_product` p ON t.product_id = p.product_id;
