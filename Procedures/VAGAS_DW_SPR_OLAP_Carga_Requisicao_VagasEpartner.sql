-- =============================================
-- Author: Fiama
-- Create date: 12/08/2019
-- Description: Script com a rotina de carga OLAP do Cubo de Requisicao_VagasEpartner.
-- =============================================

USE [VAGAS_DW] ;

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' AND NAME = 'SPR_OLAP_Carga_Requisicao_VagasEpartner')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Requisicao_VagasEpartner]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Requisicao_VagasEpartner]
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[Requisicao_VagasEpartner] ;

INSERT INTO [VAGAS_DW].[Requisicao_VagasEpartner] (Cod_requisicao,Status_requisicao,Data_requisicao,Cod_cli,Cod_func,Cod_vaga,IdConta_CRM)
SELECT	A.Cod_requisicao ,
		A.Status_requisicao ,
		A.Data_requisicao ,
		A.Cod_cli ,
		A.Cod_func ,
		A.Cod_vaga ,
		A.IdConta_CRM
FROM	[STAGE].[VAGAS_DW].[TMP_Requisicao_VagasEpartner] AS A ;