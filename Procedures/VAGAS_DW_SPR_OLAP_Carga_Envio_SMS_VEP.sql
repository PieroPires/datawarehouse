-- =============================================
-- Author: Fiama Cristi
-- Create date: 03/09/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [VAGAS_DW] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'VAGAS_DW_SPR_OLAP_Carga_Envio_SMS_VEP' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Envio_SMS_VEP]
GO


CREATE PROCEDURE [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Envio_SMS_VEP]
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[ENVIO_SMS_VEP] ;

INSERT INTO [VAGAS_DW].[ENVIO_SMS_VEP]
SELECT	A.COD_CLI ,
		A.COD_FUNC ,
		A.COD_VAGA ,
		A.QTD_SMS_ENVIADO ,
		A.QTD_ENVIOS ,
		A.DATA_ENVIO
FROM	[VAGAS_DW].[ENVIO_SMS_VEP] AS A ;