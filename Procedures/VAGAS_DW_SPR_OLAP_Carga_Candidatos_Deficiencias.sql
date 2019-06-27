-- =============================================
-- Author: Fiama
-- Create date: 27/06/2019
-- Description: Procedure para alimentação do DW
-- =============================================

USE [VAGAS_DW] ;

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' AND NAME = 'SPR_OLAP_Carga_Candidatos_Deficiencias')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Candidatos_Deficiencias] ;
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Candidatos_Deficiencias]
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[CANDIDATOS_DEFICIENCIAS] ;

INSERT INTO [VAGAS_DW].[CANDIDATOS_DEFICIENCIAS] (Cod_cand, TipoDeficiencia)
SELECT	A.Cod_cand ,
		A.TipoDeficiencia
FROM	[VAGAS_DW].[TMP_CANDIDATOS_DEFICIENCIAS] AS A ;