-- =============================================
-- Author: Fiama
-- Create date: 23/01/2020
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [STAGE] ;


IF EXISTS ( SELECT	* FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Abertura_Curriculo' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' )
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Abertura_Curriculo] ;
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Abertura_Curriculo] 
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TMP_ABERTURA_CURRICULO] ;

DECLARE	@DATA_ULT_ABERTURA DATE ; 
SET	@DATA_ULT_ABERTURA = (SELECT ISNULL(DATEADD(DAY, -1, MAX(A1.DATA_ABERTURA_CURRICULO)), '19000101')
						  FROM [VAGAS_DW].[VAGAS_DW].[ABERTURA_CURRICULO] AS A1) ;

WHILE EXISTS (SELECT TOP 1 1
			  FROM	 [hrh-data].[dbo].[


INSERT INTO [VAGAS_DW].[TMP_ABERTURA_CURRICULO] (DATA_ABERTURA_CURRICULO,COD_CAND,COD_FUNC,CONTEXTO_ABERTURA)
SELECT	CONVERT(DATE, A.DtUltLeit_cvVisto) AS DATA_ABERTURA_CURRICULO ,
		A.CodCand_cvVisto AS COD_CAND ,
		A.CodFunc_cvVisto AS COD_FUNC ,
		IIF(A.CodVaga_cvVisto = 0, 'BCE', 'VAGA') AS CONTEXTO_ABERTURA
FROM	[hrh-data].[dbo].[Curriculo_Visto] AS A
WHERE	A.DtUltLeit_cvVisto >= @DATA_ULT_ABERTURA ;