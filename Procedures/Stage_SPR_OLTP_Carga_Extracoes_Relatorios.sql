-- =============================================
-- Author: Fiama Cristi
-- Create date: 03/09/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [STAGE] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Extracoes_Relatorios' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Extracoes_Relatorios]
GO


CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Extracoes_Relatorios]
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TMP_EXTRACOES_RELATORIOS_VEP] ;

INSERT INTO [VAGAS_DW].[TMP_EXTRACOES_RELATORIOS_VEP]
SELECT	SUBQUERY.DATA_EXTRACAO ,
		SUBQUERY.COD_CLI ,
		SUBQUERY.CONTEXTO_EXTRACAO ,
		COUNT(*) AS QTD_EXTRACOES_RELATORIOS 
FROM	
	(
		SELECT	CONVERT(SMALLDATETIME, CONVERT(CHAR(10), A.Dt_email, 112)) AS DATA_EXTRACAO ,
				( SELECT	A1.CodCli_func AS COD_CLI
				  FROM		[hrh-data].[dbo].[Funcionarios] AS A1
				  WHERE		A.CodFunc_email = A1.Cod_func ) AS COD_CLI ,
				IIF(A.CodVaga_email > 0, 'VAGA', 'OUTRO') AS CONTEXTO_EXTRACAO ,
				A.CodPedido_email AS COD_PEDIDO
		FROM	[hrh-data].[dbo].[Email] AS A ) AS SUBQUERY
GROUP BY
		SUBQUERY.DATA_EXTRACAO ,
		SUBQUERY.COD_CLI ,
		SUBQUERY.CONTEXTO_EXTRACAO ;