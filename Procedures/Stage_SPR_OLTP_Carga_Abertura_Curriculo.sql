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

TRUNCATE TABLE [VAGAS_DW].[TMP_Abertura_Curriculo] ;

DECLARE	@Data_Ult_Abertura DATE ; 
SET	@Data_Ult_Abertura = (SELECT ISNULL(DATEADD(DAY, -1, MAX(A1.Data_Abertura_Curriculo)), '19000101')
						  FROM [VAGAS_DW].[VAGAS_DW].[Abertura_Curriculo] AS A1) ;

INSERT INTO [VAGAS_DW].[TMP_Abertura_Curriculo] (Data_Abertura_Curriculo,Cod_cand,Cod_func,Contexto_Abertura)
SELECT	CONVERT(DATE, A.DtUltLeit_cvVisto) AS Data_Abertura_Curriculo ,
		A.CodCand_cvVisto AS Cod_cand ,
		A.CodFunc_cvVisto AS Cod_func ,
		IIF(A.CodVaga_cvVisto = 0, 'BCE', 'VAGA') AS Contexto_Abertura
FROM	[hrh-data].[dbo].[Curriculo_Visto] AS A
WHERE	A.DtUltLeit_cvVisto >= @Data_Ult_Abertura ;