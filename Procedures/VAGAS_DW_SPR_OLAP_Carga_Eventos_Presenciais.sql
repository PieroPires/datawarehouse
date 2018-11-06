-- =============================================
-- Author: Fiama
-- Create date: 27/08/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [VAGAS_DW] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Eventos_Presenciais' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Eventos_Presenciais]
GO


CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Eventos_Presenciais]

AS
SET NOCOUNT ON


-- Limpar tabela FATO:
TRUNCATE TABLE [VAGAS_DW].[EVENTOS_PRESENCIAIS] ;

INSERT INTO [VAGAS_DW].[EVENTOS_PRESENCIAIS](COD_EVENTO,NOME_EVENTO,COD_VAGA,TIPO,DATA_ENVIO_AGENDAMENTO,QTD_EVENTOS,QTD_ENVIO_AGENDAMENTO)
SELECT	COD_EVENTO ,
		NOME_EVENTO ,
		COD_VAGA ,
		TIPO ,
		DATA_ENVIO_AGENDAMENTO ,
		QTD_EVENTOS ,
		QTD_ENVIO_AGENDAMENTO
FROM	[STAGE].[VAGAS_DW].[TMP_EVENTOS_PRESENCIAIS]  AS A ;