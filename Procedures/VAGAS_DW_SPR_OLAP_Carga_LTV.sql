-- EXEC VAGAS_DW.SPR_OLAP_Carga_LTV
USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_LTV' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_LTV
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 17/04/2017
-- Description: Procedure para alimenta��o do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_LTV @DATA_REFERENCIA SMALLDATETIME = NULL

AS
SET NOCOUNT ON

-- SE N�O FOR PASSADO DATA DE REFERENCIA SETAR COMO DATA ATUAL
IF @DATA_REFERENCIA IS NULL
	SET @DATA_REFERENCIA = CONVERT(SMALLDATETIME,CONVERT(VARCHAR,GETDATE(),112))
	
-- selecionar clientes ativos
CREATE TABLE #TMP_CLIENTES (COD_CLI INT,CONTA_ID VARCHAR(255) COLLATE SQL_Latin1_General_CP1_CI_AI,CLIENTE_CRM VARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AI,
							DATA_PRM_OPORTUNIDADE SMALLDATETIME,EX_CLIENTE BIT,DATA_RESCISAO SMALLDATETIME,VALOR_MENSALIDADE SMALLMONEY)

CREATE TABLE #TMP_CLIENTES_ATIVOS (COD_CLI INT,CONTA_ID VARCHAR(255) COLLATE SQL_Latin1_General_CP1_CI_AI,CLIENTE_CRM VARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AI,
								   DATA_PRM_OPORTUNIDADE SMALLDATETIME,EX_CLIENTE BIT,DATA_RESCISAO SMALLDATETIME,VALOR_MENSALIDADE SMALLMONEY)


CREATE TABLE #TMP_ANALISE_FATURAMENTO (COD_CLI INT,CONTA_ID VARCHAR(255) COLLATE SQL_Latin1_General_CP1_CI_AI,CLIENTE_CRM VARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AI,
									   DATA_PRM_OPORTUNIDADE SMALLDATETIME,DATA_INICIO_FATURAMENTO SMALLDATETIME,TEMPO_MESES SMALLINT,VALOR MONEY,LTV MONEY,VALOR_MENSALIDADE SMALLMONEY)

INSERT INTO #TMP_CLIENTES (COD_CLI,CONTA_ID,CLIENTE_CRM,DATA_PRM_OPORTUNIDADE,EX_CLIENTE,DATA_RESCISAO,VALOR_MENSALIDADE)
SELECT A.COD_CLI,
	   A.CONTA_ID,
	   A.CLIENTE_CRM,
	   ISNULL(A.DATA_PRM_OPORTUNIDADE_CRM,B.DATAFECHAMENTO) AS DATA_PRM_OPORTUNIDADE,
	   A.EX_CLIENTE,
	   A.DATA_RESCISAO,
	   A.VALOR_MENSALIDADE
FROM VAGAS_DW.CLIENTES A
OUTER APPLY ( SELECT TOP 1 * 
			  FROM VAGAS_DW.OPORTUNIDADES
			  WHERE CONTAID = A.CONTA_ID
			  AND PRODUTO = 'FIT'
			  AND FASE = 'fechado_e_ganho'
			  ORDER BY DATAFECHAMENTO ASC ) B
WHERE A.DATA_REFERENCIA = ( SELECT MAX(DATA_REFERENCIA) FROM VAGAS_DW.CLIENTES )
AND A.CONTEM_FIT = 1
AND B.DATAFECHAMENTO <= @DATA_REFERENCIA
ORDER BY 1 DESC

-- ATUALIZAR COMO 12 MESES CLIENTES SEM DATA RESCIS�O
UPDATE #TMP_CLIENTES SET DATA_RESCISAO = DATEADD(MONTH,12,DATA_PRM_OPORTUNIDADE)
FROM #TMP_CLIENTES 
WHERE EX_CLIENTE = 1 
AND DATA_RESCISAO IS NULL

INSERT INTO #TMP_CLIENTES_ATIVOS (COD_CLI,CONTA_ID,CLIENTE_CRM,DATA_PRM_OPORTUNIDADE,EX_CLIENTE,DATA_RESCISAO,VALOR_MENSALIDADE)
SELECT * 
FROM #TMP_CLIENTES 
WHERE @DATA_REFERENCIA BETWEEN DATA_PRM_OPORTUNIDADE AND ISNULL(DATA_RESCISAO,@DATA_REFERENCIA) -- APENAS CLIENTES ATIVOS NA DATA REFERENCIA
ORDER BY DATA_RESCISAO DESC

INSERT INTO #TMP_ANALISE_FATURAMENTO (COD_CLI,CONTA_ID,CLIENTE_CRM,DATA_PRM_OPORTUNIDADE,DATA_INICIO_FATURAMENTO,TEMPO_MESES,VALOR,VALOR_MENSALIDADE)
SELECT A.COD_CLI,
	   A.CONTA_ID,
	   A.CLIENTE_CRM,
	   MIN(B.DATA_VENCIMENTO) AS DATA_INICIO,
	   A.DATA_PRM_OPORTUNIDADE,
	   CASE WHEN MIN(B.DATA_VENCIMENTO) < A.DATA_PRM_OPORTUNIDADE THEN DATEDIFF(MONTH,MIN(B.DATA_VENCIMENTO),@DATA_REFERENCIA)
			ELSE DATEDIFF(MONTH,MIN(A.DATA_PRM_OPORTUNIDADE),@DATA_REFERENCIA)  END TEMPO_MESES,	   
	   SUM(VALOR) AS VALOR,
	   A.VALOR_MENSALIDADE
FROM #TMP_CLIENTES_ATIVOS A
INNER JOIN VAGAS_DW.FATURAS B ON B.COD_CLI_CRM = A.CONTA_ID
							 AND B.DATA_REFERENCIA = ( SELECT MAX(DATA_REFERENCIA) FROM VAGAS_DW.FATURAS
														WHERE COD_CLI_CRM = B.COD_CLI_CRM
														AND NUM_PEDIDO = B.NUM_PEDIDO )
							 AND B.DATA_VENCIMENTO < @DATA_REFERENCIA
GROUP BY A.COD_CLI,
       A.CONTA_ID,
	   A.CLIENTE_CRM,
	   A.DATA_PRM_OPORTUNIDADE,
	   A.VALOR_MENSALIDADE

-- ATUALIZAR PROJE��O DE VALOR PARA PELO MENOS 4 MESES (PARA CLIENTES QUE AINDA N�O COMPLETARAM ESTE TEMPO)
UPDATE #TMP_ANALISE_FATURAMENTO SET VALOR = VALOR * 4
FROM #TMP_ANALISE_FATURAMENTO 
WHERE TEMPO_MESES < 5

-- ATUALIZAR LTV COM MARGEM DE CONTRIBUI��O DE 80%
UPDATE #TMP_ANALISE_FATURAMENTO SET LTV = VALOR * 0.8
FROM #TMP_ANALISE_FATURAMENTO 
-- SELECT * FROM #TMP_ANALISE_FATURAMENTO

-- LIMPAR DADOS EXISTENTES PARA A DATA REFERENCIA DO M�S (MANTER SEMPRE APENAS UMA DATA REF. POR M�S)
DELETE FROM VAGAS_DW.LTV WHERE MONTH(DATA_REFERENCIA) = MONTH(@DATA_REFERENCIA) AND YEAR(DATA_REFERENCIA) = YEAR(@DATA_REFERENCIA)

-- INSERIR DADOS NA TABELA FATO
INSERT INTO VAGAS_DW.LTV (DATA_REFERENCIA,COD_CLI,CONTA_ID,CLIENTE,TEMPO_MESES,LTV,VALOR_MENSALIDADE)
SELECT @DATA_REFERENCIA, 
	   COD_CLI,
	   CONTA_ID,
	   CLIENTE_CRM AS CLIENTE,
	   TEMPO_MESES,
	   VALOR * 0.8 AS LTV,
	   VALOR_MENSALIDADE
FROM #TMP_ANALISE_FATURAMENTO 
   
DROP TABLE #TMP_CLIENTES 
DROP TABLE #TMP_CLIENTES_ATIVOS
DROP TABLE #TMP_ANALISE_FATURAMENTO

GO
