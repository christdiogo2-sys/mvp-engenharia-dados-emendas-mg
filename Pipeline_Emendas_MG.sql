-- Databricks notebook source
CREATE OR REPLACE TABLE silver_emendas_mg AS
SELECT 
    `Código da emenda` AS id_emenda,
    `Autor da emenda` AS nome_parlamentar,
    COALESCE(`Localidade do gasto (Regionalização)`, 'ABRANGENCIA ESTADUAL') AS localidade,
    `Função` AS area_atuacao,
    CAST(REPLACE(REPLACE(`Valor empenhado`, '.', ''), ',', '.') AS DECIMAL(15,2)) AS valor_empenhado,
    CAST(REPLACE(REPLACE(`Valor pago`, '.', ''), ',', '.') AS DECIMAL(15,2)) AS valor_pago
FROM bronze_emendas_raw
WHERE `Localidade do gasto (Regionalização)` LIKE '%MG%' 
   OR `Localidade do gasto (Regionalização)` LIKE '%Minas Gerais%';

-- COMMAND ----------

CREATE OR REPLACE TABLE fato_emendas_mg AS
SELECT 
    id_emenda, localidade, valor_empenhado, valor_pago 
FROM silver_emendas_mg;

-- COMMAND ----------

CREATE OR REPLACE TABLE dim_parlamentar AS
SELECT DISTINCT nome_parlamentar 
FROM silver_emendas_mg 
WHERE nome_parlamentar IS NOT NULL;

-- COMMAND ----------

CREATE OR REPLACE TABLE dim_area_atuacao AS
SELECT DISTINCT area_atuacao 
FROM silver_emendas_mg 
WHERE area_atuacao IS NOT NULL;

-- COMMAND ----------

SELECT 
    localidade, 
    SUM(valor_pago) AS volume_total_pago 
FROM fato_emendas_mg 
WHERE localidade != 'ABRANGENCIA ESTADUAL'
GROUP BY localidade 
ORDER BY volume_total_pago DESC 
LIMIT 5;

-- COMMAND ----------

SELECT 
    nome_parlamentar AS autor_da_emenda,
    SUM(valor_empenhado) AS total_empenhado,
    SUM(valor_pago) AS total_pago,
    ROUND((SUM(valor_pago) / SUM(valor_empenhado)) * 100, 2) AS percentual_pago
FROM silver_emendas_mg
GROUP BY nome_parlamentar
HAVING SUM(valor_empenhado) > 100000
ORDER BY total_pago DESC
LIMIT 5;

-- COMMAND ----------

SELECT 
    area_atuacao, 
    SUM(valor_pago) AS volume_total_pago,
    ROUND(SUM(valor_pago) / (SELECT SUM(valor_pago) FROM silver_emendas_mg) * 100, 2) AS percentual_do_total
FROM silver_emendas_mg 
GROUP BY area_atuacao 
ORDER BY volume_total_pago DESC
LIMIT 5;

-- COMMAND ----------

