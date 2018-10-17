-- =============================================
-- Author: Fiama
-- Create date: 27/08/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [STAGE]
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Eventos_Presenciais' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Eventos_Presenciais]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Eventos_Presenciais]
AS
SET NOCOUNT ON

-- Limpa tabela temporária:
TRUNCATE TABLE [VAGAS_DW].[TMP_EVENTOS_PRESENCIAIS] ;

-- Carrega os dados na tabela FATO:
INSERT INTO [VAGAS_DW].[TMP_EVENTOS_PRESENCIAIS]
SELECT	A.Cod_agEv AS COD_EVENTO ,
		A.Nome_agEv AS NOME_EVENTO ,
		A.CodVaga_agEv AS COD_VAGA ,
		CASE
			WHEN A.FormaParticipacao_agEv = 0
				THEN 'PRESENCIAL'
			WHEN A.FormaParticipacao_agEv = 1
				THEN 'REMOTO'
		END AS TIPO
FROM	[hrh-data].[dbo].[Agendamento-Eventos] AS A ;