-- =============================================
-- Author: Fiama
-- Create date: 03/10/2018
-- Description: Procedure para alimentação do DW
-- =============================================

USE [STAGE] ;
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Metricas_CV_Removido' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Metricas_CV_Removido
GO


CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Metricas_CV_Removido]
AS
SET NOCOUNT ON

-- Limpeza da tabela temporária:
TRUNCATE TABLE [VAGAS_DW].[TMP_CURRICULOS_REMOVIDOS] ;


---------------------------------------------------------------------------
-- Candidatos removidos pela equipe de Atendimento a Candidatos, via Manut:
---------------------------------------------------------------------------
-- DROP TABLE #TMP_CPF_REMOVIDO ;
SELECT	A.CPF_candREM AS CPF ,
		CONVERT(DATE, A.Data_candREM) AS DATA_REMOCAO ,
		COUNT(DISTINCT A.CodCand_candREM) AS QTD_CADASTROS
INTO	#TMP_CPF_REMOVIDO
FROM	[hrh-data].[dbo].[Cand-REM] AS A
WHERE	ISNULL(A.CPF_candREM, '') != ''
GROUP BY
		A.CPF_candREM ,
		CONVERT(DATE, A.Data_candREM) ;


-------------------------------------
-- Visão consolidada pra subir no DW:
-------------------------------------
-- DROP TABLE #TMP_VISAO_CONSOLIDADA_CPF_REMOVIDO ;
SELECT	A.CPF ,
		A.DATA_REMOCAO ,
		A.QTD_CADASTROS ,
		ISNULL(	( SELECT	TOP 1 'SIM' AS PRIMEIRA_REMOCAO
				  FROM		#TMP_CPF_REMOVIDO AS A1
				  WHERE		A.CPF = A1.CPF
							AND A.DATA_REMOCAO = ( SELECT	MIN(AA1.DATA_REMOCAO)
												   FROM		#TMP_CPF_REMOVIDO AS AA1
												   WHERE	A1.CPF = AA1.CPF ) ), 'NÃO') AS PRIMEIRA_REMOCAO ,
		( SELECT	TOP 1 A1.DATA_REMOCAO
		  FROM		#TMP_CPF_REMOVIDO AS A1
		  WHERE		A.CPF = A1.CPF
					AND A1.DATA_REMOCAO = ( SELECT	MIN(AA1.DATA_REMOCAO)
											FROM	#TMP_CPF_REMOVIDO AS AA1
											WHERE	A1.CPF = AA1.CPF ) ) AS DATA_PRM_REMOCAO ,
		IIF( ( SELECT	COUNT(*) AS QTD_DUPLICIDADES
			   FROM		#TMP_CPF_REMOVIDO AS A1
			   WHERE		A.CPF = A1.CPF) > 1, 'SIM', 'NÃO') AS RETORNOU ,
		ISNULL(	( SELECT	TOP 1 1 AS PRIMEIRA_REMOCAO
				  FROM		#TMP_CPF_REMOVIDO AS A1
				  WHERE		A.CPF = A1.CPF
							AND A.DATA_REMOCAO = ( SELECT	MIN(AA1.DATA_REMOCAO)
												   FROM		#TMP_CPF_REMOVIDO AS AA1
												   WHERE	A1.CPF = AA1.CPF ) ), 0) AS QTD_CPF_UNICO ,
		ISNULL(	( SELECT	TOP 1 0 AS QTD_RETORNO_CPF -- Retornos após a 1ª remoção
				  FROM		#TMP_CPF_REMOVIDO AS A1
				  WHERE		A.CPF = A1.CPF
							AND A.DATA_REMOCAO = ( SELECT	MIN(AA1.DATA_REMOCAO)
												   FROM		#TMP_CPF_REMOVIDO AS AA1		
												   WHERE	A1.CPF = AA1.CPF ) ), 1) AS QTD_RETORNO_CPF
INTO	#TMP_VISAO_CONSOLIDADA_CPF_REMOVIDO
FROM	#TMP_CPF_REMOVIDO AS A ;



-- Popular tabela:
INSERT INTO [VAGAS_DW].[TMP_CURRICULOS_REMOVIDOS] (CPF,DATA_REMOCAO,QTD_CADASTROS,PRIMEIRA_REMOCAO,DATA_PRM_REMOCAO,RETORNOU,QTD_CPF_UNICO,QTD_RETORNO_CPF)
SELECT	A.CPF ,
		A.DATA_REMOCAO ,
		A.QTD_CADASTROS ,
		A.PRIMEIRA_REMOCAO ,
		A.DATA_PRM_REMOCAO ,
		A.RETORNOU ,
		A.QTD_CPF_UNICO ,
		A.QTD_RETORNO_CPF
FROM	#TMP_VISAO_CONSOLIDADA_CPF_REMOVIDO AS A ;