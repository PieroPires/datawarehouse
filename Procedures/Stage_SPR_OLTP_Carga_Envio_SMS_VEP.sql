-- =============================================
-- Author: Fiama Cristi
-- Create date: 03/09/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [STAGE] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Envio_SMS_VEP' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Envio_SMS_VEP]
GO


CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Envio_SMS_VEP]
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TMP_ENVIO_SMS_VEP] ;

INSERT INTO [VAGAS_DW].[TMP_ENVIO_SMS_VEP]
SELECT	A.CodCli_smsEnv AS COD_CLI ,
		A.CodFunc_smsEnv AS COD_FUNC ,
		A.CodVaga_smsEnv AS COD_VAGA ,
		SUM(A.QtdeEnv_smsEnv) AS QTD_SMS_ENVIADO ,
		COUNT(*) AS QTD_ENVIOS ,
		CONVERT(SMALLDATETIME, CONVERT(CHAR(10), A.DataEnv_smsEnv, 112)) AS DATA_ENVIO
FROM	[hrh-data].[dbo].[SMS-Enviados] AS A
GROUP BY
		A.CodCli_smsEnv ,
		A.CodFunc_smsEnv ,
		A.CodVaga_smsEnv ,
		CONVERT(SMALLDATETIME, CONVERT(CHAR(10), A.DataEnv_smsEnv, 112)) ;