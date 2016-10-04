USE VAGAS_DW
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Treinamentos_Participantes_CRM' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Treinamentos_Participantes_CRM]
GO


-- =============================================
-- Author:      Fiama dos Santos Cristi
-- Create date: 29/09/2016
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================
CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Treinamentos_Participantes_CRM]

AS
SET NOCOUNT ON


-- LIMPAR TABELA FATO:
TRUNCATE TABLE [VAGAS_DW].[TREINAMENTOS_PARTICIPANTES_CRM] ;

INSERT INTO [VAGAS_DW].[TREINAMENTOS_PARTICIPANTES_CRM]
SELECT ID_PARTICIPANTE ,
	DATA_CRIACAO ,
	DATA_MODIFICACAO ,
	USUARIO_CRIOU ,
	USUARIO_MODIFICOU ,
	DESCRICAO ,
	STATUS_PARTICIPANTE ,
	CONTATO ,
	NOME_TREINAMENTO ,
	CONTA
FROM [VAGAS_DW].[TMP_TREINAMENTOS_PARTICIPANTES_CRM] AS A ;

