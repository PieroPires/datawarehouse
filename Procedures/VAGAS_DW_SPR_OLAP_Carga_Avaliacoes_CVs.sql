-- =============================================
-- Author: Fiama
-- Create date: 22/10/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [VAGAS_DW] ;

IF EXISTS ( SELECT	* FROM SYS.OBJECTS WHERE NAME = 'VAGAS_DW_SPR_OLAP_Carga_Avaliacoes_CVs' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' )
DROP PROCEDURE [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Avaliacoes_CVs] ;
GO

CREATE PROCEDURE [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Avaliacoes_CVs] 
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[AVALIACOES_CVS] ;


INSERT INTO [VAGAS_DW].[AVALIACOES_CVS] (DATA_AVALIACAO, COD_VAGA, AVALIACAO, QTD_AVALIACOES_CVs)
SELECT	A.DATA_AVALIACAO ,
		A.COD_VAGA ,
		A.AVALIACAO ,
		A.QTD_AVALIACOES_CVs
FROM	[STAGE].[VAGAS_DW].[TMP_AVALIACOES_CVS] AS A ;