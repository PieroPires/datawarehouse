-- =============================================
-- Author: Fiama
-- Create date: 11/10/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [STAGE] ;


IF EXISTS ( SELECT	* FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Curriculo_Visualizado' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' )
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Curriculo_Visualizado] ;
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Curriculo_Visualizado] 
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TMP_CURRICULO_VISUALIZADO] ;

DECLARE	@ULT_DATA_VISUALIZACAO DATE ;
SET	@ULT_DATA_VISUALIZACAO = ( SELECT	ISNULL(DATEADD(DAY, -1, MAX(DATA_VISUALIZACAO)), '19000101')
							   FROM		[VAGAS_DW].[VAGAS_DW].[CURRICULO_VISUALIZADO] ) ;

INSERT INTO [VAGAS_DW].[TMP_CURRICULO_VISUALIZADO] (COD_FUNC, COD_VAGA, DATA_VISUALIZACAO, COD_CLI, CLIENTE_VAGAS, CONTEXTO_VISUALIZACAO, QTD_VISUALIZACOES)
SELECT	A.CodFunc_cvVisto AS COD_FUNC ,
		A.CodVaga_cvVisto AS COD_VAGA ,
		CONVERT(DATE, A.DtUltLeit_cvVisto) AS DATA_VISUALIZACAO ,
		C.Cod_cli AS COD_CLI ,
		C.Ident_cli AS CLIENTE_VAGAS ,
		IIF(A.CodVaga_cvVisto = 0, 'BCE', 'VAGA') AS CONTEXTO_VISUALIZACAO ,
		COUNT(*) AS QTD_VISUALIZACOES
FROM	[hrh-data].[dbo].[Curriculo_Visto] AS A		INNER JOIN [hrh-data].[dbo].[Funcionarios] AS B ON A.CodFunc_cvVisto = B.Cod_func
													INNER JOIN [hrh-data].[dbo].[Clientes] AS C ON B.CodCli_func = C.Cod_cli
WHERE	A.DtUltLeit_cvVisto >= @ULT_DATA_VISUALIZACAO
GROUP BY
		A.CodFunc_cvVisto ,
		A.CodVaga_cvVisto ,
		CONVERT(DATE, A.DtUltLeit_cvVisto) ,
		C.Cod_cli ,
		C.Ident_cli ,
		IIF(A.CodVaga_cvVisto = 0, 'BCE', 'VAGA') ;