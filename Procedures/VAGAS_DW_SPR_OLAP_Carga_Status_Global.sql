-- =============================================
-- Author: Fiama Cristi
-- Create date: 03/09/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [VAGAS_DW] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'VAGAS_DW_SPR_OLAP_Carga_Status_Global' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Status_Global]
GO


CREATE PROCEDURE [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Status_Global]
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[STATUS_GLOBAL_VEP] ;

INSERT INTO [VAGAS_DW].[STATUS_GLOBAL_VEP] (COD_CLI, DATA_STATUS_GLOBAL, COD_VAGA, QTD_ALTERACOES_STATUS_GLOBAL)
SELECT	A.COD_CLI ,
		A.DATA_STATUS_GLOBAL ,
		A.COD_VAGA ,
		A.QTD_ALTERACOES_STATUS_GLOBAL
FROM	[STAGE].[VAGAS_DW].[TMP_STATUS_GLOBAL_VEP] AS A ;