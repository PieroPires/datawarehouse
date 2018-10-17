-- =============================================
-- Author: Fiama Cristi
-- Create date: 03/09/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [STAGE] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Carimbadas_Candidatos' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Carimbadas_Candidatos]
GO


CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Carimbadas_Candidatos]
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TMP_CARIMBADAS_CANDIDATOS] ;

INSERT INTO [VAGAS_DW].[TMP_CARIMBADAS_CANDIDATOS]
SELECT	A.CodCli_carim AS COD_CLI ,
		A.CodFunc_carim AS COD_FUNC ,
		A.CodVaga_carim AS COD_VAGA ,
		COUNT(*) AS QTD_CARIMBADAS_CAND ,
		COUNT(DISTINCT A.CodCand_carim) AS QTD_CANDIDATOS_CARIMBADOS ,
		CONVERT(SMALLDATETIME, CONVERT(CHAR(10), A.DataCriacao_carim, 112)) AS DATA_INCLUSAO_CARIMBO ,
		CONVERT(SMALLDATETIME, CONVERT(CHAR(10), A.DataExclusao_carim, 112)) AS DATA_EXCLUSAO_CARIMBO ,
		UPPER(A.Contexto_carim) AS CONTEXTO
FROM	[hrh-data].[dbo].[Carimbadas] AS A
GROUP BY
		A.CodCli_carim ,
		A.CodFunc_carim ,
		A.CodVaga_carim ,
		CONVERT(SMALLDATETIME, CONVERT(CHAR(10), A.DataCriacao_carim, 112)) ,
		CONVERT(SMALLDATETIME, CONVERT(CHAR(10), A.DataExclusao_carim, 112)) ,
		A.Contexto_carim ;