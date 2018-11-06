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

INSERT INTO [VAGAS_DW].[TMP_AVALIACOES_CVS] (DATA_AVALIACAO, COD_VAGA, AVALIACAO, QTD_AVALIACOES_CVs)
SELECT	CONVERT(DATE, A.DtFase_candVaga) AS DATA_AVALIACAO ,
		A.CodVaga_candVaga AS COD_VAGA ,
		CASE
			WHEN A.CodAval_candVaga = -2
				THEN 'Nenhum'
			WHEN A.CodAval_candVaga = -1
				THEN 'Ruim'
			WHEN A.CodAval_candVaga = 0
				THEN 'Não avaliado'
			WHEN A.CodAval_candVaga = 1	
				THEN 'Regular'
			WHEN A.CodAval_candVaga = 2
				THEN 'Bom'
			WHEN A.CodAval_candVaga = 3	
				THEN 'Excelente'
		END AS AVALIACAO ,
		COUNT(*) AS QTD_AVALIACOES_CVs
FROM	[hrh-data].[dbo].[CandidatoxVagas] AS A
WHERE	(A.CodAval_candVaga < 0 
		 OR A.CodAval_candVaga > 0) 
		 AND A.DtFase_candVaga IS NOT NULL 
GROUP BY
		CONVERT(DATE, A.DtFase_candVaga) ,
		A.CodVaga_candVaga ,
		CASE
			WHEN A.CodAval_candVaga = -2
				THEN 'Nenhum'
			WHEN A.CodAval_candVaga = -1
				THEN 'Ruim'
			WHEN A.CodAval_candVaga = 0
				THEN 'Não avaliado'
			WHEN A.CodAval_candVaga = 1	
				THEN 'Regular'
			WHEN A.CodAval_candVaga = 2
				THEN 'Bom'
			WHEN A.CodAval_candVaga = 3	
				THEN 'Excelente'
		END ;