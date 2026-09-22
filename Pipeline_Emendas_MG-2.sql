-- Databricks notebook source
-- Limpeza e filtro (camada Silver)

%sql
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

-- Modelagem final (camada Gold)
-- Criando a tabela fato

%sql
CREATE OR REPLACE TABLE fato_emendas_mg AS
SELECT 
    id_emenda, localidade, valor_empenhado, valor_pago 
FROM silver_emendas_mg;

-- COMMAND ----------

-- Criando a dimensão parlamentar

%sql
CREATE OR REPLACE TABLE dim_parlamentar AS
SELECT DISTINCT nome_parlamentar 
FROM silver_emendas_mg 
WHERE nome_parlamentar IS NOT NULL;

-- COMMAND ----------

-- Criando a dimensão área de atuação

%sql
CREATE OR REPLACE TABLE dim_area_atuacao AS
SELECT DISTINCT area_atuacao 
FROM silver_emendas_mg 
WHERE area_atuacao IS NOT NULL;

-- COMMAND ----------

-- Tratamento de Nulos --

%sql
SELECT COUNT(*) AS total_sem_localidade 
FROM silver_emendas_mg 
WHERE localidade IS NULL;

-- COMMAND ----------

-- Teste de acurácia --

%sql
SELECT COUNT(*) AS total_valores_negativos 
FROM silver_emendas_mg 
WHERE valor_empenhado < 0 OR valor_pago < 0;

-- COMMAND ----------

-- Resposdendo às perguntas de negócio
-- Top 5 municípios com maior volume pago

%sql
SELECT 
    localidade, 
    SUM(valor_pago) AS volume_total_pago 
FROM fato_emendas_mg 
WHERE localidade != 'ABRANGENCIA ESTADUAL'
GROUP BY localidade 
ORDER BY volume_total_pago DESC 
LIMIT 5;

-- COMMAND ----------

-- Top 5 parlamentares com maior volume pago e proporção empenho x pago

%sql
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

-- Top 5 áreas de atuação com maior volume pago

%sql
SELECT 
    area_atuacao, 
    SUM(valor_pago) AS volume_total_pago,
    ROUND(SUM(valor_pago) / (SELECT SUM(valor_pago) FROM silver_emendas_mg) * 100, 2) AS percentual_do_total
FROM silver_emendas_mg 
GROUP BY area_atuacao 
ORDER BY volume_total_pago DESC
LIMIT 5;

-- COMMAND ----------

