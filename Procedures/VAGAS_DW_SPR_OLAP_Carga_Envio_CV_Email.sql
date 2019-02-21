-- =============================================
-- Author: Fiama
-- Create date: 23/10/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [VAGAS_DW] ;

IF EXISTS ( SELECT	* FROM SYS.OBJECTS WHERE NAME = 'VAGAS_DW_SPR_OLAP_Carga_Envio_CV_Email' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' )
DROP PROCEDURE [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Envio_CV_Email] ;
GO

CREATE PROCEDURE [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Envio_CV_Email] 
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[ENVIO_CV_EMAIL] ;


INSERT INTO [VAGAS_DW].[ENVIO_CV_EMAIL] (COD_CLI,FORMATO_ENVIO_CV,COD_VAGA,DATA_ENVIO,QTD_ENVIOS_CVs,QTD_CVS_ENVIADO)
SELECT	A.COD_CLI ,
		A.FORMATO_ENVIO_CV ,
		A.COD_VAGA ,
		A.DATA_ENVIO ,
		A.QTD_ENVIOS_CVs ,
		A.QTD_CVS_ENVIADO
FROM	[STAGE].[VAGAS_DW].[TMP_ENVIO_CV_EMAIL] AS A ;