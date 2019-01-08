-- =============================================
-- Author: Fiama
-- Create date: 19/12/2017
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [VAGAS_DW] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Envio_MSG_Cand_Vaga' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Envio_MSG_Cand_Vaga] ;
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Envio_MSG_Cand_Vaga]

AS
SET NOCOUNT ON

INSERT INTO [VAGAS_DW].[ENVIO_MSG_CAND_VAGA](COD_ENVIO_MSG, COD_CLI, COD_VAGA, DATA_ENVIO)
SELECT	A.COD_ENVIO_MSG ,
		A.COD_CLI ,
		A.COD_VAGA ,
		A.DATA_ENVIO
FROM	[STAGE].[VAGAS_DW].[TMP_ENVIO_MSG_CAND_VAGA] AS A ;