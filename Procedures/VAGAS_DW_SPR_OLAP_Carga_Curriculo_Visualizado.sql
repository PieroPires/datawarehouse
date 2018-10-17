-- =============================================
-- Author: Fiama
-- Create date: 11/10/2018
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW
-- =============================================

USE [VAGAS_DW] ;

IF EXISTS ( SELECT	* FROM SYS.OBJECTS WHERE NAME = 'VAGAS_DW_SPR_OLAP_Carga_Curriculo_Visualizado' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' )
DROP PROCEDURE [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Curriculo_Visualizado] ;
GO

CREATE PROCEDURE [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Curriculo_Visualizado] 
AS
SET NOCOUNT ON

DECLARE	@ULT_DATA_VISUALIZACAO DATE ;
SET	@ULT_DATA_VISUALIZACAO = ( SELECT	ISNULL(DATEADD(DAY, -1, MAX(DATA_VISUALIZACAO)), '19000101')
							   FROM		[VAGAS_DW].[VAGAS_DW].[CURRICULO_VISUALIZADO] ) ;

-- Apaga registros a partir da �ltima data pra garantir que peguemos um dia completo:
DELETE	FROM [VAGAS_DW].[VAGAS_DW].[CURRICULO_VISUALIZADO]
FROM	[VAGAS_DW].[VAGAS_DW].[CURRICULO_VISUALIZADO] AS A
WHERE	A.DATA_VISUALIZACAO >= @ULT_DATA_VISUALIZACAO


INSERT INTO [VAGAS_DW].[CURRICULO_VISUALIZADO] (DATA_VISUALIZACAO,COD_VAGA,COD_FUNC,COD_CLI,CLIENTE_VAGAS,CONTEXTO_VISUALIZACAO,QTD_VISUALIZACOES)
SELECT	A.DATA_VISUALIZACAO ,
		A.COD_VAGA ,
		A.COD_FUNC ,
		A.COD_CLI ,
		A.CLIENTE_VAGAS ,
		A.CONTEXTO_VISUALIZACAO ,
		A.QTD_VISUALIZACOES
FROM	[STAGE].[VAGAS_DW].[TMP_CURRICULO_VISUALIZADO] AS A ;