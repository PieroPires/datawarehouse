-- =============================================
-- Author:      Fiama dos Santos Cristi
-- Create date: 03/10/2018
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW
-- =============================================


USE VAGAS_DW
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Metricas_CV_Removido' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Metricas_CV_Removido]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Metricas_CV_Removido]

AS
SET NOCOUNT ON


-- LIMPAR TABELA FATO:
TRUNCATE TABLE [VAGAS_DW].[CURRICULOS_REMOVIDOS] ;

INSERT INTO [VAGAS_DW].[CURRICULOS_REMOVIDOS](CPF,DATA_REMOCAO,QTD_CADASTROS,PRIMEIRA_REMOCAO,DATA_PRM_REMOCAO,RETORNOU,QTD_CPF_UNICO,QTD_RETORNO_CPF)
SELECT	A.CPF ,
		A.DATA_REMOCAO ,
		A.QTD_CADASTROS ,
		A.PRIMEIRA_REMOCAO ,
		A.DATA_PRM_REMOCAO ,
		A.RETORNOU ,
		A.QTD_CPF_UNICO ,
		A.QTD_RETORNO_CPF
FROM	[STAGE].[VAGAS_DW].[TMP_CURRICULOS_REMOVIDOS] AS A ;


-------------------------------------------------------------------------
-- Gerar c�digo sequencial para n�o exibirmos o CPF do candidato no CUBO:
-------------------------------------------------------------------------
-- DROP TABLE #TMP_CPF_SEQUENCIAL ;
SELECT	SUBQUERY.CPF ,
		'CPF' + '_' + CONVERT(VARCHAR(100), SUBQUERY.ROWNUMBER) AS CPF_SEQUENCIAL ,
		CONVERT(INT, RIGHT('CPF' + '_' + CONVERT(VARCHAR(100), SUBQUERY.ROWNUMBER), LEN('CPF' + '_' + CONVERT(VARCHAR(100), SUBQUERY.ROWNUMBER)) - 4)) AS NUM_CPF_SEQUENCIAL
INTO	#TMP_CPF_SEQUENCIAL
FROM	(
		SELECT	CPF ,
				ROW_NUMBER() OVER(ORDER BY CPF ASC) AS ROWNUMBER ,
				COUNT(*) AS QTD_REGISTROS
		FROM	[STAGE].[VAGAS_DW].[TMP_CURRICULOS_REMOVIDOS]
		GROUP BY
				CPF ) AS SUBQUERY
ORDER BY
		CONVERT(INT, RIGHT('CPF' + '_' + CONVERT(VARCHAR(100), SUBQUERY.ROWNUMBER), LEN('CPF' + '_' + CONVERT(VARCHAR(100), SUBQUERY.ROWNUMBER)) - 4)) ASC ;


-------------------------------------
-- Atribuir o CPF_SEQUENCIAL a vis�o:
-------------------------------------
UPDATE	[VAGAS_DW].[CURRICULOS_REMOVIDOS]
SET		CPF_SEQUENCIAL = B.CPF_SEQUENCIAL ,
		NUM_CPF_SEQUENCIAL = B.NUM_CPF_SEQUENCIAL
FROM	[VAGAS_DW].[CURRICULOS_REMOVIDOS] AS A		LEFT OUTER JOIN #TMP_CPF_SEQUENCIAL AS B ON A.CPF COLLATE SQL_Latin1_General_CP1_CI_AI = B.CPF ;


---------------------------------------
-- Faixa de classifica��o dos retornos:
---------------------------------------
-- DROP TABLE #TMP_FAIXAS_CLASSIFICACAO_CPF ;
SELECT	CASE
			WHEN SUBQUERY.QTD_RETORNOS BETWEEN 1 AND 2
				THEN '1 A 2'
			WHEN SUBQUERY.QTD_RETORNOS BETWEEN 3 AND 4
				THEN '3 A 4'
			WHEN SUBQUERY.QTD_RETORNOS BETWEEN 5 AND 9
				THEN '5 A 9'
			WHEN SUBQUERY.QTD_RETORNOS > 9
				THEN 'ACIMA DE 9'
			ELSE NULL
		END AS FAIXA_RETORNO ,
		SUBQUERY.NUM_CPF_SEQUENCIAL
INTO	#TMP_FAIXAS_CLASSIFICACAO_CPF
FROM	(
			SELECT	A.NUM_CPF_SEQUENCIAL ,
					COUNT(*) AS QTD_RETORNOS
			FROM	[VAGAS_DW].[CURRICULOS_REMOVIDOS] AS A
			WHERE	A.RETORNOU = 'SIM'
			GROUP BY
					A.NUM_CPF_SEQUENCIAL
			HAVING COUNT(*) > 1 ) AS SUBQUERY ;

--------------------------------------------------
-- Atribuir a faixa de classifica��o dos retornos:
--------------------------------------------------
UPDATE	[VAGAS_DW].[CURRICULOS_REMOVIDOS]
SET		FAIXA_RETORNO = B.FAIXA_RETORNO
FROM	[VAGAS_DW].[CURRICULOS_REMOVIDOS] AS A		INNER JOIN #TMP_FAIXAS_CLASSIFICACAO_CPF AS B ON A.NUM_CPF_SEQUENCIAL = B.NUM_CPF_SEQUENCIAL ;