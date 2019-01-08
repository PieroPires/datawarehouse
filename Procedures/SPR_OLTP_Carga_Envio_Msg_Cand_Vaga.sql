-- =============================================
-- Author: Fiama Cristi
-- Create date: 21/11/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- ============================================

USE [STAGE] ;

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Envio_Msg_Cand_Vaga' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Envio_Msg_Cand_Vaga]
GO


CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Envio_Msg_Cand_Vaga]
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TMP_ENVIO_MSG_CAND_VAGA] ;

-- Mensagens enviadas a partir de Jan/2015:
DECLARE	@COD_ULT_ENVIO_MSG INT = (	SELECT	ISNULL(MAX(A1.COD_ENVIO_MSG), 1027588824) 
									FROM	[VAGAS_DW].[VAGAS_DW].[ENVIO_MSG_CAND_VAGA] AS A1) ;


-- Carga incremental:
INSERT INTO [VAGAS_DW].[TMP_ENVIO_MSG_CAND_VAGA] (COD_ENVIO_MSG, COD_CLI, COD_VAGA, DATA_ENVIO)
SELECT	A.ChaveSQL_hist AS COD_ENVIO_MSG ,
		A.CodCliente_hist AS COD_CLI ,
		A.CodVaga_hist AS COD_VAGA ,
		CONVERT(DATE, A.Dt_hist) AS DATA_ENVIO
FROM	[hrh-data].[dbo].[Historico] AS A
WHERE	A.ChaveSQL_hist > @COD_ULT_ENVIO_MSG
		AND A.Tipo_hist = -107
		AND A.CodVaga_hist > 0
		AND ISNUMERIC(A.Autor_hist) = 1
		AND A.Autor_hist >= 124 ;
