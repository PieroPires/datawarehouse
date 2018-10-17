-- =============================================
-- Author: Fiama Cristi
-- Create date: 03/09/2018
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW
-- =============================================

USE [VAGAS_DW] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'VAGAS_DW_SPR_OLAP_Carga_Extracoes_Relatorios' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Extracoes_Relatorios]
GO


CREATE PROCEDURE [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Extracoes_Relatorios]
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[EXTRACOES_RELATORIOS_VEP] ;

INSERT INTO [VAGAS_DW].[EXTRACOES_RELATORIOS_VEP] (DATA_EXTRACAO, COD_CLI, CONTEXTO_EXTRACAO, QTD_EXTRACOES_RELATORIOS)
SELECT	A.DATA_EXTRACAO ,
		A.COD_CLI ,
		A.CONTEXTO_EXTRACAO ,
		A.QTD_EXTRACOES_RELATORIOS		
FROM	[STAGE].[VAGAS_DW].[TMP_EXTRACOES_RELATORIOS_VEP] AS A ;