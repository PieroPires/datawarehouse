-- =============================================
-- Author: Fiama Cristi
-- Create date: 03/09/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [STAGE] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Status_Global' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Status_Global]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Status_Global]
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TMP_STATUS_GLOBAL_VEP] ;

INSERT INTO [VAGAS_DW].[TMP_STATUS_GLOBAL_VEP]
SELECT	A.CodCliente_candCli AS COD_CLI ,
		CONVERT(SMALLDATETIME, CONVERT(CHAR(10), A.DtIniStatus_candCli, 112)) AS DATA_STATUS_GLOBAL ,
		A.VagaStatus_candCli AS COD_VAGA ,
		COUNT(*) AS QTD_ALTERACOES_STATUS_GLOBAL
FROM	[hrh-data].[dbo].[CandidatoxCliente] AS A
WHERE	EXISTS ( SELECT	1
				 FROM	[hrh-data].[dbo].[Cad_stGlobalCand] AS A1
				 WHERE	A.CodStatus_candCli = A1.Cod_stGCand
						AND A.CodCliente_candCli = A1.CodCli_stGCand )
GROUP BY
		A.CodCliente_candCli ,
		CONVERT(SMALLDATETIME, CONVERT(CHAR(10), A.DtIniStatus_candCli, 112)) ,
		A.VagaStatus_candCli ;