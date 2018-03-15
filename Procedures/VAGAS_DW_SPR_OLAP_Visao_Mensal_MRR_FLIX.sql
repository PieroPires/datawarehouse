-- =============================================
-- Author: Fiama
-- Create date: 02/03/2018
-- Description: Vis�o mensal MRR VAGAS FLIX.
-- =============================================

USE [VAGAS_DW] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_VAGAS_DW_SPR_OLAP_Visao_Mensal_MRR_FLIX' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_VAGAS_DW_SPR_OLAP_Visao_Mensal_MRR_FLIX] ;
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_VAGAS_DW_SPR_OLAP_Visao_Mensal_MRR_FLIX]
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[VISAO_MENSAL_MRR_FLIX] ;

DECLARE	@MAX_DATA_REFERENCIA SMALLDATETIME ;
SET		@MAX_DATA_REFERENCIA = (SELECT	MAX(DATA_REFERENCIA) FROM [VAGAS_DW].[BASE_EMPRESAS_VAGAS_FLIX] WHERE DATA_REFERENCIA IS NOT NULL) ;

WITH	CTE_EXISTS_CNPJ (DATA_REFERENCIA, CNPJ, DATA_REFERENCIA_ANTERIOR, DATA_REFERENCIA_POSTERIOR)
AS
	( SELECT	A1.DATA_REFERENCIA ,
				A1.CNPJ ,
				LAG(A1.DATA_REFERENCIA, 1, 0) OVER(PARTITION BY A1.CNPJ ORDER BY A1.DATA_REFERENCIA ASC) AS DATA_REFERENCIA_ANTERIOR ,
				LEAD(A1.DATA_REFERENCIA, 1, 0) OVER(PARTITION BY A1.CNPJ ORDER BY A1.DATA_REFERENCIA ASC) AS DATA_REFERENCIA_POSTERIOR
	  FROM		[VAGAS_DW].[BASE_EMPRESAS_VAGAS_FLIX] AS A1
	  WHERE		A1.DATA_REFERENCIA IS NOT NULL )
SELECT	EOMONTH(A.DATA_REFERENCIA) AS DATA_REFERENCIA ,
		A.CNPJ ,
		A.DATA_REFERENCIA_ANTERIOR ,
		A.DATA_REFERENCIA_POSTERIOR ,
		CASE
			WHEN (A.DATA_REFERENCIA_ANTERIOR = '19000101' AND A.DATA_REFERENCIA_POSTERIOR = '19000101') OR (A.DATA_REFERENCIA_ANTERIOR = '19000101')
				THEN 'New MRR'
			WHEN (DATEDIFF(MONTH, A.DATA_REFERENCIA_ANTERIOR, A.DATA_REFERENCIA) > 1) AND A.DATA_REFERENCIA_ANTERIOR > '19000101'
				THEN 'New MRR'
			WHEN (A.DATA_REFERENCIA_ANTERIOR > '19000101')
				THEN 'Expansion MRR'
		END AS CATEGORIA ,
		IIF(DATA_REFERENCIA_POSTERIOR = '19000101' AND DATA_REFERENCIA < @MAX_DATA_REFERENCIA, EOMONTH(DATEADD(MONTH, 1, A.DATA_REFERENCIA)), NULL) AS PROX_DATA_REFERENCIA ,
		IIF(DATEDIFF(MONTH, A.DATA_REFERENCIA_ANTERIOR, A.DATA_REFERENCIA) > 1 AND A.DATA_REFERENCIA_ANTERIOR > '19000101', EOMONTH(DATEADD(MONTH, 1, DATA_REFERENCIA_ANTERIOR)), NULL) AS PROX_DATA_REFERENCIA_CHURNED_MES_ANT
INTO	#TMP_VISAO_MRR
FROM	CTE_EXISTS_CNPJ AS A ;


-- DROP TABLE #TMP_VISAO_CONSOLIDADA_MRR ;
SELECT	A.DATA_REFERENCIA AS DATA_REFERENCIA ,
		A.CNPJ ,
		A.CATEGORIA ,
		1 AS QTD ,
		CONVERT(SMALLMONEY, 1 * 6.50) AS VALOR_FATURADO
INTO	#TMP_VISAO_CONSOLIDADA_MRR
FROM	#TMP_VISAO_MRR AS A
UNION ALL
SELECT	A.PROX_DATA_REFERENCIA AS DATA_REFERENCIA ,
		A.CNPJ ,
		'Churned MRR' AS CATEGORIA ,
		 -1 AS QTD ,
		CONVERT(SMALLMONEY, -1 * 6.50) AS VALOR
FROM	#TMP_VISAO_MRR AS A
WHERE	A.PROX_DATA_REFERENCIA IS NOT NULL
UNION ALL
SELECT	A.PROX_DATA_REFERENCIA_CHURNED_MES_ANT AS DATA_REFERENCIA ,
		A.CNPJ ,
		'Churned MRR' AS CATEGORIA ,
		-1 AS QTD ,
		CONVERT(SMALLMONEY, -1 * 6.50) AS VALOR
FROM	#TMP_VISAO_MRR AS A
WHERE	A.PROX_DATA_REFERENCIA_CHURNED_MES_ANT IS NOT NULL ;

INSERT INTO [VAGAS_DW].[VISAO_MENSAL_MRR_FLIX] (DATA_REFERENCIA, CNPJ, CATEGORIA, QTD_CNPJs, VALOR_MRR)
SELECT	A.DATA_REFERENCIA ,
		A.CNPJ ,
		A.CATEGORIA ,
		A.QTD ,
		A.VALOR_FATURADO
FROM	#TMP_VISAO_CONSOLIDADA_MRR AS A ;