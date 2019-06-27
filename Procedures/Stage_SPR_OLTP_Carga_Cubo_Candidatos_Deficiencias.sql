-- =============================================
-- Author: Fiama
-- Create date: 27/06/2019
-- Description: Procedure para alimentação do DW
-- =============================================

USE [VAGAS_DW] ;

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' AND NAME = 'Stage_SPR_OLTP_Carga_Cubo_Candidatos_Deficiencias')
DROP PROCEDURE [VAGAS_DW].[Stage_SPR_OLTP_Carga_Cubo_Candidatos_Deficiencias] ;
GO

CREATE PROCEDURE [VAGAS_DW].[Stage_SPR_OLTP_Carga_Cubo_Candidatos_Deficiencias]
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TMP_CANDIDATOS_DEFICIENCIAS] ;

INSERT INTO [VAGAS_DW].[TMP_CANDIDATOS_DEFICIENCIAS] (Cod_cand, TipoDeficiencia)
SELECT	A.CodCand_necEsp AS Cod_cand ,
		'Auditiva' AS TipoDeficiencia
FROM	[hrh-data].[dbo].[Cand-NecEsp] AS A
WHERE	A.Auditiva_necEsp > -1
UNION ALL
SELECT	A.CodCand_necEsp ,
		'Fala' AS TipoDeficiencia
FROM	[hrh-data].[dbo].[Cand-NecEsp] AS A
WHERE	A.Fala_necEsp > -1
UNION ALL
SELECT	A.CodCand_necEsp ,
		'Física' AS TipoDeficiencia
FROM	[hrh-data].[dbo].[Cand-NecEsp] AS A
WHERE	A.Fisica_necEsp > -1
UNION ALL
SELECT	A.CodCand_necEsp ,
		'Mental' AS TipoDeficiencia
FROM	[hrh-data].[dbo].[Cand-NecEsp] AS A
WHERE	A.Mental_necEsp > -1
UNION ALL
SELECT	A.CodCand_necEsp ,
		'Visual' AS TipoDeficiencia
FROM	[hrh-data].[dbo].[Cand-NecEsp] AS A
WHERE	A.Visual_necEsp > -1 ;
