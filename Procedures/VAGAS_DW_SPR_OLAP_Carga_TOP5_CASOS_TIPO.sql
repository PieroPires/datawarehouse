-- =============================================
-- Author: Fiama
-- Create date: 12/04/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [VAGAS_DW] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_TOP5_CASOS_TIPO' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_TOP5_CASOS_TIPO] ;
GO



CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_TOP5_CASOS_TIPO]
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TOP_5_CASOS_TIPO] ;

INSERT INTO [VAGAS_DW].[TOP_5_CASOS_TIPO]
SELECT	A.CONTA_ID ,
		B.TIPO ,
		B.QTD_CASOS ,
		CONVERT(TINYINT, ROW_NUMBER() OVER(PARTITION BY A.CONTA_ID ORDER BY B.QTD_CASOS DESC)) AS ORDEM_TOP_5
FROM	[VAGAS_DW].[CLIENTES] AS A		OUTER APPLY (SELECT	TOP 5 A1.TIPO ,
															COUNT(*) AS QTD_CASOS
													 FROM	[VAGAS_DW].[CASOS] AS A1
													 WHERE	A.CONTA_ID = A1.CONTA_ID
															AND A1.[STATUS] IN ('fechado', 'fechado_sem_resposta')
															AND A1.DATA_FECHAMENTO >= DATEADD(MONTH, -12, CAST(GETDATE() AS DATE))
															AND A1.FILA_ATENDIMENTO = 'suporte_empresas'
													 GROUP BY
															A1.TIPO
													 ORDER BY
															QTD_CASOS DESC) AS B
WHERE	A.EX_CLIENTE = 0
		AND A.CARTEIRA = 'RELACIONAMENTO'
ORDER BY
		A.CONTA_ID ASC ,
		ORDEM_TOP_5 ASC ;