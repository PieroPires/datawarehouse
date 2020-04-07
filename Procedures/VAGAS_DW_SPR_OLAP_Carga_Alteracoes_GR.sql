USE [VAGAS_DW]
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_ALTERACOES_GR' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_ALTERACOES_GR
GO

-- =============================================
-- Author: Fiama dos Santos Cristi
-- Create date: 22/02/2018
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_ALTERACOES_GR
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[ALTERACOES_GR] ;

-- MODELAGEM do recebimento dos dados:
SELECT	A.CONTA_ID ,
		A.DATA_ALTERACAO ,
		A.VALOR_ANTERIOR ,
		ISNULL(A.VALOR_ATUALIZADO, '') AS VALOR_ATUALIZADO ,
		ROW_NUMBER() OVER(PARTITION BY A.CONTA_ID ORDER BY A.DATA_ALTERACAO ASC) AS CONTROLE
INTO	#TMP_ALTERACOES_GR
FROM	[STAGE].[VAGAS_DW].[TMP_ALTERACOES_GR] AS A
WHERE	A.DATA_ALTERACAO = (SELECT	MAX(A1.DATA_ALTERACAO)
							FROM	[STAGE].[VAGAS_DW].[TMP_ALTERACOES_GR] AS A1
							WHERE	A.CONTA_ID = A1.CONTA_ID
									AND CONVERT(VARCHAR(8), A.DATA_ALTERACAO) = CONVERT(VARCHAR(8), A1.DATA_ALTERACAO)); -- Considera o maior registro de altera��o na mesma data


-- Estrutura��o da 1� e �ltima altera��o, com as demais altera��es, entre a 1� e a �ltima:
SELECT	SUBQUERY.CONTA_ID ,
		CONVERT(DATETIME, CONVERT(VARCHAR(8), SUBQUERY.DATA_ALTERACAO_ANTERIOR, 112)) AS DATA_ALTERACAO_ANTERIOR ,
		CONVERT(DATETIME, CONVERT(VARCHAR(8), SUBQUERY.DATA_ALTERACAO_ATUALIZADO, 112)) AS DATA_ALTERACAO_ATUALIZADO ,
		SUBQUERY.VALOR_ATUALIZACAO ,
		ROW_NUMBER() OVER(PARTITION BY SUBQUERY.CONTA_ID ORDER BY SUBQUERY.DATA_ALTERACAO_ATUALIZADO ASC) AS CONTROLE
INTO	#TMP_VISAO_ALTERACOES_GR
FROM	(
	SELECT	A.CONTA_ID ,
			CONVERT(DATETIME, '19000101') AS DATA_ALTERACAO_ANTERIOR ,
			A.DATA_ALTERACAO AS DATA_ALTERACAO_ATUALIZADO ,
			A.VALOR_ANTERIOR AS VALOR_ATUALIZACAO
	FROM	#TMP_ALTERACOES_GR AS A
	WHERE	A.CONTROLE = 1
	UNION ALL
	SELECT	A.CONTA_ID ,
			A.DATA_ALTERACAO AS DATA_ALTERACAO_ANTERIOR ,
			ISNULL(B.DATA_ALTERACAO, CONVERT(DATETIME, '20790606')) AS DATA_ALTERACAO_ATUALIZADO ,
			A.VALOR_ATUALIZADO AS VALOR_ATUALIZACAO
	FROM	#TMP_ALTERACOES_GR AS A		OUTER APPLY (SELECT	TOP 1 A1.DATA_ALTERACAO
													 FROM	#TMP_ALTERACOES_GR AS A1
													 WHERE	A.CONTA_ID = A1.CONTA_ID
															AND A1.DATA_ALTERACAO > A.DATA_ALTERACAO
													 ORDER BY
															A1.DATA_ALTERACAO ASC) AS B ) AS SUBQUERY
ORDER BY
		SUBQUERY.CONTA_ID ;




-- Tratamento para registros que possuem o propriet�rio da conta, diferente do �ltimo registro no log de altera��o do propriet�rio da conta:
UPDATE	#TMP_VISAO_ALTERACOES_GR
SET		VALOR_ATUALIZACAO = (SELECT	SUBQUERY.PROPRIETARIO_CONTA
							 FROM	(SELECT	A1.CONTA_ID ,
											ISNULL(A1.PROPRIETARIO_CONTA, '') AS PROPRIETARIO_CONTA
									 FROM	[VAGAS_DW].[CONTAS_CRM] AS A1
									 UNION ALL
									 SELECT	A2.CONTA_ID ,
											ISNULL(A2.PROPRIETARIO_CONTA, '') AS PROPRIETARIO_CONTA
									 FROM	[VAGAS_DW].[CONTAS_MEMBRO_CRM] AS A2) AS SUBQUERY
							 WHERE	A.CONTA_ID = SUBQUERY.CONTA_ID COLLATE SQL_Latin1_General_CP1_CI_AI)
FROM	#TMP_VISAO_ALTERACOES_GR AS A
WHERE	A.DATA_ALTERACAO_ATUALIZADO = '20790606'
		AND A.CONTA_ID IN ( SELECT	DISTINCT A.CONTA_ID
							FROM	#TMP_VISAO_ALTERACOES_GR AS A
																	INNER JOIN (
																				SELECT	A.CONTA_ID ,
																						ISNULL(A.PROPRIETARIO_CONTA, '') AS PROPRIETARIO_CONTA
																				FROM	[VAGAS_DW].[CONTAS_CRM] AS A
																				UNION ALL
																				SELECT	A.CONTA_ID ,
																						ISNULL(A.PROPRIETARIO_CONTA, '') AS PROPRIETARIO_CONTA
																				FROM	[VAGAS_DW].[CONTAS_MEMBRO_CRM] AS A ) AS B ON A.CONTA_ID = B.CONTA_ID COLLATE SQL_Latin1_General_CP1_CI_AI AND A.VALOR_ATUALIZACAO != B.PROPRIETARIO_CONTA COLLATE SQL_Latin1_General_CP1_CI_AI
							WHERE	A.DATA_ALTERACAO_ATUALIZADO = '20790606' ) ;

-- Carga dos registros na [VAGAS_DW].[ALTERACOES_GR]:
INSERT INTO [VAGAS_DW].[ALTERACOES_GR] (CONTA_ID, DATA_ALTERACAO_ANTERIOR, DATA_ALTERACAO_ATUALIZADO, VALOR_ATUALIZACAO, CONTROLE)
SELECT	A.CONTA_ID ,
		A.DATA_ALTERACAO_ANTERIOR ,
		A.DATA_ALTERACAO_ATUALIZADO ,
		A.VALOR_ATUALIZACAO ,
		A.CONTROLE
FROM	#TMP_VISAO_ALTERACOES_GR AS A ;

-- Limpeza das tabelas tempor�rias:
DROP TABLE #TMP_ALTERACOES_GR ;
DROP TABLE #TMP_VISAO_ALTERACOES_GR ;