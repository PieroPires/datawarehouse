-- =============================================
-- Author: Fiama Cristi
-- Create date: 20/08/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [STAGE]
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Avaliacoes_CVs' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Avaliacoes_CVs]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Avaliacoes_CVs]

AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TMP_AVALIACOES_CVS] ;

INSERT INTO [VAGAS_DW].[TMP_AVALIACOES_CVS] (COD_VAGA, QTD_AVALIACOES_VAGA)
SELECT	CONVERT(SMALLDATETIME, CONVERT(CHAR(8), A.DtFase_candVaga, 112)) AS DATA_AVALIACAO ,
		A.CodVaga_cvVisto AS COD_VAGA ,
		COUNT(*) AS QTD_VISUALIZACOES
FROM	[hrh-data].[dbo].[Curriculo_Visto] AS A
GROUP BY
		CONVERT(SMALLDATETIME, CONVERT(CHAR(8), A.DtUltLeit_cvVisto, 112)) ,
		A.CodVaga_cvVisto ;


SELECT	TOP 1000 * FROM [hrh-data].[dbo].[CandidatoxVagas] 
WHERE (CodAval_candVaga < 0 OR CodAval_candVaga > 0) AND DtFase_candVaga IS NOT NULL 
ORDER BY Cod_candVaga DESC ;


SELECT	TOP 10 * FROM [hrh-data]..[HistoricoFasesCand]
SELECT	DISTINCT CodAval_faseCand FROM [hrh-data]..[HistoricoFasesCand]